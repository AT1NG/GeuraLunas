import 'dart:async';

import 'package:geuralunas/repositories/reminder_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _askedKey = 'reminderPermissionAsked';

/// Decides when reminders are rescheduled.
///
/// Reschedules after sign-in, when debt data changes and when the app returns
/// to the foreground, cancels everything on sign-out, asks for notification
/// permission once the first reminder exists, and opens the debt of a tapped
/// notification.
class ReminderCoordinator {
  ReminderCoordinator({
    required ReminderRepository reminders,
    required Stream<bool> signedIn,
    required Stream<Object?> Function() debtChanges,
    required SharedPreferences prefs,
    required void Function(String debtId) openDebt,
    Duration debounce = const Duration(milliseconds: 500),
  }) : _reminders = reminders,
       _signedInStream = signedIn,
       _debtChanges = debtChanges,
       _prefs = prefs,
       _openDebt = openDebt,
       _debounce = debounce;

  final ReminderRepository _reminders;
  final Stream<bool> _signedInStream;
  final Stream<Object?> Function() _debtChanges;
  final SharedPreferences _prefs;
  final void Function(String debtId) _openDebt;
  final Duration _debounce;

  StreamSubscription<bool>? _authSub;
  StreamSubscription<Object?>? _debtSub;
  StreamSubscription<String>? _tapSub;
  Timer? _timer;
  bool _signedIn = false;
  bool? _lastSignedIn;
  String? _pendingLaunch;
  bool _promptWanted = false;

  void start() {
    _pendingLaunch = _reminders.launchDebtId;
    _authSub = _signedInStream.listen(_onAuth);
    _tapSub = _reminders.taps.listen((id) {
      if (_signedIn) _openDebt(id);
    });
  }

  void _onAuth(bool signedIn) {
    if (signedIn == _lastSignedIn) return;
    _lastSignedIn = signedIn;
    _signedIn = signedIn;
    if (signedIn) {
      // The first snapshot is the debts that already exist; only later ones
      // are a change the user made, and only those may ask for permission.
      var first = true;
      _debtSub = _debtChanges().listen(
        (_) {
          if (!first) _promptWanted = true;
          first = false;
          _schedule();
        },
        // A failing stream must not crash the app; the next event or the next
        // resume reschedules.
        onError: (Object _) {},
      );
      _schedule();
      final launch = _pendingLaunch;
      if (launch != null) {
        _pendingLaunch = null;
        _openDebt(launch);
      }
    } else {
      _timer?.cancel();
      unawaited(_debtSub?.cancel());
      _debtSub = null;
      unawaited(_reminders.cancelAll());
    }
  }

  /// The app came back to the foreground.
  void onResumed() {
    if (_signedIn) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(_debounce, () => unawaited(_run()));
  }

  Future<void> _run() async {
    final wantsPrompt = _promptWanted;
    _promptWanted = false;
    final planned = await _reminders.rescheduleAll();
    if (planned > 0 && wantsPrompt && !(_prefs.getBool(_askedKey) ?? false)) {
      try {
        await _reminders.requestPermissions();
        // Only after the request really ran, so a failure asks again later.
        await _prefs.setBool(_askedKey, true);
      } on Object {
        _promptWanted = true;
      }
    }
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _authSub?.cancel();
    await _debtSub?.cancel();
    await _tapSub?.cancel();
  }
}
