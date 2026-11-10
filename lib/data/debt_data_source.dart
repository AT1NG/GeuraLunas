import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geuralunas/data/firestore_paths.dart';

/// A document id with its raw data.
typedef RawDoc = ({String id, Map<String, Object?> data});

/// One write in a batch.
sealed class WriteOp {
  const WriteOp(this.path);

  /// Full document path.
  final String path;
}

/// Replaces the whole document at [path].
final class SetOp extends WriteOp {
  const SetOp(super.path, this.data);

  final Map<String, Object?> data;
}

/// Merges [data] into the document at [path], leaving other fields alone.
final class MergeOp extends WriteOp {
  const MergeOp(super.path, this.data);

  final Map<String, Object?> data;
}

/// Deletes the document at [path].
final class DeleteOp extends WriteOp {
  const DeleteOp(super.path);
}

/// Thin wrapper over Firestore for debts, installments and payments.
class DebtDataSource {
  DebtDataSource(FirebaseFirestore firestore) : _firestore = firestore;

  /// Firestore allows 500 writes per batch; stay below it.
  static const maxBatchSize = 450;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String path) =>
      _firestore.collection(path);

  List<RawDoc> _docs(QuerySnapshot<Map<String, dynamic>> s) => [
    for (final d in s.docs)
      (id: d.id, data: Map<String, Object?>.from(d.data())),
  ];

  RawDoc? _doc(DocumentSnapshot<Map<String, dynamic>> s) =>
      s.exists ? (id: s.id, data: Map<String, Object?>.from(s.data()!)) : null;

  String newDebtId(String uid) =>
      _collection(FirestorePaths.debts(uid)).doc().id;

  String newPaymentId(String uid, String debtId) =>
      _collection(FirestorePaths.payments(uid, debtId)).doc().id;

  Stream<List<RawDoc>> watchDebts(String uid) =>
      _collection(FirestorePaths.debts(uid)).snapshots().map(_docs);

  Stream<RawDoc?> watchDebt(String uid, String debtId) =>
      _firestore.doc(FirestorePaths.debt(uid, debtId)).snapshots().map(_doc);

  Stream<List<RawDoc>> watchInstallments(String uid, String debtId) =>
      _collection(
        FirestorePaths.installments(uid, debtId),
      ).snapshots().map(_docs);

  Stream<List<RawDoc>> watchPayments(String uid, String debtId) =>
      _collection(FirestorePaths.payments(uid, debtId)).snapshots().map(_docs);

  Future<RawDoc?> getDebt(String uid, String debtId) async =>
      _doc(await _firestore.doc(FirestorePaths.debt(uid, debtId)).get());

  Future<List<RawDoc>> getInstallments(String uid, String debtId) async =>
      _docs(await _collection(FirestorePaths.installments(uid, debtId)).get());

  Future<List<RawDoc>> getPayments(String uid, String debtId) async =>
      _docs(await _collection(FirestorePaths.payments(uid, debtId)).get());

  /// Applies [ops]; see [writeBatches].
  Future<void> write(List<WriteOp> ops) => writeBatches(_firestore, ops);
}

/// Applies [ops] in batches of at most [DebtDataSource.maxBatchSize] writes.
///
/// All batches are started before any is awaited, so nothing queues behind
/// a server acknowledgement that cannot arrive while offline. The returned
/// future completes when the server has acknowledged every batch.
Future<void> writeBatches(FirebaseFirestore firestore, List<WriteOp> ops) {
  const size = DebtDataSource.maxBatchSize;
  final commits = <Future<void>>[];
  for (var start = 0; start < ops.length; start += size) {
    final batch = firestore.batch();
    final end = start + size < ops.length ? start + size : ops.length;
    for (final op in ops.sublist(start, end)) {
      final ref = firestore.doc(op.path);
      switch (op) {
        case SetOp(:final data):
          batch.set(ref, data);
        case MergeOp(:final data):
          batch.set(ref, data, SetOptions(merge: true));
        case DeleteOp():
          batch.delete(ref);
      }
    }
    commits.add(batch.commit());
  }
  return Future.wait(commits);
}
