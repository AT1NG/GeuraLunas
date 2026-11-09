import 'package:flutter/material.dart';

/// Root widget of the GeuraLunas app.
class App extends StatelessWidget {
  /// Creates the root widget.
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('GeuraLunas'))),
    );
  }
}
