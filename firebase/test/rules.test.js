const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  setDoc,
  getDoc,
  doc,
  Timestamp,
  serverTimestamp,
} = require('firebase/firestore');

let env;

const validProfile = () => ({
  displayName: 'Rani',
  email: 'rani@mail.com',
  createdAt: serverTimestamp(),
  settings: {
    reminderTime: '08:00',
    reminderDaysBefore: [3, 1, 0],
    budgetCycleStartDay: 1,
    timezone: 'Asia/Jakarta',
  },
});

const withSettings = (overrides) => {
  const p = validProfile();
  p.settings = { ...p.settings, ...overrides };
  return p;
};

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'geuralunas-dev',
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', '..', 'firestore.rules'),
        'utf8',
      ),
    },
  });
});

after(async () => env.cleanup());

beforeEach(async () => env.clearFirestore());

const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

test('owner can create own profile', async () => {
  await assertSucceeds(setDoc(doc(as('a'), 'users/a'), validProfile()));
});

test('owner can read own profile', async () => {
  await seed('users/a', validProfile());
  await assertSucceeds(getDoc(doc(as('a'), 'users/a')));
});

test('other user cannot read profile', async () => {
  await seed('users/a', validProfile());
  await assertFails(getDoc(doc(as('b'), 'users/a')));
});

test('other user cannot write profile', async () => {
  await assertFails(setDoc(doc(as('b'), 'users/a'), validProfile()));
});

test('unauthenticated cannot read or write', async () => {
  await seed('users/a', validProfile());
  await assertFails(getDoc(doc(anon(), 'users/a')));
  await assertFails(setDoc(doc(anon(), 'users/a'), validProfile()));
  await assertFails(setDoc(doc(anon(), 'users/a/debts/d1'), { x: 1 }));
});

test('owner can write to a subcollection doc', async () => {
  await assertSucceeds(setDoc(doc(as('a'), 'users/a/debts/d1'), { x: 1 }));
});

test('other user cannot read subcollection doc', async () => {
  await seed('users/a/debts/d1', { x: 1 });
  await assertFails(getDoc(doc(as('b'), 'users/a/debts/d1')));
});

test('profile with unknown field is denied', async () => {
  await assertFails(
    setDoc(doc(as('a'), 'users/a'), { ...validProfile(), isAdmin: true }),
  );
});

test('budgetCycleStartDay 0 and 29 are denied, 1 and 28 allowed', async () => {
  const ref = doc(as('a'), 'users/a');
  await assertFails(setDoc(ref, withSettings({ budgetCycleStartDay: 0 })));
  await assertFails(setDoc(ref, withSettings({ budgetCycleStartDay: 29 })));
  await assertSucceeds(setDoc(ref, withSettings({ budgetCycleStartDay: 1 })));
  await env.clearFirestore(); // createdAt is immutable, so start from a fresh doc
  await assertSucceeds(setDoc(ref, withSettings({ budgetCycleStartDay: 28 })));
});

test('reminderDaysBefore must be a list', async () => {
  const ref = doc(as('a'), 'users/a');
  await assertFails(setDoc(ref, withSettings({ reminderDaysBefore: 3 })));
  await assertFails(setDoc(ref, withSettings({ reminderDaysBefore: ['3'] })));
  await assertSucceeds(setDoc(ref, withSettings({ reminderDaysBefore: [] })));
});

test('reminderTime must match HH:mm', async () => {
  const ref = doc(as('a'), 'users/a');
  await assertFails(setDoc(ref, withSettings({ reminderTime: '8am' })));
  await assertFails(setDoc(ref, withSettings({ reminderTime: '24:00' })));
  await assertFails(setDoc(ref, withSettings({ reminderTime: '08:60' })));
  await assertSucceeds(setDoc(ref, withSettings({ reminderTime: '23:59' })));
});

test('document outside users/ is denied', async () => {
  await assertFails(setDoc(doc(as('a'), 'other/a'), { x: 1 }));
  await assertFails(getDoc(doc(as('a'), 'other/a')));
});

test('createdAt must be the server time on create', async () => {
  const old = Timestamp.fromDate(new Date('2020-01-01T00:00:00Z'));
  await assertFails(
    setDoc(doc(as('a'), 'users/a'), { ...validProfile(), createdAt: old }),
  );
});

test('createdAt cannot be rewritten on update', async () => {
  await seed('users/a', {
    ...validProfile(),
    createdAt: Timestamp.fromDate(new Date('2024-05-05T00:00:00Z')),
  });
  await assertFails(
    setDoc(doc(as('a'), 'users/a'), { ...validProfile(), createdAt: serverTimestamp() }),
  );
});

test('merging only displayName into existing profile is allowed', async () => {
  await seed('users/a', {
    ...validProfile(),
    createdAt: Timestamp.fromDate(new Date('2024-05-05T00:00:00Z')),
  });
  await assertSucceeds(
    setDoc(doc(as('a'), 'users/a'), { displayName: 'Rani B' }, { merge: true }),
  );
});

test('overlong displayName is denied', async () => {
  await assertFails(
    setDoc(doc(as('a'), 'users/a'), {
      ...validProfile(),
      displayName: 'x'.repeat(101),
    }),
  );
});

test('reminderDaysBefore with more than 8 entries is denied', async () => {
  await assertFails(
    setDoc(
      doc(as('a'), 'users/a'),
      withSettings({ reminderDaysBefore: [1, 1, 1, 1, 1, 1, 1, 1, 1] }),
    ),
  );
});

test('owner can write a deep path, other user cannot', async () => {
  await assertSucceeds(setDoc(doc(as('a'), 'users/a/debts/d1/payments/p1'), { x: 1 }));
  await assertFails(setDoc(doc(as('b'), 'users/a/debts/d1/payments/p1'), { x: 1 }));
});
