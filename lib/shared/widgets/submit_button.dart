import 'package:flutter/material.dart';

/// Filled button that shows a spinner while [busy].
class SubmitButton extends StatelessWidget {
  /// Creates a submit button.
  const SubmitButton({
    required this.label,
    required this.busy,
    required this.onPressed,
    super.key,
  });

  /// Button text.
  final String label;

  /// Whether a request is in flight.
  final bool busy;

  /// Tap handler; ignored while [busy].
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}
