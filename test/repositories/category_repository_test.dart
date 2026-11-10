import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/data/budget_data_source.dart';
import 'package:geuralunas/data/debt_data_source.dart';
import 'package:geuralunas/domain/budget/category.dart';
import 'package:geuralunas/repositories/category_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockBudgetDataSource extends Mock implements BudgetDataSource {}

Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late FakeFirebaseFirestore firestore;
  late CategoryRepositoryImpl repo;

  CategoryRepositoryImpl makeRepo() => CategoryRepositoryImpl(
    BudgetDataSource(firestore),
    currentUid: () => 'u1',
  );

  Future<int> count() async =>
      (await firestore.collection('users/u1/categories').get()).docs.length;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = makeRepo();
  });

  group('ensureDefaults', () {
    test('seeds the seven default categories into an empty account', () async {
      await repo.ensureDefaults();
      await pump();

      final list = await repo.watchCategories().first;
      expect(list.map((c) => c.id), defaultCategories.map((c) => c.id));
      expect(list.every((c) => c.isDefault), isTrue);
    });

    test('a second call writes nothing', () async {
      await repo.ensureDefaults();
      await pump();
      await repo.rename('makan', 'Jajan');
      await pump();

      await repo.ensureDefaults();
      await pump();

      final list = await repo.watchCategories().first;
      expect(list.firstWhere((c) => c.id == 'makan').name, 'Jajan');
    });

    test('two calls at once do not duplicate anything', () async {
      await Future.wait([repo.ensureDefaults(), repo.ensureDefaults()]);
      await pump();
      expect(await count(), 7);
    });

    test('a new repository does not overwrite a renamed default', () async {
      await repo.ensureDefaults();
      await pump();
      await repo.rename('makan', 'Jajan');
      await pump();

      await makeRepo().ensureDefaults();
      await pump();

      final list = await repo.watchCategories().first;
      expect(list.firstWhere((c) => c.id == 'makan').name, 'Jajan');
      expect(list, hasLength(7));
    });
  });

  group('changes', () {
    setUp(() async {
      await repo.ensureDefaults();
      await pump();
    });

    test('add puts the category last and not as a default', () async {
      final id = await repo.add(
        name: 'Jajan',
        icon: 'cake',
        colorHex: '#112233',
      );
      await pump();

      final list = await repo.watchCategories().first;
      final added = list.firstWhere((c) => c.id == id);
      expect(added.name, 'Jajan');
      expect(added.sortOrder, 7);
      expect(added.isDefault, isFalse);
      expect(list.last.id, id);
    });

    test('rename changes only the name', () async {
      await repo.rename('transport', 'Ojek');
      await pump();

      final c = (await repo.watchCategories().first).firstWhere(
        (c) => c.id == 'transport',
      );
      expect(c.name, 'Ojek');
      expect(c.icon, 'directions_bus');
      expect(c.archived, isFalse);
    });

    test('archiving keeps the document and can be undone', () async {
      await repo.setArchived('belanja', archived: true);
      await pump();
      var list = await repo.watchCategories().first;
      expect(list, hasLength(7));
      expect(list.firstWhere((c) => c.id == 'belanja').archived, isTrue);

      await repo.setArchived('belanja', archived: false);
      await pump();
      list = await repo.watchCategories().first;
      expect(list.firstWhere((c) => c.id == 'belanja').archived, isFalse);
    });

    test('watchCategories is ordered by sortOrder', () async {
      await repo.add(name: 'Z', icon: 'cake', colorHex: '#000000');
      await pump();
      final orders = (await repo.watchCategories().first).map(
        (c) => c.sortOrder,
      );
      expect(orders.toList(), orders.toList()..sort());
    });
  });

  test('a rejected write is reported on writeErrors', () async {
    final ds = _MockBudgetDataSource();
    when(() => ds.getCategories(any())).thenAnswer((_) async => const []);
    when(() => ds.write(any())).thenAnswer(
      (_) => Future<void>.error(Exception('permission-denied')),
    );
    final failing = CategoryRepositoryImpl(ds, currentUid: () => 'u1');

    final error = failing.writeErrors.first;
    await failing.ensureDefaults();

    expect(await error, isA<Exception>());
    verify(() => ds.write(any())).called(1);
  });

  test('ensureDefaults writes SetOps to the fixed paths', () async {
    final ds = _MockBudgetDataSource();
    when(() => ds.getCategories(any())).thenAnswer((_) async => const []);
    when(() => ds.write(any())).thenAnswer((_) async {});
    await CategoryRepositoryImpl(ds, currentUid: () => 'u1').ensureDefaults();

    final ops =
        verify(() => ds.write(captureAny())).captured.single as List<WriteOp>;
    expect(ops.every((o) => o is SetOp), isTrue);
    expect(ops.first.path, 'users/u1/categories/makan');
    expect(ops, hasLength(7));
  });
}
