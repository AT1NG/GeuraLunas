import 'package:flutter/widgets.dart';
import 'package:geuralunas/app/app.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';

/// Initializes dependencies and returns the root widget.
Future<Widget> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFormatting();
  return const App();
}
