/// Firestore document and collection paths (see `docs/DATABASE.md`).
abstract final class FirestorePaths {
  static String debts(String uid) => 'users/$uid/debts';

  static String debt(String uid, String debtId) => '${debts(uid)}/$debtId';

  static String installments(String uid, String debtId) =>
      '${debt(uid, debtId)}/installments';

  /// Installment ids are zero-padded so they sort in order: `001`, `002`, ...
  static String installmentId(int seq) => seq.toString().padLeft(3, '0');

  static String installment(String uid, String debtId, int seq) =>
      '${installments(uid, debtId)}/${installmentId(seq)}';

  static String payments(String uid, String debtId) =>
      '${debt(uid, debtId)}/payments';

  static String payment(String uid, String debtId, String paymentId) =>
      '${payments(uid, debtId)}/$paymentId';

  static String categories(String uid) => 'users/$uid/categories';

  static String category(String uid, String categoryId) =>
      '${categories(uid)}/$categoryId';

  static String expenses(String uid) => 'users/$uid/expenses';

  static String expense(String uid, String expenseId) =>
      '${expenses(uid)}/$expenseId';
}
