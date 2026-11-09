import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/debts/collection_message.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

/// Hands [text] to the system share sheet.
typedef ShareText = Future<void> Function(String text);

Future<void> _systemShare(String text) =>
    SharePlus.instance.share(ShareParams(text: text));

/// Opens a sheet with a polite, editable collection message for a receivable.
///
/// Nothing is stored; the text only leaves the app through [share].
Future<void> showCollectionSheet(
  BuildContext context, {
  required String name,
  required Money remaining,
  DateTime? dueDate,
  ShareText share = _systemShare,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CollectionSheet(
      name: name,
      remaining: remaining,
      dueDate: dueDate,
      share: share,
    ),
  );
}

class _CollectionSheet extends StatefulWidget {
  const _CollectionSheet({
    required this.name,
    required this.remaining,
    required this.dueDate,
    required this.share,
  });

  final String name;
  final Money remaining;
  final DateTime? dueDate;
  final ShareText share;

  @override
  State<_CollectionSheet> createState() => _CollectionSheetState();
}

class _CollectionSheetState extends State<_CollectionSheet> {
  TextEditingController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= TextEditingController(
      text: buildCollectionMessage(
        l10n: context.l10n,
        name: widget.name,
        remaining: widget.remaining,
        dueDate: widget.dueDate,
        now: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    final copied = context.l10n.collectionCopied;
    await Clipboard.setData(ClipboardData(text: _controller!.text));
    messenger.showSnackBar(SnackBar(content: Text(copied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Spacing.md,
          0,
          Spacing.md,
          Spacing.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.collectionSheetTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: Spacing.xs),
            Text(l10n.collectionSheetHint, style: theme.textTheme.bodyMedium),
            const SizedBox(height: Spacing.md),
            TextField(
              key: const Key('collection-message'),
              controller: _controller,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.collectionMessageLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                FilledButton.icon(
                  key: const Key('collection-share'),
                  onPressed: () async {
                    await widget.share(_controller!.text);
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: Text(l10n.collectionShare),
                ),
                OutlinedButton.icon(
                  key: const Key('collection-copy'),
                  onPressed: _copy,
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(l10n.collectionCopy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
