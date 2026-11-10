import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/budget/category.dart';
import 'package:geuralunas/features/budget/view/categories_page.dart';
import 'package:geuralunas/repositories/category_repository.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeCategoryRepository repository;

  Future<void> pump(WidgetTester tester) async {
    await pumpApp(
      tester,
      const CategoriesPage(),
      repositories: [
        RepositoryProvider<CategoryRepository>.value(value: repository),
      ],
    );
    await tester.pumpAndSettle();
  }

  setUp(() => repository = FakeCategoryRepository());

  testWidgets('lists the categories and has no way to delete one', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byKey(const Key('categories-page')), findsOneWidget);
    for (final c in defaultCategories) {
      expect(find.byKey(Key('category-row-${c.id}')), findsOneWidget);
    }
    expect(find.text('Diarsipkan'), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
  });

  testWidgets('adding a category sends name, icon and color', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('category-add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-name')), 'Jajan');
    await tester.tap(find.byKey(const Key('category-save')));
    await tester.pumpAndSettle();

    expect(repository.calls, ['ensureDefaults', 'add:Jajan']);
    expect(find.text('Jajan'), findsOneWidget);
    expect(find.byKey(const Key('category-save')), findsNothing);
  });

  testWidgets('a default category can be renamed', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('category-row-makan')));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const Key('category-name')),
    );
    expect(field.controller?.text, 'Makan');

    await tester.enterText(find.byKey(const Key('category-name')), 'Ojek');
    await tester.tap(find.byKey(const Key('category-save')));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('rename:makan:Ojek'));
    expect(find.text('Ojek'), findsOneWidget);
  });

  testWidgets('an empty name keeps the dialog open with a hint', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('category-add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-name')), '   ');
    await tester.tap(find.byKey(const Key('category-save')));
    await tester.pumpAndSettle();

    expect(find.text('Isi nama kategorinya dulu ya.'), findsOneWidget);
    expect(find.byKey(const Key('category-save')), findsOneWidget);
    expect(repository.calls, ['ensureDefaults']);
  });

  testWidgets('a name over 50 characters is explained', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('category-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('category-name')),
      'a' * 51,
    );
    await tester.tap(find.byKey(const Key('category-save')));
    await tester.pumpAndSettle();

    expect(
      find.text('Nama kategori paling panjang 50 huruf.'),
      findsOneWidget,
    );
    expect(repository.calls, ['ensureDefaults']);
  });

  testWidgets('archiving moves a category down, restoring brings it back', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('category-archive-belanja')));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('archive:belanja:true'));
    expect(find.text('Diarsipkan'), findsOneWidget);
    // The row is still there, under the archived heading, and is not deleted.
    expect(find.byKey(const Key('category-row-belanja')), findsOneWidget);
    expect(find.text('Pulihkan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('category-archive-belanja')));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('archive:belanja:false'));
    expect(find.text('Diarsipkan'), findsNothing);
  });

  testWidgets('archived categories start under the archived heading', (
    tester,
  ) async {
    repository = FakeCategoryRepository(
      initial: [
        defaultCategories[0],
        defaultCategories[1].copyWith(archived: true),
      ],
    );
    await pump(tester);

    expect(find.text('Diarsipkan'), findsOneWidget);
    final active = tester.getTopLeft(
      find.byKey(const Key('category-row-makan')),
    );
    final archived = tester.getTopLeft(
      find.byKey(const Key('category-row-transport')),
    );
    expect(archived.dy, greaterThan(active.dy));
  });
}
