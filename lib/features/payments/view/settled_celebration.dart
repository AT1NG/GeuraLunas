import 'package:flutter/material.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/l10n/l10n.dart';

/// A short, warm "paid off" message. [isOwe] picks the wording for a debt
/// versus a receivable.
Future<void> showSettledCelebration(
  BuildContext context, {
  required bool isOwe,
}) {
  final l10n = context.l10n;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('settled-celebration'),
      icon: Icon(
        Icons.celebration_outlined,
        size: Spacing.xl * 2,
        color: Theme.of(dialogContext).colorScheme.primary,
      ),
      content: Text(
        isOwe ? l10n.detailSettledOwe : l10n.detailSettledLent,
        textAlign: TextAlign.center,
        style: Theme.of(dialogContext).textTheme.titleMedium,
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.celebrationClose),
        ),
      ],
    ),
  );
}
