'use strict';

/**
 * Yanyana Cloud Functions
 *
 * - rcWebhook: RevenueCat olaylarını alır, couples/{id}.premiumUntil alanını
 *   günceller → "1 üyelik = 2 kişi" (partner de premium olur).
 * - onCoupleWritten: üyelik değişince çift premium'unu yeniden hesaplar ve
 *   "Seni düşünüyorum" sinyalini partnere push olarak gönderir.
 * - onAnswerWritten / onMemoryCreated / onNoteCreated: partnere bildirim.
 * - notifyUnlockedNotes: kilidi açılan zaman kapsüllerini saatlik bildirir.
 * - cleanupDeletedUser: Auth kullanıcısı silinince artık verileri temizler.
 *
 * Gerekli gizli anahtarlar (firebase functions:secrets:set ...):
 * - REVENUECAT_WEBHOOK_AUTH: RevenueCat webhook ayarındaki Authorization değeri
 * - REVENUECAT_SECRET_KEY: RevenueCat gizli API anahtarı (sk_...)
 */

const { setGlobalOptions } = require('firebase-functions/v2');
const { onRequest } = require('firebase-functions/v2/https');
const { onDocumentWritten, onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const functionsV1 = require('firebase-functions/v1');
const logger = require('firebase-functions/logger');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getStorage } = require('firebase-admin/storage');
const h = require('./lib/helpers');

initializeApp();
const db = getFirestore();

// Firestore veritabanı eur3 çoklu bölgesinde; tetikleyiciler bununla uyumlu bölgede çalışmalı.
const REGION = 'europe-west1';
setGlobalOptions({ region: REGION, maxInstances: 10 });

const ENTITLEMENT_ID = 'premium';
const RC_WEBHOOK_AUTH = defineSecret('REVENUECAT_WEBHOOK_AUTH');
const RC_SECRET_KEY = defineSecret('REVENUECAT_SECRET_KEY');

// ---------------------------------------------------------------------------
// Premium (RevenueCat)
// ---------------------------------------------------------------------------

async function fetchEntitlementExpiry(uid) {
  const res = await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`, {
    headers: { Authorization: `Bearer ${RC_SECRET_KEY.value()}` },
  });
  if (!res.ok) throw new Error(`RevenueCat ${res.status} for ${uid}`);
  const body = await res.json();
  return h.entitlementExpiryMs(body.subscriber, ENTITLEMENT_ID);
}

/** Üyelerin users/{uid}.premiumUntil değerlerinden çift premium'unu hesaplar. */
async function refreshCouplePremium(coupleRef, couple) {
  const members = Array.isArray(couple.memberIds) ? couple.memberIds : [];
  const entries = await Promise.all(
    members.map(async (uid) => {
      const user = await db.doc(`users/${uid}`).get();
      const until = user.get('premiumUntil');
      return { uid, untilMs: until ? until.toMillis() : null };
    }),
  );
  const best = h.latestPremium(entries);
  const current = couple.premiumUntil ? couple.premiumUntil.toMillis() : null;
  if (current === best.untilMs && (couple.premiumOwner || null) === best.owner) return;
  await coupleRef.update({
    premiumUntil: best.untilMs == null ? null : Timestamp.fromMillis(best.untilMs),
    premiumOwner: best.owner,
  });
}

exports.rcWebhook = onRequest({ secrets: [RC_WEBHOOK_AUTH, RC_SECRET_KEY] }, async (req, res) => {
  if (req.method !== 'POST' || req.get('Authorization') !== RC_WEBHOOK_AUTH.value()) {
    res.status(401).send('unauthorized');
    return;
  }
  const event = req.body && req.body.event;
  if (!event || event.type === 'TEST') {
    res.status(200).send('ok');
    return;
  }

  try {
    // Olay alanlarına güvenmek yerine güncel durumu RevenueCat'ten okuyoruz
    // (iade, transfer ve sıralı olaylar için en güvenilir yol).
    for (const uid of h.affectedUserIds(event)) {
      const untilMs = await fetchEntitlementExpiry(uid);
      await db.doc(`users/${uid}`).set(
        {
          premiumUntil: untilMs == null ? null : Timestamp.fromMillis(untilMs),
          premiumProduct: event.product_id || null,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      const couples = await db.collection('couples').where('memberIds', 'array-contains', uid).get();
      for (const doc of couples.docs) {
        await refreshCouplePremium(doc.ref, doc.data());
      }
    }
    res.status(200).send('ok');
  } catch (e) {
    logger.error('rcWebhook failed', e);
    // 5xx → RevenueCat olayı daha sonra tekrar gönderir.
    res.status(500).send('error');
  }
});

// ---------------------------------------------------------------------------
// Push bildirimleri
// ---------------------------------------------------------------------------

async function sendToMember(couple, uid, payload, data = {}) {
  const token = couple.tokens && couple.tokens[uid];
  if (!token) return;
  try {
    await getMessaging().send({
      token,
      notification: payload,
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      apns: { payload: { aps: { sound: 'default' } } },
      android: { priority: 'high', notification: { sound: 'default' } },
    });
  } catch (e) {
    logger.warn('push failed', { uid, code: e.code });
  }
}

async function loadCouple(coupleId) {
  const snap = await db.doc(`couples/${coupleId}`).get();
  return snap.exists ? snap.data() : null;
}

exports.onCoupleWritten = onDocumentWritten('couples/{coupleId}', async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : null;
  const after = event.data.after.exists ? event.data.after.data() : null;
  if (!after) return;

  const membersChanged = JSON.stringify(before && before.memberIds) !== JSON.stringify(after.memberIds);
  if (membersChanged) {
    await refreshCouplePremium(event.data.after.ref, after);
  }

  const pulse = after.lastThinkingOfYou;
  const prevPulse = before && before.lastThinkingOfYou;
  if (pulse && pulse.senderId && (!prevPulse || prevPulse.iso !== pulse.iso)) {
    const partner = h.partnerOf(after, pulse.senderId);
    if (partner) {
      const name = h.nameOf(after, pulse.senderId) || pulse.senderName || 'Partner';
      await sendToMember(after, partner, h.message(h.langOf(after, partner), 'thinking', name), {
        type: 'thinking_of_you',
      });
    }
  }
});

exports.onAnswerWritten = onDocumentWritten('couples/{coupleId}/answers/{questionId}', async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : null;
  const after = event.data.after.exists ? event.data.after.data() : null;
  if (!after) return;
  const added = h.newAnswerers(before, after);
  if (added.length === 0) return;

  const couple = await loadCouple(event.params.coupleId);
  if (!couple) return;
  const answerer = added[0];
  const partner = h.partnerOf(couple, answerer);
  if (!partner) return;
  const lang = h.langOf(couple, partner);
  const name = h.nameOf(couple, answerer) || 'Partner';
  const bothAnswered = h.answererIds(after).includes(partner);
  const payload = bothAnswered ? h.message(lang, 'answersRevealed') : h.message(lang, 'answerWaiting', name);
  await sendToMember(couple, partner, payload, { type: 'daily_question', questionId: event.params.questionId });
});

exports.onMemoryCreated = onDocumentCreated('couples/{coupleId}/memories/{memoryId}', async (event) => {
  const memory = event.data && event.data.data();
  if (!memory || !memory.authorId) return;
  const couple = await loadCouple(event.params.coupleId);
  if (!couple) return;
  const partner = h.partnerOf(couple, memory.authorId);
  if (!partner) return;
  const name = h.nameOf(couple, memory.authorId) || 'Partner';
  await sendToMember(couple, partner, h.message(h.langOf(couple, partner), 'memory', name, memory.title), {
    type: 'memory',
    memoryId: event.params.memoryId,
  });
});

exports.onNoteCreated = onDocumentCreated('couples/{coupleId}/notes/{noteId}', async (event) => {
  const note = event.data && event.data.data();
  if (!note || !note.authorId) return;
  const couple = await loadCouple(event.params.coupleId);
  if (!couple) return;
  const partner = h.partnerOf(couple, note.authorId);
  if (!partner) return;
  const name = h.nameOf(couple, note.authorId) || note.senderName || 'Partner';
  const locked = typeof note.unlockAtMs === 'number' && note.unlockAtMs > Date.now();
  await sendToMember(couple, partner, h.message(h.langOf(couple, partner), 'note', name, locked), {
    type: 'note',
    noteId: event.params.noteId,
  });
});

/** Son çalışmadan bu yana kilidi açılan zaman kapsüllerini bildirir. */
exports.notifyUnlockedNotes = onSchedule('every 60 minutes', async () => {
  const stateRef = db.doc('system/noteUnlocks');
  const state = await stateRef.get();
  const now = Date.now();
  const since = state.exists ? state.get('lastRunMs') : now - 60 * 60 * 1000;

  const notes = await db
    .collectionGroup('notes')
    .where('unlockAtMs', '>', since)
    .where('unlockAtMs', '<=', now)
    .get();
  for (const doc of notes.docs) {
    const note = doc.data();
    const coupleRef = doc.ref.parent.parent;
    if (!coupleRef || !note.authorId) continue;
    const couple = await loadCouple(coupleRef.id);
    const partner = couple && h.partnerOf(couple, note.authorId);
    if (!partner) continue;
    const name = h.nameOf(couple, note.authorId) || note.senderName || 'Partner';
    await sendToMember(couple, partner, h.message(h.langOf(couple, partner), 'noteUnlocked', name), {
      type: 'note',
      noteId: doc.id,
    });
  }
  await stateRef.set({ lastRunMs: now });
});

// ---------------------------------------------------------------------------
// Hesap silme yedeği
// ---------------------------------------------------------------------------

/**
 * İstemci hesap silmeyi kendisi yapar; bu fonksiyon yarıda kalan silmelerde
 * (ağ kesintisi vb.) kullanıcıya ait artık verileri temizler.
 */
exports.cleanupDeletedUser = functionsV1
  .region(REGION)
  .auth.user()
  .onDelete(async (user) => {
    const uid = user.uid;
    const couples = await db.collection('couples').where('memberIds', 'array-contains', uid).get();
    for (const doc of couples.docs) {
      const couple = doc.data();
      const remaining = (couple.memberIds || []).filter((m) => m !== uid);
      if (remaining.length === 0) {
        await db.recursiveDelete(doc.ref);
        await getStorage()
          .bucket()
          .deleteFiles({ prefix: `couples/${doc.id}/` })
          .catch((e) => logger.warn('storage cleanup failed', e));
      } else {
        const partner = remaining[0];
        await doc.ref.update({
          memberIds: [partner],
          user1Id: partner,
          user1Name: h.nameOf(couple, partner),
          user2Id: null,
          user2Name: null,
          [`tokens.${uid}`]: FieldValue.delete(),
        });
      }
    }
    const invites = await db.collection('invites').where('ownerId', '==', uid).get();
    await Promise.all(invites.docs.map((d) => d.ref.delete()));
    await db.doc(`users/${uid}`).delete();
  });
