import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/interest.dart';
import 'package:geuralunas/domain/debt/payments.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/features/debts/bloc/debt_form_cubit.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/debt_fixtures.dart';

final today = DateTime(2026, 11, 9, 14);

void main() {
  late MockDebtRepository repo;

  setUpAll(() {
    registerFallbackValue(
      NewDebt(
        direction: DebtDirection.owe,
        kind: DebtKind.personal,
        counterpartyName: 'x',
        principal: const Money(1),
        frequency: Frequency.once,
        startDate: DateTime(2026),
      ),
    );
    registerFallbackValue(makeDebt());
  });

  setUp(() {
    repo = MockDebtRepository();
    when(() => repo.addDebt(any())).thenAnswer((_) async => 'new-id');
    when(
      () => repo.updateDebt(any(), schedule: any(named: 'schedule')),
    ).thenAnswer((_) async {});
  });

  DebtFormCubit cubit({Debt? editing}) =>
      DebtFormCubit(repo, editing: editing, now: () => today);

  DebtFormCubit filled() => cubit()
    ..nameChanged('Pinjol B')
    ..principalChanged('1.000.000');

  group('validation', () {
    test('an empty or blank name is rejected', () {
      final c = cubit()..principalChanged('1000');
      expect(c.state.errors[DebtFormField.name], DebtFormError.required);
      c.nameChanged('   ');
      expect(c.state.errors[DebtFormField.name], DebtFormError.required);
      c.nameChanged(' Rani ');
      expect(c.state.errors.containsKey(DebtFormField.name), isFalse);
    });

    test('principal must be a positive amount', () {
      final c = cubit()..nameChanged('X');
      expect(c.state.errors[DebtFormField.principal], DebtFormError.required);
      for (final bad in ['0', '-5', 'abc', '1.5']) {
        c.principalChanged(bad);
        expect(
          c.state.errors[DebtFormField.principal],
          DebtFormError.invalidAmount,
          reason: bad,
        );
      }
      c.principalChanged('1.500.000');
      expect(c.state.errors.containsKey(DebtFormField.principal), isFalse);
    });

    test('tenor zero is rejected for an installment', () {
      final c = filled()
        ..kindChanged(DebtKind.installment)
        ..interestTypeChanged(InterestType.flatMonthly)
        ..rateChanged('2')
        ..tenorChanged('0');
      expect(c.state.errors[DebtFormField.tenor], DebtFormError.invalidNumber);
    });

    test('tenor is required when there is interest', () {
      final c = filled()
        ..interestTypeChanged(InterestType.flatMonthly)
        ..rateChanged('3');
      expect(c.state.errors[DebtFormField.tenor], DebtFormError.required);
      c.tenorChanged('3');
      expect(c.state.errors.containsKey(DebtFormField.tenor), isFalse);
    });

    test('tenor is optional without interest', () {
      final c = filled()..kindChanged(DebtKind.installment);
      expect(c.state.errors.containsKey(DebtFormField.tenor), isFalse);
    });

    test('the interest rate is required and cannot be negative', () {
      final c = filled()
        ..interestTypeChanged(InterestType.flatMonthly)
        ..tenorChanged('3');
      expect(
        c.state.errors[DebtFormField.interestRate],
        DebtFormError.required,
      );
      c.rateChanged('-1');
      expect(
        c.state.errors[DebtFormField.interestRate],
        DebtFormError.invalidNumber,
      );
      c.rateChanged('0,4');
      expect(c.state.errors.containsKey(DebtFormField.interestRate), isFalse);
    });

    test('an invalid admin fee is rejected, blank is fine', () {
      final c = filled();
      expect(c.state.errors.containsKey(DebtFormField.adminFee), isFalse);
      c.adminFeeChanged('abc');
      expect(
        c.state.errors[DebtFormField.adminFee],
        DebtFormError.invalidAmount,
      );
      c.adminFeeChanged('25.000');
      expect(c.state.errors.containsKey(DebtFormField.adminFee), isFalse);
    });

    test('a personal debt ignores interest, fee and tenor', () {
      final c = filled()
        ..interestTypeChanged(InterestType.flatMonthly)
        ..rateChanged('abc')
        ..tenorChanged('0')
        ..kindChanged(DebtKind.personal);
      expect(c.state.errors, isEmpty);
      expect(c.state.interestType, InterestType.none);
      expect(c.state.tenor, isEmpty);
    });
  });

  group('preview', () {
    test('is empty until the input is valid', () {
      expect(cubit().state.plan, isNull);
      expect(filled().state.plan, isNotNull);
      expect((filled()..principalChanged('0')).state.plan, isNull);
    });

    test('does not wait for the name', () {
      final c = cubit()..principalChanged('500.000');
      expect(c.state.errors.containsKey(DebtFormField.name), isTrue);
      expect(c.state.plan!.totalPayable, const Money(500000));
    });

    test('total matches calculateTotalPayable', () {
      final c = filled()
        ..principalChanged('12.000.000')
        ..interestTypeChanged(InterestType.reducingMonthly)
        ..rateChanged('2')
        ..tenorChanged('12');

      expect(
        c.state.plan!.totalPayable,
        calculateTotalPayable(
          principal: const Money(12000000),
          interestType: InterestType.reducingMonthly,
          interestRate: 2,
          adminFee: Money.zero,
          periods: 12,
        ),
      );
      expect(c.state.plan!.totalPayable, const Money(13616580));
    });

    test('the schedule sums to the total and follows the tenor', () {
      final c = filled()
        ..principalChanged('1.000.000')
        ..interestTypeChanged(InterestType.flatMonthly)
        ..rateChanged('3')
        ..adminFeeChanged('10.000')
        ..tenorChanged('3');

      final plan = c.state.plan!;
      expect(plan.installments.length, 3);
      expect(
        plan.installments.fold(0, (s, i) => s + i.amount.rupiah),
        plan.totalPayable.rupiah,
      );
      expect(plan.totalPayable, const Money(1100000));
    });

    test('a personal debt without tenor has no schedule', () {
      final c = filled()..kindChanged(DebtKind.personal);
      expect(c.state.plan!.installments, isEmpty);
    });

    test('a personal debt with a due date has one installment', () {
      final c = filled()
        ..kindChanged(DebtKind.personal)
        ..firstDueDateChanged(DateTime(2026, 11, 20));
      expect(c.state.plan!.installments.single.dueDate, DateTime(2026, 11, 20));
    });

    test('flat daily makes one installment at start plus days', () {
      final c = filled()
        ..principalChanged('1.000.000')
        ..interestTypeChanged(InterestType.flatDaily)
        ..rateChanged('0,4')
        ..tenorChanged('30')
        ..startDateChanged(DateTime(2026, 11));

      final plan = c.state.plan!;
      expect(plan.installments.single.dueDate, DateTime(2026, 12));
      expect(plan.totalPayable, const Money(1120000));
    });

    test('changing the tenor updates the preview', () {
      final c = filled()
        ..principalChanged('900.000')
        ..kindChanged(DebtKind.installment)
        ..tenorChanged('3');
      expect(c.state.plan!.installments.length, 3);
      c.tenorChanged('2');
      expect(c.state.plan!.installments.length, 2);
      expect(c.state.plan!.installments.first.amount, const Money(450000));
    });
  });

  group('submit', () {
    test(
      'with errors it shows them and does not touch the repository',
      () async {
        final c = cubit();
        await c.submit();

        expect(c.state.showErrors, isTrue);
        expect(c.state.status, SubmitStatus.idle);
        verifyNever(() => repo.addDebt(any()));
      },
    );

    test('calls addDebt once with the trimmed name', () async {
      final c = cubit()
        ..nameChanged('  Pinjol B  ')
        ..noteChanged('dari aplikasi')
        ..principalChanged('1.000.000')
        ..interestTypeChanged(InterestType.flatMonthly)
        ..rateChanged('3')
        ..tenorChanged('3');

      await Future.wait([c.submit(), c.submit()]);

      final captured = verify(() => repo.addDebt(captureAny())).captured;
      expect(captured, hasLength(1));
      final input = captured.single as NewDebt;
      expect(input.counterpartyName, 'Pinjol B');
      expect(input.note, 'dari aplikasi');
      expect(input.principal, const Money(1000000));
      expect(input.interestType, InterestType.flatMonthly);
      expect(input.interestRate, 3);
      expect(input.tenorCount, 3);
      expect(input.direction, DebtDirection.owe);
      expect(input.kind, DebtKind.pinjol);
      expect(c.state.status, SubmitStatus.success);
    });

    test('a lent personal debt is sent without interest or tenor', () async {
      final c = cubit()
        ..directionChanged(DebtDirection.lent)
        ..kindChanged(DebtKind.personal)
        ..nameChanged('Budi')
        ..principalChanged('100.000');

      await c.submit();

      final input =
          verify(() => repo.addDebt(captureAny())).captured.single as NewDebt;
      expect(input.direction, DebtDirection.lent);
      expect(input.interestType, InterestType.none);
      expect(input.tenorCount, isNull);
      expect(input.adminFee, Money.zero);
    });

    test('a failure shows an error and keeps the input', () async {
      when(() => repo.addDebt(any())).thenThrow(StateError('boom'));
      final c = filled();

      await c.submit();

      expect(c.state.status, SubmitStatus.failure);
      expect(c.state.failure, DebtFormFailure.unknown);
      expect(c.state.name, 'Pinjol B');
      expect(c.state.principal, '1.000.000');
    });

    test('finishing after the cubit is closed does not throw', () async {
      final c = filled();
      final pending = c.submit();
      await c.close();
      await expectLater(pending, completes);
    });
  });

  group('editing', () {
    Debt existing() => makeDebt(
      name: 'Paylater A',
      kind: DebtKind.installment,
      total: 900000,
      remaining: 300000,
    ).copyWith(tenorCount: 3, note: 'catatan');

    test('loads the existing values', () {
      final c = cubit(editing: existing());
      expect(c.state.name, 'Paylater A');
      expect(c.state.note, 'catatan');
      expect(c.state.principal, '900000');
      expect(c.state.kind, DebtKind.installment);
      expect(c.state.tenor, '3');
      expect(c.state.paidTotal, const Money(600000));
    });

    test('cannot lower the total below what is already paid', () async {
      final c = cubit(editing: existing())..principalChanged('300.000');

      expect(c.state.errors[DebtFormField.principal], DebtFormError.belowPaid);
      await c.submit();
      verifyNever(
        () => repo.updateDebt(any(), schedule: any(named: 'schedule')),
      );
      expect(c.state.showErrors, isTrue);
    });

    test('a name-only change sends no schedule', () async {
      final c = cubit(editing: existing())..nameChanged('Paylater B');

      await c.submit();

      final captured = verify(
        () => repo.updateDebt(
          captureAny(),
          schedule: captureAny(named: 'schedule'),
        ),
      ).captured;
      expect((captured[0] as Debt).counterpartyName, 'Paylater B');
      expect(captured[1], isNull);
      expect(c.state.status, SubmitStatus.success);
    });

    test('a money change sends the recomputed schedule', () async {
      final c = cubit(editing: existing())
        ..principalChanged('1.200.000')
        ..tenorChanged('4');

      await c.submit();

      final captured = verify(
        () => repo.updateDebt(
          captureAny(),
          schedule: captureAny(named: 'schedule'),
        ),
      ).captured;
      final debt = captured[0] as Debt;
      final schedule = captured[1] as List<Installment>;
      expect(debt.principal, const Money(1200000));
      expect(debt.totalPayable, const Money(1200000));
      expect(debt.tenorCount, 4);
      expect(schedule.length, 4);
      expect(schedule.fold(0, (s, i) => s + i.amount.rupiah), 1200000);
    });

    test('clearing the note really removes it', () async {
      final c = cubit(editing: existing())..noteChanged('  ');

      await c.submit();

      final debt =
          verify(
                () => repo.updateDebt(
                  captureAny(),
                  schedule: any(named: 'schedule'),
                ),
              ).captured.single
              as Debt;
      expect(debt.note, isNull);
    });

    test(
      'the repository refusing the total shows a belowPaid failure',
      () async {
        when(
          () => repo.updateDebt(any(), schedule: any(named: 'schedule')),
        ).thenThrow(const PaymentExceedsRemaining(remaining: Money(1)));
        final c = cubit(editing: existing())..principalChanged('1.200.000');

        await c.submit();

        expect(c.state.status, SubmitStatus.failure);
        expect(c.state.failure, DebtFormFailure.belowPaid);
      },
    );
  });
}
