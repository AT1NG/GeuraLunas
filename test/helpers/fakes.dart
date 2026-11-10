import 'dart:async';

import 'package:geuralunas/domain/auth/app_user.dart';
import 'package:geuralunas/domain/budget/budget_cycle.dart';
import 'package:geuralunas/domain/budget/category.dart';
import 'package:geuralunas/domain/budget/expense.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/domain/reminder/reminder_settings.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:geuralunas/repositories/category_repository.dart';
import 'package:geuralunas/repositories/expense_repository.dart';
import 'package:geuralunas/repositories/onboarding_repository.dart';
import 'package:geuralunas/repositories/reminder_repository.dart';
import 'package:geuralunas/repositories/user_profile_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// In-memory auth repository for app-level tests.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser, bool emitOnListen = true}) {
    _controller = StreamController<AppUser?>.broadcast(
      onListen: () {
        if (emitOnListen) _controller.add(_user);
      },
    );
    _user = initialUser;
  }

  late final StreamController<AppUser?> _controller;
  AppUser? _user;

  void emit(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {}

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async => emit(null);
}

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({this.seen = true});

  bool seen;

  @override
  Future<bool> isSeen() async => seen;

  @override
  Future<void> markSeen() async => seen = true;
}

const testUser = AppUser(
  uid: 'u1',
  email: 'rani@mail.com',
  displayName: 'Rani',
);

class FakeUserProfileRepository implements UserProfileRepository {
  final ensured = <String>[];

  @override
  Future<void> ensureProfile(AppUser user) async => ensured.add(user.uid);

  /// Reminder settings the fake reports; push a new value with [setSettings].
  ReminderSettings _settings = ReminderSettings.defaults;
  final _settingsController = StreamController<ReminderSettings>.broadcast();

  /// Calls made to `saveReminderSettings`.
  final saved = <ReminderSettings>[];

  void setSettings(ReminderSettings settings) {
    _settings = settings;
    _settingsController.add(settings);
  }

  @override
  Stream<ReminderSettings> watchReminderSettings(String uid) async* {
    yield _settings;
    yield* _settingsController.stream;
  }

  @override
  Future<void> saveReminderSettings(
    String uid,
    ReminderSettings settings,
  ) async {
    saved.add(settings);
    setSettings(settings);
  }
}

/// Records what the app asks of the reminder system.
class FakeReminderRepository implements ReminderRepository {
  /// 'reschedule', 'cancel' and 'request' in the order they happened.
  final calls = <String>[];

  /// What `rescheduleAll` reports as planned.
  int planned = 3;

  ReminderPermissions state = const ReminderPermissions(
    notifications: true,
    exactAlarms: true,
  );

  @override
  String? launchDebtId;

  final _taps = StreamController<String>.broadcast();

  void tap(String debtId) => _taps.add(debtId);

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<int> rescheduleAll() async {
    calls.add('reschedule');
    return planned;
  }

  @override
  Future<void> cancelAll() async => calls.add('cancel');

  @override
  Future<ReminderPermissions> permissions() async => state;

  @override
  Future<ReminderPermissions> requestPermissions() async {
    calls.add('request');
    final error = requestError;
    if (error != null) throw error;
    return state;
  }

  /// Makes `requestPermissions` throw.
  Error? requestError;

  @override
  Future<void> openAlarmSettings() async => calls.add('alarm-settings');
}

/// In-memory categories for widget tests; every change updates the stream.
class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository({List<Category>? initial})
    : _categories = initial ?? defaultCategories;

  /// Calls in order, such as `ensureDefaults`, `add:Jajan`, `rename:makan:Ojek`
  /// and `archive:makan:true`.
  final calls = <String>[];

  List<Category> _categories;
  final _controller = StreamController<List<Category>>.broadcast();
  final _errors = StreamController<Object>.broadcast();

  void emit(List<Category> categories) {
    _categories = categories;
    _controller.add(categories);
  }

  void rejectWrite(Object error) => _errors.add(error);

  @override
  Stream<Object> get writeErrors => _errors.stream;

  @override
  Stream<List<Category>> watchCategories() async* {
    yield _categories;
    yield* _controller.stream;
  }

  @override
  Future<void> ensureDefaults() async => calls.add('ensureDefaults');

  @override
  Future<String> add({
    required String name,
    required String icon,
    required String colorHex,
  }) async {
    calls.add('add:$name');
    final id = 'new-${_categories.length}';
    emit([
      ..._categories,
      Category(
        id: id,
        name: name,
        icon: icon,
        colorHex: colorHex,
        sortOrder: _categories.length,
      ),
    ]);
    return id;
  }

  @override
  Future<void> rename(String id, String name) async {
    calls.add('rename:$id:$name');
    emit([
      for (final c in _categories) c.id == id ? c.copyWith(name: name) : c,
    ]);
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    calls.add('archive:$id:$archived');
    emit([
      for (final c in _categories)
        c.id == id ? c.copyWith(archived: archived) : c,
    ]);
  }
}

/// One call to `addExpense`.
class AddedExpense {
  const AddedExpense({
    required this.amount,
    required this.categoryId,
    required this.spentAt,
    this.note,
  });

  final Money amount;
  final String categoryId;
  final DateTime spentAt;
  final String? note;
}

/// In-memory expenses for widget tests.
class FakeExpenseRepository implements ExpenseRepository {
  FakeExpenseRepository({List<Expense>? initial})
    : _expenses = initial ?? const [];

  final added = <AddedExpense>[];
  final deleted = <String>[];

  /// Cycles passed to `watchExpenses`.
  final watched = <BudgetCycle>[];

  List<Expense> _expenses;
  final _controller = StreamController<List<Expense>>.broadcast();
  final _errors = StreamController<Object>.broadcast();

  void emit(List<Expense> expenses) {
    _expenses = expenses;
    _controller.add(expenses);
  }

  void rejectWrite(Object error) => _errors.add(error);

  @override
  Stream<Object> get writeErrors => _errors.stream;

  @override
  Stream<List<Expense>> watchExpenses(BudgetCycle cycle) async* {
    watched.add(cycle);
    yield _expenses;
    yield* _controller.stream;
  }

  @override
  Future<String> addExpense({
    required Money amount,
    required String categoryId,
    required DateTime spentAt,
    String? note,
  }) async {
    added.add(
      AddedExpense(
        amount: amount,
        categoryId: categoryId,
        spentAt: spentAt,
        note: note,
      ),
    );
    return 'e${added.length}';
  }

  @override
  Future<void> deleteExpense(String id) async {
    deleted.add(id);
    emit([
      for (final e in _expenses)
        if (e.id != id) e,
    ]);
  }
}
