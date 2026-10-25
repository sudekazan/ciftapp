'use strict';

// Firestore + Storage güvenlik kuralı testleri. Çalıştırmak için: npm test
// (Firebase emülatörlerini başlatır, testleri koşar ve kapatır.)

const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  getDocs,
  serverTimestamp,
  deleteField,
  query,
  where,
} = require('firebase/firestore');
const { ref, uploadString, getBytes } = require('firebase/storage');

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-yanyana',
    firestore: { rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8') },
    storage: { rules: fs.readFileSync(path.join(__dirname, '..', 'storage.rules'), 'utf8') },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

const db = (uid) => env.authenticatedContext(uid).firestore();
const anonDb = () => env.unauthenticatedContext().firestore();

/** Aynı istemci akışı: çift alanını ve davet kodunu oluştur. */
async function createSpace(uid, coupleId = 'cpl_a', code = 'CFT-AAAAAA') {
  await setDoc(doc(db(uid), 'couples', coupleId), {
    coupleId,
    inviteCode: code,
    user1Id: uid,
    user1Name: 'Ayşe',
    user2Id: null,
    user2Name: null,
    memberIds: [uid],
    tokens: { [uid]: 'token-a' },
    mode: 'long_distance',
    startDate: '2024-01-01T00:00:00.000',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  await setDoc(doc(db(uid), 'invites', code), {
    coupleId,
    ownerId: uid,
    ownerName: 'Ayşe',
    updatedAt: serverTimestamp(),
  });
}

function joinUpdate(uid, code = 'CFT-AAAAAA', owner = 'alice') {
  return {
    user2Id: uid,
    user2Name: 'Berk',
    memberIds: [owner, uid],
    [`tokens.${uid}`]: 'token-b',
    joinCode: code,
    pairedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}

async function pairedCouple() {
  await createSpace('alice');
  await updateDoc(doc(db('bob'), 'couples', 'cpl_a'), joinUpdate('bob'));
}

// --- Çift alanı oluşturma ---

test('a user can create their own couple space and invite', async () => {
  await assertSucceeds(createSpace('alice'));
});

test('a couple space cannot be created with someone else inside', async () => {
  await assertFails(
    setDoc(doc(db('alice'), 'couples', 'cpl_x'), {
      user1Id: 'alice',
      user2Id: null,
      memberIds: ['alice', 'victim'],
      tokens: {},
    }),
  );
});

test('clients cannot grant themselves premium', async () => {
  await assertFails(
    setDoc(doc(db('alice'), 'couples', 'cpl_x'), {
      user1Id: 'alice',
      user2Id: null,
      memberIds: ['alice'],
      tokens: {},
      premiumUntil: new Date(2100, 0, 1),
    }),
  );
  await createSpace('alice');
  await assertFails(updateDoc(doc(db('alice'), 'couples', 'cpl_a'), { premiumUntil: new Date(2100, 0, 1) }));
  await assertFails(setDoc(doc(db('alice'), 'users', 'alice'), { premiumUntil: new Date(2100, 0, 1) }));
});

test("an invite cannot point to someone else's couple space", async () => {
  await createSpace('alice');
  await assertFails(
    setDoc(doc(db('mallory'), 'invites', 'CFT-MMMMMM'), { coupleId: 'cpl_a', ownerId: 'mallory' }),
  );
  // ...and an existing invite cannot be hijacked.
  await assertFails(
    setDoc(doc(db('mallory'), 'invites', 'CFT-AAAAAA'), { coupleId: 'cpl_m', ownerId: 'mallory' }),
  );
});

// --- Gizlilik ---

test('couples cannot be listed or read by strangers', async () => {
  await createSpace('alice');
  await assertFails(getDocs(collection(db('mallory'), 'couples')));
  await assertFails(getDocs(query(collection(db('mallory'), 'couples'), where('inviteCode', '==', 'CFT-AAAAAA'))));
  await assertFails(getDoc(doc(db('mallory'), 'couples', 'cpl_a')));
  await assertFails(getDoc(doc(anonDb(), 'invites', 'CFT-AAAAAA')));
  await assertFails(getDocs(collection(db('mallory'), 'invites')));
});

test('an invite can be read by code but not listed', async () => {
  await createSpace('alice');
  await assertSucceeds(getDoc(doc(db('bob'), 'invites', 'CFT-AAAAAA')));
});

// --- Eşleşme ---

test('a partner can join with the invite code', async () => {
  await createSpace('alice');
  await assertSucceeds(updateDoc(doc(db('bob'), 'couples', 'cpl_a'), joinUpdate('bob')));
  await assertSucceeds(getDoc(doc(db('bob'), 'couples', 'cpl_a')));
});

test('a taken seat cannot be stolen', async () => {
  await pairedCouple();
  await assertFails(updateDoc(doc(db('mallory'), 'couples', 'cpl_a'), joinUpdate('mallory')));
});

test('joining requires the matching invite code', async () => {
  await createSpace('alice');
  await createSpace('carol', 'cpl_c', 'CFT-CCCCCC');
  await assertFails(updateDoc(doc(db('bob'), 'couples', 'cpl_a'), joinUpdate('bob', 'CFT-CCCCCC')));
  await assertFails(updateDoc(doc(db('bob'), 'couples', 'cpl_a'), joinUpdate('bob', 'CFT-NOPE00')));
});

test("a joiner cannot touch other fields or the owner's token", async () => {
  await createSpace('alice');
  await assertFails(
    updateDoc(doc(db('bob'), 'couples', 'cpl_a'), { ...joinUpdate('bob'), premiumUntil: new Date(2100, 0, 1) }),
  );
  await assertFails(
    updateDoc(doc(db('bob'), 'couples', 'cpl_a'), { ...joinUpdate('bob'), 'tokens.alice': 'hijacked' }),
  );
  await assertFails(updateDoc(doc(db('bob'), 'couples', 'cpl_a'), { ...joinUpdate('bob'), mode: 'co_living' }));
});

test('the owner cannot join their own space as the partner', async () => {
  await createSpace('alice');
  await assertFails(updateDoc(doc(db('alice'), 'couples', 'cpl_a'), joinUpdate('alice')));
});

// --- Üye işlemleri ---

test('members share settings and content; strangers cannot', async () => {
  await pairedCouple();
  await assertSucceeds(
    updateDoc(doc(db('bob'), 'couples', 'cpl_a'), {
      'tz.bob': { name: 'Europe/London', offsetMinutes: 0 },
      reunionDate: '2030-01-01T00:00:00.000',
    }),
  );
  await assertSucceeds(setDoc(doc(db('alice'), 'couples', 'cpl_a', 'memories', 'm1'), { id: 'm1', title: 'İlk' }));
  await assertSucceeds(getDoc(doc(db('bob'), 'couples', 'cpl_a', 'memories', 'm1')));
  await assertFails(getDoc(doc(db('mallory'), 'couples', 'cpl_a', 'memories', 'm1')));
  await assertFails(setDoc(doc(db('mallory'), 'couples', 'cpl_a', 'memories', 'm2'), { id: 'm2' }));
  await assertFails(updateDoc(doc(db('mallory'), 'couples', 'cpl_a'), { mode: 'co_living' }));
});

test('a member cannot add a third person', async () => {
  await pairedCouple();
  await assertFails(updateDoc(doc(db('alice'), 'couples', 'cpl_a'), { memberIds: ['alice', 'bob', 'mallory'] }));
  await assertFails(updateDoc(doc(db('alice'), 'couples', 'cpl_a'), { memberIds: ['alice', 'mallory'] }));
});

test('leaving: the remaining partner keeps the space', async () => {
  await pairedCouple();
  await assertSucceeds(
    updateDoc(doc(db('alice'), 'couples', 'cpl_a'), {
      memberIds: ['bob'],
      user1Id: 'bob',
      user1Name: 'Berk',
      user2Id: null,
      user2Name: null,
      'tokens.alice': deleteField(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(getDoc(doc(db('alice'), 'couples', 'cpl_a', 'memories', 'm1')));
  await assertSucceeds(getDoc(doc(db('bob'), 'couples', 'cpl_a')));
});

test('a shared couple cannot be deleted; the last member can delete it', async () => {
  await pairedCouple();
  await assertFails(deleteDoc(doc(db('alice'), 'couples', 'cpl_a')));
  await createSpace('carol', 'cpl_c', 'CFT-CCCCCC');
  await assertSucceeds(deleteDoc(doc(db('carol'), 'couples', 'cpl_c')));
});

test('users can read only their own subscription document', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users', 'alice'), { premiumUntil: new Date(2100, 0, 1) });
  });
  await assertSucceeds(getDoc(doc(db('alice'), 'users', 'alice')));
  await assertFails(getDoc(doc(db('bob'), 'users', 'alice')));
});

// --- Storage ---

test('only couple members can upload and view photos', async () => {
  await pairedCouple();
  const photo = (uid) => ref(env.authenticatedContext(uid).storage(), 'couples/cpl_a/memories/p.jpg');
  await assertSucceeds(uploadString(photo('alice'), 'data', 'raw', { contentType: 'image/jpeg' }));
  await assertSucceeds(getBytes(photo('bob')));
  await assertFails(getBytes(photo('mallory')));
  await assertFails(uploadString(photo('mallory'), 'data', 'raw', { contentType: 'image/jpeg' }));
  await assertFails(
    uploadString(ref(env.authenticatedContext('alice').storage(), 'couples/cpl_a/memories/x.exe'), 'data', 'raw', {
      contentType: 'application/octet-stream',
    }),
  );
  await assertFails(
    uploadString(ref(env.authenticatedContext('alice').storage(), 'memories/alice/old.jpg'), 'data', 'raw', {
      contentType: 'image/jpeg',
    }),
  );
});
