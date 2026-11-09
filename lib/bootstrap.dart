import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:geuralunas/app/app.dart';
import 'package:geuralunas/data/auth_data_source.dart';
import 'package:geuralunas/data/debt_data_source.dart';
import 'package:geuralunas/data/notification_data_source.dart';
import 'package:geuralunas/data/user_profile_data_source.dart';
import 'package:geuralunas/firebase_options.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/repositories/onboarding_repository.dart';
import 'package:geuralunas/repositories/reminder_repository.dart';
import 'package:geuralunas/repositories/user_profile_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initializes dependencies and returns the root widget.
Future<Widget> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeFormatting();
  final prefs = await SharedPreferences.getInstance();
  final debts = DebtRepositoryImpl(
    DebtDataSource(FirebaseFirestore.instance),
    currentUid: () => FirebaseAuth.instance.currentUser!.uid,
  );
  final profiles = UserProfileRepositoryImpl(
    UserProfileDataSource(FirebaseFirestore.instance),
  );
  final notifications = NotificationDataSource(PluginNotificationsPlatform());
  await notifications.init();
  return App(
    authRepository: AuthRepositoryImpl(AuthDataSource()),
    onboardingRepository: SharedPrefsOnboardingRepository(prefs),
    debtRepository: debts,
    userProfileRepository: profiles,
    reminderRepository: ReminderRepositoryImpl(
      debts: debts,
      profiles: profiles,
      notifications: notifications,
      currentUid: () => FirebaseAuth.instance.currentUser?.uid,
    ),
    prefs: prefs,
  );
}
