import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/data/notification_data_source.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/domain/reminder/reminder_plan.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

class _MockPlatform extends Mock implements NotificationsPlatform {}

ReminderPlan plan(int id, DateTime at, {int daysBefore = 1}) => ReminderPlan(
  id: id,
  at: at,
  debtId: 'd$id',
  debtName: 'Paylater A',
  amount: const Money(350000),
  daysBefore: daysBefore,
);

void main() {
  setUpAll(() async {
    await initializeFormatting();
    registerFallbackValue(tz.TZDateTime.utc(2026));
  });

  late _MockPlatform platform;
  late NotificationDataSource ds;

  void stubSchedule() {
    when(
      () => platform.schedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
        at: any(named: 'at'),
        exact: any(named: 'exact'),
      ),
    ).thenAnswer((_) async {});
  }

  setUp(() async {
    platform = _MockPlatform();
    when(
      () => platform.initialize(onTap: any(named: 'onTap')),
    ).thenAnswer((_) async {});
    when(platform.launchPayload).thenAnswer((_) async => null);
    when(platform.canScheduleExact).thenAnswer((_) async => true);
    when(platform.cancelAll).thenAnswer((_) async {});
    ds = NotificationDataSource(platform);
    await ds.init();
    stubSchedule();
  });

  VerificationResult verifySchedule(int id, {bool? exact}) => verify(
    () => platform.schedule(
      id: id,
      title: any(named: 'title'),
      body: any(named: 'body'),
      payload: any(named: 'payload'),
      at: any(named: 'at'),
      exact: exact ?? any(named: 'exact'),
    ),
  );

  test(
    'schedule sends one notification per plan with texts and payload',
    () async {
      await ds.schedule([
        plan(1, DateTime(2026, 12, 19, 9)),
      ]);

      final call = verify(
        () => platform.schedule(
          id: 1,
          title: 'Cicilan jatuh tempo',
          body: 'Cicilan Paylater A Rp350.000 jatuh tempo besok.',
          payload: 'd1',
          at: captureAny(named: 'at'),
          exact: true,
        ),
      )..called(1);
      final at = call.captured.single as tz.TZDateTime;
      expect(at.toUtc(), DateTime(2026, 12, 19, 9).toUtc());
    },
  );

  test('uses inexact alarms when exact alarms are not allowed', () async {
    when(platform.canScheduleExact).thenAnswer((_) async => false);
    await ds.schedule([
      plan(1, DateTime(2026, 12, 19, 9)),
    ]);
    verifySchedule(1, exact: false).called(1);
  });

  test('one failing notification does not stop the rest', () async {
    when(
      () => platform.schedule(
        id: 1,
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
        at: any(named: 'at'),
        exact: any(named: 'exact'),
      ),
    ).thenThrow(Exception('boom'));

    await ds.schedule([
      plan(1, DateTime(2026, 12, 19, 9)),
      plan(2, DateTime(2026, 12, 20, 9)),
    ]);

    verifySchedule(2).called(1);
  });

  test('reminders fire at the time shown on the phone', () async {
    final at = DateTime(2026, 12, 19, 9);
    await ds.schedule([plan(1, at)]);

    final captured =
        verify(
              () => platform.schedule(
                id: 1,
                title: any(named: 'title'),
                body: any(named: 'body'),
                payload: any(named: 'payload'),
                at: captureAny(named: 'at'),
                exact: any(named: 'exact'),
              ),
            ).captured.single
            as tz.TZDateTime;
    expect(captured.toUtc(), at.toUtc());
  });

  test('wallClockNow is the clock of the phone', () {
    expect(
      ds.wallClockNow().difference(DateTime.now()).inSeconds.abs(),
      lessThan(2),
    );
  });

  test('cancelAll goes to the platform', () async {
    await ds.cancelAll();
    verify(platform.cancelAll).called(1);
  });

  test('permissions reflect the platform', () async {
    when(platform.notificationsEnabled).thenAnswer((_) async => true);
    when(platform.canScheduleExact).thenAnswer((_) async => false);
    expect(
      await ds.permissions(),
      const ReminderPermissions(notifications: true, exactAlarms: false),
    );
  });

  test('requestPermissions asks for both and reports the result', () async {
    when(platform.requestNotifications).thenAnswer((_) async => true);
    when(platform.requestExactAlarms).thenAnswer((_) async => false);
    when(platform.notificationsEnabled).thenAnswer((_) async => true);
    final result = await ds.requestPermissions();
    verify(platform.requestNotifications).called(1);
    expect(result.notifications, isTrue);
  });

  test('a throwing platform never throws out of permissions', () async {
    when(platform.notificationsEnabled).thenThrow(Exception('no'));
    expect(
      await ds.permissions(),
      const ReminderPermissions(notifications: false, exactAlarms: false),
    );
  });

  test('taps and the launch payload are forwarded', () async {
    when(platform.launchPayload).thenAnswer((_) async => 'dLaunch');
    late void Function(String?) onTap;
    when(() => platform.initialize(onTap: any(named: 'onTap'))).thenAnswer((
      inv,
    ) async {
      onTap = inv.namedArguments[#onTap] as void Function(String?);
    });

    final fresh = NotificationDataSource(platform);
    await fresh.init();
    expect(fresh.launchDebtId, 'dLaunch');

    final taps = <String>[];
    final sub = fresh.taps.listen(taps.add);
    onTap('d7');
    onTap(null);
    await pumpEventQueue();
    await sub.cancel();
    expect(taps, ['d7']);
  });
}
