import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:geuralunas/app/app.dart';
import 'package:geuralunas/data/auth_data_source.dart';
import 'package:geuralunas/firebase_options.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:geuralunas/repositories/onboarding_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initializes dependencies and returns the root widget.
Future<Widget> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeFormatting();
  final prefs = await SharedPreferences.getInstance();
  return App(
    authRepository: AuthRepositoryImpl(AuthDataSource()),
    onboardingRepository: SharedPrefsOnboardingRepository(prefs),
  );
}
