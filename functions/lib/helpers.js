'use strict';

// Saf yardımcılar: Firebase'e bağımlı değiller, birim testleri test/ altında.

const LIFETIME_MS = Date.UTC(2100, 0, 1);

/** Çift belgesinde [senderId] dışındaki üyenin uid'i. */
function partnerOf(couple, senderId) {
  const members = Array.isArray(couple && couple.memberIds) ? couple.memberIds : [];
  return members.find((m) => m && m !== senderId) || null;
}

/** Üyenin çift belgesindeki adı. */
function nameOf(couple, uid) {
  if (!couple || !uid) return null;
  if (couple.user1Id === uid) return couple.user1Name || null;
  if (couple.user2Id === uid) return couple.user2Name || null;
  return null;
}

/** Bildirim dili (istemci langs.{uid} alanına yazar). */
function langOf(couple, uid) {
  const lang = couple && couple.langs && couple.langs[uid];
  return lang === 'en' ? 'en' : 'tr';
}

/** RevenueCat olayından etkilenen, anonim olmayan kullanıcılar. */
function affectedUserIds(event) {
  const ids = new Set();
  const add = (v) => {
    if (typeof v === 'string' && v && !v.startsWith('$RCAnonymousID')) ids.add(v);
  };
  if (!event) return [];
  add(event.app_user_id);
  add(event.original_app_user_id);
  (event.aliases || []).forEach(add);
  (event.transferred_from || []).forEach(add);
  (event.transferred_to || []).forEach(add);
  return [...ids];
}

/**
 * RevenueCat REST API subscriber yanıtından entitlement bitiş zamanı (ms).
 * Ömür boyu: 2100; aktif değilse null.
 */
function entitlementExpiryMs(subscriber, entitlementId, now = Date.now()) {
  const ent = subscriber && subscriber.entitlements && subscriber.entitlements[entitlementId];
  if (!ent) return null;
  if (ent.expires_date == null) return LIFETIME_MS;
  const ms = Date.parse(ent.expires_date);
  return Number.isFinite(ms) && ms > now ? ms : null;
}

/** Üyelerin premium bitişlerinden en geç olanı ve sahibi. */
function latestPremium(entries, now = Date.now()) {
  let best = { untilMs: null, owner: null };
  for (const { uid, untilMs } of entries) {
    if (untilMs != null && untilMs > now && (best.untilMs == null || untilMs > best.untilMs)) {
      best = { untilMs, owner: uid };
    }
  }
  return best;
}

/** Cevap belgesine yeni eklenen uid alanları (meta alanlar hariç). */
const META_FIELDS = new Set(['id', 'updatedAt', '_order', 'authorId']);
function newAnswerers(before, after) {
  const prev = before || {};
  return Object.keys(after || {}).filter((k) => !META_FIELDS.has(k) && !(k in prev));
}

function answererIds(doc) {
  return Object.keys(doc || {}).filter((k) => !META_FIELDS.has(k));
}

const TEXTS = {
  tr: {
    thinking: (n) => ({ title: `${n} seni düşünüyor 💗`, body: 'Kalbine dokunmak istedi.' }),
    answerWaiting: (n) => ({
      title: `${n} günün sorusunu cevapladı`,
      body: 'Cevabını görmek için sen de cevapla 💬',
    }),
    answersRevealed: () => ({ title: 'Cevaplar açıldı! 🔓', body: 'İkiniz de günün sorusunu cevapladınız.' }),
    memory: (n, t) => ({ title: `${n} yeni bir anı ekledi 📸`, body: t || '' }),
    note: (n, locked) => ({
      title: `${n} sana bir not bıraktı 💌`,
      body: locked ? 'Zaman kapsülü: kilidi açıldığında okuyabileceksin.' : 'Hemen okumak için dokun.',
    }),
    noteUnlocked: (n) => ({ title: 'Zaman kapsülün açıldı! 💌', body: `${n} sana yazdığı notu artık okuyabilirsin.` }),
  },
  en: {
    thinking: (n) => ({ title: `${n} is thinking of you 💗`, body: 'They wanted to touch your heart.' }),
    answerWaiting: (n) => ({
      title: `${n} answered today's question`,
      body: 'Answer too to see their answer 💬',
    }),
    answersRevealed: () => ({ title: 'Answers revealed! 🔓', body: "You both answered today's question." }),
    memory: (n, t) => ({ title: `${n} added a new memory 📸`, body: t || '' }),
    note: (n, locked) => ({
      title: `${n} left you a note 💌`,
      body: locked ? 'Time capsule: you can read it once it unlocks.' : 'Tap to read it now.',
    }),
    noteUnlocked: (n) => ({ title: 'Your time capsule is open! 💌', body: `You can now read the note from ${n}.` }),
  },
};

function message(lang, key, ...args) {
  const texts = TEXTS[lang] || TEXTS.tr;
  return texts[key](...args);
}

module.exports = {
  LIFETIME_MS,
  partnerOf,
  nameOf,
  langOf,
  affectedUserIds,
  entitlementExpiryMs,
  latestPremium,
  newAnswerers,
  answererIds,
  message,
};
