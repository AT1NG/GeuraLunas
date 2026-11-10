import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/budget/category.dart';
import 'package:geuralunas/features/budget/bloc/categories_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeCategoryRepository repository;

  setUp(() => repository = FakeCategoryRepository());

  test('start seeds the defaults before showing the list', () async {
    final cubit = CategoriesCubit(repository);
    await cubit.start();
    await Future<void>.delayed(Duration.zero);

    expect(repository.calls.first, 'ensureDefaults');
    expect(cubit.state.status, CategoriesStatus.loaded);
    expect(cubit.state.categories, defaultCategories);
    await cubit.close();
  });

  test('active leaves out archived categories and keeps the order', () async {
    final cubit = CategoriesCubit(repository);
    await cubit.start();
    repository.emit([
      defaultCategories[2],
      defaultCategories[0].copyWith(archived: true),
      defaultCategories[1],
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.active.map((c) => c.id), ['belanja', 'transport']);
    expect(cubit.state.archived.map((c) => c.id), ['makan']);
    await cubit.close();
  });

  test('a failure to seed still shows what the stream has', () async {
    final failing = _FailingSeed();
    final cubit = CategoriesCubit(failing);
    await cubit.start();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, CategoriesStatus.loaded);
    await cubit.close();
  });

  blocTest<CategoriesCubit, CategoriesState>(
    'add, rename and archive go to the repository',
    build: () => CategoriesCubit(repository),
    act: (cubit) async {
      await cubit.add(name: 'Jajan', icon: 'cake', colorHex: '#112233');
      await cubit.rename('makan', 'Ojek');
      await cubit.setArchived('belanja', archived: true);
    },
    verify: (_) {
      expect(repository.calls, [
        'add:Jajan',
        'rename:makan:Ojek',
        'archive:belanja:true',
      ]);
    },
  );
}

class _FailingSeed extends FakeCategoryRepository {
  @override
  Future<void> ensureDefaults() async => throw Exception('offline');
}
