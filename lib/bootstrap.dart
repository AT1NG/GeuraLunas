import 'package:flutter/widgets.dart';
import 'package:geuralunas/app/app.dart';

/// Initializes dependencies and returns the root widget.
Future<Widget> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  return const App();
}
