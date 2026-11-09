import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('id')];

  /// No description provided for @appName.
  ///
  /// In id, this message translates to:
  /// **'GeuraLunas'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get navHome;

  /// No description provided for @navDebts.
  ///
  /// In id, this message translates to:
  /// **'Hutang'**
  String get navDebts;

  /// No description provided for @navBudget.
  ///
  /// In id, this message translates to:
  /// **'Budget'**
  String get navBudget;

  /// No description provided for @navMore.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get navMore;

  /// No description provided for @navAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get navAdd;

  /// No description provided for @addMenuExpense.
  ///
  /// In id, this message translates to:
  /// **'Catat pengeluaran'**
  String get addMenuExpense;

  /// No description provided for @addMenuPayment.
  ///
  /// In id, this message translates to:
  /// **'Catat pembayaran'**
  String get addMenuPayment;

  /// No description provided for @addMenuDebt.
  ///
  /// In id, this message translates to:
  /// **'Tambah hutang'**
  String get addMenuDebt;

  /// No description provided for @onboardingTitle1.
  ///
  /// In id, this message translates to:
  /// **'Catat semua hutang di satu tempat'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In id, this message translates to:
  /// **'Pinjol, cicilan, atau pinjaman dari teman. Semua terlihat jelas, tanpa perlu diingat-ingat.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In id, this message translates to:
  /// **'Jangan sampai telat bayar'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In id, this message translates to:
  /// **'Kami ingatkan sebelum jatuh tempo, supaya kamu tenang dan terhindar dari denda.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In id, this message translates to:
  /// **'Jatah jajan harian yang aman'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In id, this message translates to:
  /// **'Kami hitung sisa uangmu setelah cicilan, jadi kamu tahu berapa yang aman dipakai hari ini.'**
  String get onboardingBody3;

  /// No description provided for @onboardingSkip.
  ///
  /// In id, this message translates to:
  /// **'Lewati'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In id, this message translates to:
  /// **'Mulai'**
  String get onboardingStart;

  /// No description provided for @authEmail.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In id, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authName.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get authName;

  /// No description provided for @authOr.
  ///
  /// In id, this message translates to:
  /// **'atau'**
  String get authOr;

  /// No description provided for @authShowPassword.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan password'**
  String get authHidePassword;

  /// No description provided for @validationRequired.
  ///
  /// In id, this message translates to:
  /// **'Wajib diisi'**
  String get validationRequired;

  /// No description provided for @validationInvalidEmail.
  ///
  /// In id, this message translates to:
  /// **'Format email belum benar'**
  String get validationInvalidEmail;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In id, this message translates to:
  /// **'Minimal 8 karakter'**
  String get validationPasswordTooShort;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In id, this message translates to:
  /// **'Email atau password belum cocok. Coba cek lagi ya.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In id, this message translates to:
  /// **'Format email belum benar.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In id, this message translates to:
  /// **'Email ini sudah terdaftar. Coba masuk, atau pakai email lain.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In id, this message translates to:
  /// **'Password terlalu mudah ditebak. Pakai minimal 8 karakter.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In id, this message translates to:
  /// **'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNetwork.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada koneksi internet. Coba lagi setelah tersambung.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorDifferentCredential.
  ///
  /// In id, this message translates to:
  /// **'Email ini sudah dipakai dengan cara masuk lain. Coba masuk dengan email dan password.'**
  String get authErrorDifferentCredential;

  /// No description provided for @authErrorUnknown.
  ///
  /// In id, this message translates to:
  /// **'Ada yang tidak beres. Coba lagi sebentar lagi.'**
  String get authErrorUnknown;

  /// No description provided for @loginTitle.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Senang melihatmu lagi. Yuk lanjut beresin hutang.'**
  String get loginSubtitle;

  /// No description provided for @loginSubmit.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get loginSubmit;

  /// No description provided for @loginGoogle.
  ///
  /// In id, this message translates to:
  /// **'Masuk dengan Google'**
  String get loginGoogle;

  /// No description provided for @loginForgot.
  ///
  /// In id, this message translates to:
  /// **'Lupa password?'**
  String get loginForgot;

  /// No description provided for @loginNoAccount.
  ///
  /// In id, this message translates to:
  /// **'Belum punya akun?'**
  String get loginNoAccount;

  /// No description provided for @loginToRegister.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get loginToRegister;

  /// No description provided for @registerTitle.
  ///
  /// In id, this message translates to:
  /// **'Buat akun'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Mulai catat hutangmu dengan tenang.'**
  String get registerSubtitle;

  /// No description provided for @registerSubmit.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get registerSubmit;

  /// No description provided for @registerHaveAccount.
  ///
  /// In id, this message translates to:
  /// **'Sudah punya akun?'**
  String get registerHaveAccount;

  /// No description provided for @registerToLogin.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get registerToLogin;

  /// No description provided for @forgotTitle.
  ///
  /// In id, this message translates to:
  /// **'Lupa password'**
  String get forgotTitle;

  /// No description provided for @forgotBody.
  ///
  /// In id, this message translates to:
  /// **'Masukkan email akunmu. Kami kirim tautan untuk membuat password baru.'**
  String get forgotBody;

  /// No description provided for @forgotSubmit.
  ///
  /// In id, this message translates to:
  /// **'Kirim tautan'**
  String get forgotSubmit;

  /// No description provided for @forgotSent.
  ///
  /// In id, this message translates to:
  /// **'Kalau email itu terdaftar, tautan sudah kami kirim. Cek kotak masuk atau folder spam.'**
  String get forgotSent;

  /// No description provided for @commonCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get commonCancel;

  /// No description provided for @commonComingSoon.
  ///
  /// In id, this message translates to:
  /// **'Segera hadir'**
  String get commonComingSoon;

  /// No description provided for @moreSimulation.
  ///
  /// In id, this message translates to:
  /// **'Simulasi pelunasan'**
  String get moreSimulation;

  /// No description provided for @settingsTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settingsTitle;

  /// No description provided for @settingsNoName.
  ///
  /// In id, this message translates to:
  /// **'Tanpa nama'**
  String get settingsNoName;

  /// No description provided for @settingsSignOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari akun?'**
  String get settingsSignOutConfirmTitle;

  /// No description provided for @settingsSignOutConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'Datamu tetap aman dan akan muncul lagi saat kamu masuk.'**
  String get settingsSignOutConfirmBody;

  /// No description provided for @debtsTabOwe.
  ///
  /// In id, this message translates to:
  /// **'Aku berutang'**
  String get debtsTabOwe;

  /// No description provided for @debtsTabLent.
  ///
  /// In id, this message translates to:
  /// **'Piutang'**
  String get debtsTabLent;

  /// No description provided for @debtsTotalOwe.
  ///
  /// In id, this message translates to:
  /// **'Total yang harus kamu bayar'**
  String get debtsTotalOwe;

  /// No description provided for @debtsTotalLent.
  ///
  /// In id, this message translates to:
  /// **'Total yang akan kamu terima'**
  String get debtsTotalLent;

  /// No description provided for @debtsFilterActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get debtsFilterActive;

  /// No description provided for @debtsFilterSettled.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get debtsFilterSettled;

  /// No description provided for @debtsEmptyOwe.
  ///
  /// In id, this message translates to:
  /// **'Belum ada hutang yang tercatat. Mulai dari yang pertama, pelan-pelan saja.'**
  String get debtsEmptyOwe;

  /// No description provided for @debtsEmptyLent.
  ///
  /// In id, this message translates to:
  /// **'Belum ada piutang yang tercatat.'**
  String get debtsEmptyLent;

  /// No description provided for @debtsEmptySettled.
  ///
  /// In id, this message translates to:
  /// **'Belum ada yang lunas. Satu per satu pasti sampai.'**
  String get debtsEmptySettled;

  /// No description provided for @debtsEmptyAction.
  ///
  /// In id, this message translates to:
  /// **'Tambah hutang pertamamu'**
  String get debtsEmptyAction;

  /// No description provided for @debtsLoadError.
  ///
  /// In id, this message translates to:
  /// **'Datamu belum bisa dimuat. Coba lagi sebentar lagi.'**
  String get debtsLoadError;

  /// No description provided for @statusOverdue.
  ///
  /// In id, this message translates to:
  /// **'Terlambat'**
  String get statusOverdue;

  /// No description provided for @statusDueSoon.
  ///
  /// In id, this message translates to:
  /// **'Segera jatuh tempo'**
  String get statusDueSoon;

  /// No description provided for @statusSettled.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get statusSettled;

  /// No description provided for @statusActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get statusActive;

  /// No description provided for @debtCardRemaining.
  ///
  /// In id, this message translates to:
  /// **'Sisa {amount}'**
  String debtCardRemaining(String amount);

  /// No description provided for @debtCardDue.
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo {date}'**
  String debtCardDue(String date);

  /// No description provided for @debtCardNoDue.
  ///
  /// In id, this message translates to:
  /// **'Tanpa jatuh tempo'**
  String get debtCardNoDue;

  /// No description provided for @debtCardSemantics.
  ///
  /// In id, this message translates to:
  /// **'{name}, sisa {amount}, {due}'**
  String debtCardSemantics(String name, String amount, String due);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
