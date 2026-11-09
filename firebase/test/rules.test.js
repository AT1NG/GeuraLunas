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
  deleteDoc,
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
  await assertFails(setDoc(doc(anon(), 'users/a/categories/c1'), { x: 1 }));
});

test('owner can write to a subcollection doc', async () => {
  await assertSucceeds(setDoc(doc(as('a'), 'users/a/categories/c1'), { x: 1 }));
});

test('other user cannot read subcollection doc', async () => {
  await seed('users/a/categories/c1', { x: 1 });
  await assertFails(getDoc(doc(as('b'), 'users/a/categories/c1')));
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
  await assertSucceeds(setDoc(doc(as('a'), 'users/a/categories/c1/x/y'), { x: 1 }));
  await assertFails(setDoc(doc(as('b'), 'users/a/categories/c1/x/y'), { x: 1 }));
});

// ---- debts, installments, payments (Phase 2) ----

const ts = (iso) => Timestamp.fromDate(new Date(iso));

const validDebt = (overrides = {}) => ({
  direction: 'owe',
  kind: 'installment',
  counterpartyName: 'Paylater A',
  principal: 900000,
  interestType: 'none',
  interestRate: 0,
  adminFee: 0,
  tenorCount: 3,
  frequency: 'monthly',
  startDate: ts('2026-11-05T00:00:00Z'),
  totalPayable: 900000,
  paidTotal: 0,
  remaining: 900000,
  nextDueDate: ts('2026-12-05T00:00:00Z'),
  status: 'active',
  createdAt: ts('2026-11-09T00:00:00Z'),
  updatedAt: ts('2026-11-09T00:00:00Z'),
  ...overrides,
});

const validInstallment = (overrides = {}) => ({
  seq: 1,
  dueDate: ts('2026-12-05T00:00:00Z'),
  amount: 300000,
  paidAmount: 0,
  status: 'pending',
  ...overrides,
});

const validPayment = (overrides = {}) => ({
  amount: 300000,
  paidAt: ts('2026-12-05T00:00:00Z'),
  createdAt: ts('2026-12-05T01:00:00Z'),
  ...overrides,
});

const debtRef = (db, uid = 'a') => doc(db, `users/${uid}/debts/d1`);

test('owner can create a valid debt', async () => {
  await assertSucceeds(setDoc(debtRef(as('a')), validDebt()));
});

test('owner can create a debt without optional fields', async () => {
  const d = validDebt();
  delete d.tenorCount;
  delete d.nextDueDate;
  await assertSucceeds(setDoc(debtRef(as('a')), d));
});

test('other user cannot read or write a debt', async () => {
  await seed('users/a/debts/d1', validDebt());
  await assertFails(getDoc(debtRef(as('b'))));
  await assertFails(setDoc(debtRef(as('b')), validDebt()));
});

test('principal 0 or negative is denied', async () => {
  await assertFails(setDoc(debtRef(as('a')), validDebt({ principal: 0 })));
  await assertFails(setDoc(debtRef(as('a')), validDebt({ principal: -5 })));
});

test('principal as a string is denied', async () => {
  await assertFails(setDoc(debtRef(as('a')), validDebt({ principal: '900000' })));
});

test('unknown enum values are denied', async () => {
  const ref = debtRef(as('a'));
  await assertFails(setDoc(ref, validDebt({ direction: 'borrowed' })));
  await assertFails(setDoc(ref, validDebt({ kind: 'loan' })));
  await assertFails(setDoc(ref, validDebt({ interestType: 'compound' })));
  await assertFails(setDoc(ref, validDebt({ frequency: 'daily' })));
  await assertFails(setDoc(ref, validDebt({ status: 'overdue' })));
});

test('negative remaining or paidTotal is denied', async () => {
  const ref = debtRef(as('a'));
  await assertFails(setDoc(ref, validDebt({ remaining: -1 })));
  await assertFails(setDoc(ref, validDebt({ paidTotal: -1 })));
});

test('paidTotal above totalPayable is denied', async () => {
  await assertFails(
    setDoc(debtRef(as('a')), validDebt({ paidTotal: 900001, remaining: 0 })),
  );
});

test('debt with an unknown field is denied', async () => {
  await assertFails(setDoc(debtRef(as('a')), validDebt({ owner: 'x' })));
});

test('debt missing a required field is denied', async () => {
  const d = validDebt();
  delete d.counterpartyName;
  await assertFails(setDoc(debtRef(as('a')), d));
});

test('counterpartyName must be 1 to 100 characters', async () => {
  const ref = debtRef(as('a'));
  await assertFails(setDoc(ref, validDebt({ counterpartyName: '' })));
  await assertFails(setDoc(ref, validDebt({ counterpartyName: 'x'.repeat(101) })));
  await assertSucceeds(setDoc(ref, validDebt({ counterpartyName: 'x'.repeat(100) })));
});

test('an overlong note is denied', async () => {
  await assertFails(setDoc(debtRef(as('a')), validDebt({ note: 'x'.repeat(501) })));
});

test('interestRate may be fractional but not negative', async () => {
  const ref = debtRef(as('a'));
  await assertSucceeds(setDoc(ref, validDebt({ interestRate: 0.4 })));
  await assertFails(setDoc(ref, validDebt({ interestRate: -0.1 })));
});

test('owner can delete a debt', async () => {
  await seed('users/a/debts/d1', validDebt());
  await assertSucceeds(deleteDoc(debtRef(as('a'))));
});

test('installment rules', async () => {
  const ref = (uid, id = '001') => doc(as(uid), `users/a/debts/d1/installments/${id}`);
  await assertSucceeds(setDoc(ref('a'), validInstallment()));
  await assertFails(setDoc(ref('b'), validInstallment()));
  await assertFails(setDoc(ref('a'), validInstallment({ amount: 0 })));
  await assertFails(setDoc(ref('a'), validInstallment({ paidAmount: 300001 })));
  await assertFails(setDoc(ref('a'), validInstallment({ paidAmount: -1 })));
  await assertFails(setDoc(ref('a'), validInstallment({ status: 'late' })));
  await assertFails(setDoc(ref('a'), validInstallment({ extra: 1 })));
  await assertSucceeds(
    setDoc(ref('a', '002'), validInstallment({ seq: 2, paidAmount: 300000, status: 'paid', paidAt: ts('2027-01-04T00:00:00Z') })),
  );
});

test('payment rules', async () => {
  const ref = (uid, id = 'p1') => doc(as(uid), `users/a/debts/d1/payments/${id}`);
  await assertSucceeds(setDoc(ref('a'), validPayment()));
  await assertSucceeds(
    setDoc(ref('a', 'p2'), validPayment({ installmentSeq: 2, note: 'transfer' })),
  );
  await assertFails(setDoc(ref('b'), validPayment()));
  await assertFails(setDoc(ref('a'), validPayment({ amount: 0 })));
  await assertFails(setDoc(ref('a'), validPayment({ amount: '300000' })));
  await assertFails(setDoc(ref('a'), validPayment({ paidAt: '2026-12-05' })));
  await assertFails(setDoc(ref('a'), validPayment({ extra: 1 })));
  await assertFails(setDoc(ref('a'), validPayment({ note: 'x'.repeat(501) })));
});

test('a payment cannot be read by another user', async () => {
  await seed('users/a/debts/d1/payments/p1', validPayment());
  await assertFails(getDoc(doc(as('b'), 'users/a/debts/d1/payments/p1')));
  await assertSucceeds(getDoc(doc(as('a'), 'users/a/debts/d1/payments/p1')));
});
