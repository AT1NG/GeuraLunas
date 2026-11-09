import 'package:flutter/material.dart';

/// Shown while auth and onboarding state are loading.
class SplashPage extends StatelessWidget {
  /// Creates the splash page.
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('splash-page'),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
