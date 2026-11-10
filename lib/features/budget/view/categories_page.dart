import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/domain/budget/category.dart';
import 'package:geuralunas/features/budget/bloc/categories_cubit.dart';
import 'package:geuralunas/features/budget/widgets/category_style.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/category_repository.dart';

/// Lists the categories and lets the user add, rename and archive them.
/// Categories are never deleted, so old expenses keep their name.
class CategoriesPage extends StatelessWidget {
  /// Creates the page.
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = CategoriesCubit(context.read<CategoryRepository>());
        unawaited(cubit.start());
        return cubit;
      },
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('categories-page'),
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      body: BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (context, state) {
          final cubit = context.read<CategoriesCubit>();
          return ListView(
            padding: const EdgeInsets.only(bottom: Spacing.xl),
            children: [
              ListTile(
                key: const Key('category-add'),
                leading: const Icon(Icons.add),
                title: Text(l10n.categoriesAdd),
                onTap: () => unawaited(_showEditor(context, cubit)),
              ),
              for (final c in state.active)
                _CategoryRow(category: c, cubit: cubit),
              if (state.archived.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.lg,
                    Spacing.md,
                    Spacing.sm,
                  ),
                  child: Text(
                    l10n.categoriesArchivedSection,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                for (final c in state.archived)
                  _CategoryRow(category: c, cubit: cubit),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.cubit});

  final Category category;
  final CategoriesCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      key: Key('category-row-${category.id}'),
      leading: Icon(
        categoryIcon(category.icon),
        color: categoryColor(category.colorHex),
      ),
      title: Text(category.name),
      onTap: () => unawaited(_showEditor(context, cubit, existing: category)),
      trailing: TextButton(
        key: Key('category-archive-${category.id}'),
        onPressed: () => unawaited(
          cubit.setArchived(category.id, archived: !category.archived),
        ),
        child: Text(
          category.archived ? l10n.categoriesRestore : l10n.categoriesArchive,
        ),
      ),
    );
  }
}

/// Opens the dialog to add a category, or to rename [existing].
Future<void> _showEditor(
  BuildContext context,
  CategoriesCubit cubit, {
  Category? existing,
}) => showDialog<void>(
  context: context,
  builder: (_) => _CategoryDialog(cubit: cubit, existing: existing),
);

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.cubit, this.existing});

  final CategoriesCubit cubit;
  final Category? existing;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  String _icon = categoryIcons.keys.first;
  String _color = categoryColors.first;
  CategoryNameError? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final existing = widget.existing;
    final error = existing == null
        ? await widget.cubit.add(
            name: _name.text,
            icon: _icon,
            colorHex: _color,
          )
        : await widget.cubit.rename(existing.id, _name.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final adding = widget.existing == null;
    return AlertDialog(
      title: Text(adding ? l10n.categoriesAdd : l10n.categoriesRename),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('category-name'),
              controller: _name,
              autofocus: true,
              maxLength: maxCategoryNameLength + 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.categoriesNameLabel,
                errorText: switch (_error) {
                  CategoryNameError.empty => l10n.categoriesNameEmpty,
                  CategoryNameError.tooLong => l10n.categoriesNameTooLong,
                  null => null,
                },
                border: const OutlineInputBorder(),
              ),
            ),
            if (adding) ...[
              const SizedBox(height: Spacing.md),
              Text(l10n.categoriesIcon),
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  for (final entry in categoryIcons.entries)
                    ChoiceChip(
                      key: Key('category-icon-${entry.key}'),
                      label: Icon(entry.value, size: 18),
                      selected: _icon == entry.key,
                      onSelected: (_) => setState(() => _icon = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Text(l10n.categoriesColor),
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  for (final hex in categoryColors)
                    InkResponse(
                      key: Key('category-color-$hex'),
                      onTap: () => setState(() => _color = hex),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: categoryColor(hex),
                        child: _color == hex
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('category-save'),
          onPressed: _save,
          child: Text(l10n.categoriesSave),
        ),
      ],
    );
  }
}
