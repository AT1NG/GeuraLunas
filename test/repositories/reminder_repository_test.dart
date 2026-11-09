import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/data/notification_data_source.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/domain/reminder/reminder_plan.dart';
import 'package:geuralunas/domain/reminder/reminder_settings.dart';
import 'package:geuralunas/repositories/reminder_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/debt_fixtures.dart';
import '../helpers/fakes.dart';

class _MockNotifications extends Mock implements NotificationDataSource {}

Installment inst(int seq, DateTime due) => Installment(
  seq: seq,
  dueDate: due,
  amount: const Money(350000),
);

void main() {
  late MockDebtRepository debts;
  late FakeUserProfileRepository profiles;
  late _MockNotifications notifications;
  late ReminderRepositoryImpl repo;
  late List<String> events;
  final now = DateTime(2026, 12);

  setUpAll(() => registerFallbackValue(<ReminderPlan>[]));

  setUp(() {
    debts = MockDebtRepository();
    profiles = FakeUserProfileRepository();
    notifications = _MockNotifications();
    events = [];
    when(() => notifications.wallClockNow()).thenReturn(now);
    when(notifications.cancelAll).thenAnswer((_) async {
      events.add('C');
      await Future<void>.delayed(const Duration(milliseconds: 5));
    });
    when(
      () => notifications.schedule(any()),
    ).thenAnswer((_) async {
      events.add('S');
      await Future<void>.delayed(const Duration(milliseconds: 5));
    });
    when(() => debts.watchDebts()).thenAnswer(
      (_) => Stream.value([
        makeDebt(nextDue: DateTime(2026, 12, 20)),
        makeDebt(id: 'lent', direction: DebtDirection.lent),
        makeDebt(id: 'done', status: DebtStatus.settled),
      ]),
    );
    when(() => debts.watchInstallments(any())).thenAnswer(
      (_) => Stream.value([inst(1, DateTime(2026, 12, 20))]),
    );
    repo = ReminderRepositoryImpl(
      debts: debts,
      profiles: profiles,
      notifications: notifications,
      currentUid: () => 'u1',
    );
  });

  test('rescheduleAll cancels everything then schedules the plan', () async {
    final count = await repo.rescheduleAll();

    expect(count, 3);
    expect(events, ['C', 'S']);
    final plans =
        verify(
              () => notifications.schedule(captureAny()),
            ).captured.single
            as List<ReminderPlan>;
    expect(plans.map((p) => p.at), [
      DateTime(2026, 12, 17, 9),
      DateTime(2026, 12, 19, 9),
      DateTime(2026, 12, 20, 9),
    ]);
    expect(plans.every((p) => p.debtId == 'd1'), isTrue);
  });

  test('reads installments only for active owe debts', () async {
    await repo.rescheduleAll();
    verify(() => debts.watchInstallments('d1')).called(1);
    verifyNever(() => debts.watchInstallments('lent'));
    verifyNever(() => debts.watchInstallments('done'));
  });

  test('uses the reminder settings of the user', () async {
    profiles.setSettings(
      const ReminderSettings(
        hour: 7,
        minute: 30,
        daysBefore: [0],
        timezone: 'Asia/Makassar',
      ),
    );
    final count = await repo.rescheduleAll();
    expect(count, 1);
    final plans =
        verify(
              () => notifications.schedule(captureAny()),
            ).captured.single
            as List<ReminderPlan>;
    expect(plans.single.at, DateTime(2026, 12, 20, 7, 30));
  });

  test('concurrent calls run one after another', () async {
    await Future.wait([repo.rescheduleAll(), repo.rescheduleAll()]);
    expect(events, ['C', 'S', 'C', 'S']);
  });

  test('a failure is swallowed and the next call still works', () async {
    var first = true;
    when(
      () => notifications.schedule(any()),
    ).thenAnswer((_) async {
      if (first) {
        first = false;
        throw Exception('platform down');
      }
      events.add('S');
    });

    expect(await repo.rescheduleAll(), 0);
    expect(await repo.rescheduleAll(), 3);
    expect(events.last, 'S');
  });

  test('a failing debt stream is swallowed too', () async {
    when(() => debts.watchDebts()).thenAnswer(
      (_) => Stream<List<Debt>>.error(Exception('offline')),
    );
    expect(await repo.rescheduleAll(), 0);
  });

  test('does nothing without a signed in user', () async {
    final signedOut = ReminderRepositoryImpl(
      debts: debts,
      profiles: profiles,
      notifications: notifications,
      currentUid: () => null,
    );
    expect(await signedOut.rescheduleAll(), 0);
    verifyNever(() => debts.watchDebts());
    verifyNever(notifications.cancelAll);
  });

  test('cancelAll reads no data', () async {
    await repo.cancelAll();
    verify(notifications.cancelAll).called(1);
    verifyNever(() => debts.watchDebts());
  });

  test('cancelAll waits for a running reschedule', () async {
    final running = repo.rescheduleAll();
    await repo.cancelAll();
    await running;
    expect(events, ['C', 'S', 'C']);
  });

  test('permissions and taps come from the data source', () async {
    when(notifications.permissions).thenAnswer(
      (_) async =>
          const ReminderPermissions(notifications: true, exactAlarms: false),
    );
    when(() => notifications.launchDebtId).thenReturn('dX');
    expect((await repo.permissions()).notifications, isTrue);
    expect(repo.launchDebtId, 'dX');
  });
}
