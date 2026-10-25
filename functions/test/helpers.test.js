'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const h = require('../lib/helpers');

const couple = {
  memberIds: ['a', 'b'],
  user1Id: 'a',
  user1Name: 'Ayşe',
  user2Id: 'b',
  user2Name: 'Berk',
  langs: { b: 'en' },
};

test('partnerOf / nameOf / langOf', () => {
  assert.equal(h.partnerOf(couple, 'a'), 'b');
  assert.equal(h.partnerOf({ memberIds: ['a'] }, 'a'), null);
  assert.equal(h.nameOf(couple, 'b'), 'Berk');
  assert.equal(h.langOf(couple, 'b'), 'en');
  assert.equal(h.langOf(couple, 'a'), 'tr');
});

test('affectedUserIds skips anonymous RevenueCat ids', () => {
  const ids = h.affectedUserIds({
    app_user_id: 'uid1',
    original_app_user_id: '$RCAnonymousID:abc',
    aliases: ['uid1', 'uid2'],
    transferred_to: ['uid3'],
  });
  assert.deepEqual(ids.sort(), ['uid1', 'uid2', 'uid3']);
});

test('entitlementExpiryMs handles active, expired and lifetime', () => {
  const now = Date.UTC(2026, 9, 25);
  const sub = (expires) => ({ entitlements: { premium: { expires_date: expires } } });
  assert.equal(h.entitlementExpiryMs(sub('2027-01-01T00:00:00Z'), 'premium', now), Date.UTC(2027, 0, 1));
  assert.equal(h.entitlementExpiryMs(sub('2026-01-01T00:00:00Z'), 'premium', now), null);
  assert.equal(h.entitlementExpiryMs(sub(null), 'premium', now), h.LIFETIME_MS);
  assert.equal(h.entitlementExpiryMs({ entitlements: {} }, 'premium', now), null);
});

test('latestPremium picks the member with the latest active subscription', () => {
  const now = 1000;
  assert.deepEqual(
    h.latestPremium([{ uid: 'a', untilMs: 500 }, { uid: 'b', untilMs: 3000 }, { uid: 'c', untilMs: 2000 }], now),
    { untilMs: 3000, owner: 'b' },
  );
  assert.deepEqual(h.latestPremium([{ uid: 'a', untilMs: null }], now), { untilMs: null, owner: null });
});

test('newAnswerers ignores meta fields', () => {
  assert.deepEqual(h.newAnswerers({ a: 'x' }, { a: 'x', b: 'y', updatedAt: 1 }), ['b']);
  assert.deepEqual(h.newAnswerers(undefined, { a: 'x', _order: 1 }), ['a']);
  assert.deepEqual(h.answererIds({ a: 1, b: 2, id: 'q' }), ['a', 'b']);
});

test('messages are localized', () => {
  assert.match(h.message('tr', 'thinking', 'Ayşe').title, /seni düşünüyor/);
  assert.match(h.message('en', 'thinking', 'Ayşe').title, /thinking of you/);
  assert.match(h.message('xx', 'note', 'Ayşe', true).body, /Zaman kapsülü/);
});
