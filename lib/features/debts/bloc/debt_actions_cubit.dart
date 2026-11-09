import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/repositories/debt_repository.dart';

/// Progress of the last action.
enum ActionStatus { idle, working, done, failure }

/// What the user asked for.
enum DebtAction { archive, unarchive, delete, markSettled }

/// Note stored on the payment created by "Tandai lunas".
const markSettledNote = 'Ditandai lunas';

final class DebtActionsState extends Equatable {
  const DebtActionsState({this.status = ActionStatus.idle, this.action});

  final ActionStatus status;

  /// The action `status` refers to; `null` before anything ran.
  final DebtAction? action;

  @override
  List<Object?> get props => [status, action];
}

/// Archive, delete and "mark as paid" for one debt.
class DebtActionsCubit extends Cubit<DebtActionsState> {
  DebtActionsCubit(this._repository, this._debtId, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const DebtActionsState());

  final DebtRepository _repository;
  final String _debtId;
  final DateTime Function() _now;

  /// A late result must not throw if the screen is already gone.
  @override
  void emit(DebtActionsState state) {
    if (!isClosed) super.emit(state);
  }

  Future<void> archive() => _run(
    DebtAction.archive,
    () => _repository.setArchived(_debtId, archived: true),
  );

  /// Not reachable from a screen yet (archived debts are hidden); kept for
  /// the screen that will list them.
  Future<void> unarchive() => _run(
    DebtAction.unarchive,
    () => _repository.setArchived(_debtId, archived: false),
  );

  Future<void> delete() =>
      _run(DebtAction.delete, () => _repository.deleteDebt(_debtId));

  /// Records one payment for exactly what is still owed, dated today.
  /// Does nothing if the debt is not active or has nothing left.
  Future<void> markSettled() => _run(DebtAction.markSettled, () async {
    final debt = await _repository.watchDebt(_debtId).first;
    if (debt == null) throw DebtNotFound(_debtId);
    if (debt.status != DebtStatus.active || debt.remaining.isZero) return;
    final now = _now();
    await _repository.recordPayment(
      debtId: _debtId,
      amount: debt.remaining,
      paidAt: DateTime(now.year, now.month, now.day),
      note: markSettledNote,
    );
  });

  Future<void> _run(DebtAction action, Future<void> Function() body) async {
    if (state.status == ActionStatus.working) return;
    emit(DebtActionsState(status: ActionStatus.working, action: action));
    try {
      await body();
      emit(DebtActionsState(status: ActionStatus.done, action: action));
    } on Object {
      emit(DebtActionsState(status: ActionStatus.failure, action: action));
    }
  }
}
