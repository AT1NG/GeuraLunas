import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/l10n/l10n.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _slideCount = 3;

  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _slideCount - 1;

  void _next() {
    if (_isLast) {
      widget.onFinished();
      return;
    }
    unawaited(
      _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slides = [
      (
        Icons.account_balance_wallet_outlined,
        l10n.onboardingTitle1,
        l10n.onboardingBody1,
      ),
      (
        Icons.notifications_active_outlined,
        l10n.onboardingTitle2,
        l10n.onboardingBody2,
      ),
      (Icons.savings_outlined, l10n.onboardingTitle3, l10n.onboardingBody3),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onFinished,
                child: Text(l10n.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final (icon, title, body) in slides)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 96,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: Spacing.lg),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: Spacing.md),
                          Text(
                            body,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slideCount; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.all(Spacing.xs),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _isLast ? l10n.onboardingStart : l10n.onboardingNext,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
