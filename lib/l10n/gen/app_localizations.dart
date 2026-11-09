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

  /// No description provided for @debtFormNewTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah hutang'**
  String get debtFormNewTitle;

  /// No description provided for @debtFormEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah hutang'**
  String get debtFormEditTitle;

  /// No description provided for @formDirectionOwe.
  ///
  /// In id, this message translates to:
  /// **'Aku berutang'**
  String get formDirectionOwe;

  /// No description provided for @formDirectionLent.
  ///
  /// In id, this message translates to:
  /// **'Dia berutang ke aku'**
  String get formDirectionLent;

  /// No description provided for @formKindPinjol.
  ///
  /// In id, this message translates to:
  /// **'Pinjol'**
  String get formKindPinjol;

  /// No description provided for @formKindInstallment.
  ///
  /// In id, this message translates to:
  /// **'Cicilan'**
  String get formKindInstallment;

  /// No description provided for @formKindPersonal.
  ///
  /// In id, this message translates to:
  /// **'Teman'**
  String get formKindPersonal;

  /// No description provided for @formName.
  ///
  /// In id, this message translates to:
  /// **'Nama pihak (platform, toko, atau teman)'**
  String get formName;

  /// No description provided for @formPrincipal.
  ///
  /// In id, this message translates to:
  /// **'Pokok pinjaman'**
  String get formPrincipal;

  /// No description provided for @formInterestTitle.
  ///
  /// In id, this message translates to:
  /// **'Bunga'**
  String get formInterestTitle;

  /// No description provided for @formInterestNone.
  ///
  /// In id, this message translates to:
  /// **'Tanpa bunga'**
  String get formInterestNone;

  /// No description provided for @formInterestFlatMonthly.
  ///
  /// In id, this message translates to:
  /// **'Flat per bulan'**
  String get formInterestFlatMonthly;

  /// No description provided for @formInterestFlatDaily.
  ///
  /// In id, this message translates to:
  /// **'Flat per hari'**
  String get formInterestFlatDaily;

  /// No description provided for @formInterestReducing.
  ///
  /// In id, this message translates to:
  /// **'Anuitas (menurun)'**
  String get formInterestReducing;

  /// No description provided for @formRate.
  ///
  /// In id, this message translates to:
  /// **'Bunga (% per periode)'**
  String get formRate;

  /// No description provided for @formAdminFee.
  ///
  /// In id, this message translates to:
  /// **'Biaya admin (opsional)'**
  String get formAdminFee;

  /// No description provided for @formTenor.
  ///
  /// In id, this message translates to:
  /// **'Jumlah cicilan'**
  String get formTenor;

  /// No description provided for @formTenorDays.
  ///
  /// In id, this message translates to:
  /// **'Tenor (hari)'**
  String get formTenorDays;

  /// No description provided for @formFrequencyTitle.
  ///
  /// In id, this message translates to:
  /// **'Cicilan setiap'**
  String get formFrequencyTitle;

  /// No description provided for @formFrequencyMonthly.
  ///
  /// In id, this message translates to:
  /// **'Bulan'**
  String get formFrequencyMonthly;

  /// No description provided for @formFrequencyWeekly.
  ///
  /// In id, this message translates to:
  /// **'Minggu'**
  String get formFrequencyWeekly;

  /// No description provided for @formStartDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal mulai'**
  String get formStartDate;

  /// No description provided for @formFirstDue.
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo pertama'**
  String get formFirstDue;

  /// No description provided for @formFirstDueAuto.
  ///
  /// In id, this message translates to:
  /// **'Otomatis'**
  String get formFirstDueAuto;

  /// No description provided for @formFirstDueClear.
  ///
  /// In id, this message translates to:
  /// **'Hapus tanggal'**
  String get formFirstDueClear;

  /// No description provided for @formNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan (opsional)'**
  String get formNote;

  /// No description provided for @formPreviewTitle.
  ///
  /// In id, this message translates to:
  /// **'Pratinjau'**
  String get formPreviewTitle;

  /// No description provided for @formPreviewTotal.
  ///
  /// In id, this message translates to:
  /// **'Total yang harus dibayar: {amount}'**
  String formPreviewTotal(String amount);

  /// No description provided for @formPreviewRow.
  ///
  /// In id, this message translates to:
  /// **'Cicilan {n}'**
  String formPreviewRow(int n);

  /// No description provided for @formPreviewMore.
  ///
  /// In id, this message translates to:
  /// **'dan {count} cicilan lainnya'**
  String formPreviewMore(int count);

  /// No description provided for @formSubmitNew.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get formSubmitNew;

  /// No description provided for @formSubmitEdit.
  ///
  /// In id, this message translates to:
  /// **'Simpan perubahan'**
  String get formSubmitEdit;

  /// No description provided for @formErrorAmount.
  ///
  /// In id, this message translates to:
  /// **'Isi nominal yang benar, lebih dari Rp0.'**
  String get formErrorAmount;

  /// No description provided for @formErrorNumber.
  ///
  /// In id, this message translates to:
  /// **'Isi angka yang benar.'**
  String get formErrorNumber;

  /// No description provided for @formErrorBelowPaid.
  ///
  /// In id, this message translates to:
  /// **'Total tidak boleh kurang dari yang sudah dibayar ({amount}).'**
  String formErrorBelowPaid(String amount);

  /// No description provided for @formSaveFailed.
  ///
  /// In id, this message translates to:
  /// **'Belum bisa menyimpan. Coba lagi sebentar lagi.'**
  String get formSaveFailed;

  /// No description provided for @formPaidWarning.
  ///
  /// In id, this message translates to:
  /// **'Hutang ini sudah punya pembayaran. Kalau nominal, bunga, atau tenor diubah, jadwal dihitung ulang dan pembayaran yang ada diterapkan lagi ke cicilan.'**
  String get formPaidWarning;

  /// No description provided for @formNotFound.
  ///
  /// In id, this message translates to:
  /// **'Hutang ini tidak ditemukan. Mungkin sudah dihapus.'**
  String get formNotFound;

  /// No description provided for @detailKindPinjol.
  ///
  /// In id, this message translates to:
  /// **'Pinjol'**
  String get detailKindPinjol;

  /// No description provided for @detailKindInstallment.
  ///
  /// In id, this message translates to:
  /// **'Cicilan'**
  String get detailKindInstallment;

  /// No description provided for @detailKindPersonal.
  ///
  /// In id, this message translates to:
  /// **'Pinjaman teman'**
  String get detailKindPersonal;

  /// No description provided for @detailDirectionOwe.
  ///
  /// In id, this message translates to:
  /// **'Aku berutang'**
  String get detailDirectionOwe;

  /// No description provided for @detailDirectionLent.
  ///
  /// In id, this message translates to:
  /// **'Dia berutang ke aku'**
  String get detailDirectionLent;

  /// No description provided for @detailKindDirection.
  ///
  /// In id, this message translates to:
  /// **'{kind} · {direction}'**
  String detailKindDirection(String kind, String direction);

  /// No description provided for @detailRemainingOwe.
  ///
  /// In id, this message translates to:
  /// **'Sisa yang harus dibayar'**
  String get detailRemainingOwe;

  /// No description provided for @detailRemainingLent.
  ///
  /// In id, this message translates to:
  /// **'Sisa yang akan diterima'**
  String get detailRemainingLent;

  /// No description provided for @detailPaidOf.
  ///
  /// In id, this message translates to:
  /// **'{paid} dari {total}'**
  String detailPaidOf(String paid, String total);

  /// No description provided for @detailProgressSemantics.
  ///
  /// In id, this message translates to:
  /// **'Sudah dibayar {paid} dari {total}'**
  String detailProgressSemantics(String paid, String total);

  /// No description provided for @detailPayOwe.
  ///
  /// In id, this message translates to:
  /// **'Bayar'**
  String get detailPayOwe;

  /// No description provided for @detailPayLent.
  ///
  /// In id, this message translates to:
  /// **'Catat penerimaan'**
  String get detailPayLent;

  /// No description provided for @detailSettledOwe.
  ///
  /// In id, this message translates to:
  /// **'Lunas! Satu beban berkurang.'**
  String get detailSettledOwe;

  /// No description provided for @detailSettledLent.
  ///
  /// In id, this message translates to:
  /// **'Lunas! Semuanya sudah kembali.'**
  String get detailSettledLent;

  /// No description provided for @detailScheduleTitle.
  ///
  /// In id, this message translates to:
  /// **'Jadwal cicilan'**
  String get detailScheduleTitle;

  /// No description provided for @detailNoSchedule.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada jadwal cicilan.'**
  String get detailNoSchedule;

  /// No description provided for @installmentTitle.
  ///
  /// In id, this message translates to:
  /// **'Cicilan {n}'**
  String installmentTitle(int n);

  /// No description provided for @installmentDue.
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo {date}'**
  String installmentDue(String date);

  /// No description provided for @installmentPaid.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get installmentPaid;

  /// No description provided for @installmentPartial.
  ///
  /// In id, this message translates to:
  /// **'Sebagian ({paid} dari {total})'**
  String installmentPartial(String paid, String total);

  /// No description provided for @installmentPending.
  ///
  /// In id, this message translates to:
  /// **'Belum dibayar'**
  String get installmentPending;

  /// No description provided for @detailPaymentsOwe.
  ///
  /// In id, this message translates to:
  /// **'Riwayat pembayaran'**
  String get detailPaymentsOwe;

  /// No description provided for @detailPaymentsLent.
  ///
  /// In id, this message translates to:
  /// **'Riwayat penerimaan'**
  String get detailPaymentsLent;

  /// No description provided for @detailNoPayments.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pembayaran.'**
  String get detailNoPayments;

  /// No description provided for @detailEdit.
  ///
  /// In id, this message translates to:
  /// **'Ubah'**
  String get detailEdit;

  /// No description provided for @detailMenu.
  ///
  /// In id, this message translates to:
  /// **'Menu'**
  String get detailMenu;

  /// No description provided for @payTitleOwe.
  ///
  /// In id, this message translates to:
  /// **'Catat pembayaran'**
  String get payTitleOwe;

  /// No description provided for @payTitleLent.
  ///
  /// In id, this message translates to:
  /// **'Catat penerimaan'**
  String get payTitleLent;

  /// No description provided for @payDirectionOwe.
  ///
  /// In id, this message translates to:
  /// **'Aku bayar'**
  String get payDirectionOwe;

  /// No description provided for @payDirectionLent.
  ///
  /// In id, this message translates to:
  /// **'Diterima dari {name}'**
  String payDirectionLent(String name);

  /// No description provided for @payRemainingNow.
  ///
  /// In id, this message translates to:
  /// **'Sisa sekarang {amount}'**
  String payRemainingNow(String amount);

  /// No description provided for @payAmount.
  ///
  /// In id, this message translates to:
  /// **'Nominal'**
  String get payAmount;

  /// No description provided for @payDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get payDate;

  /// No description provided for @payInstallment.
  ///
  /// In id, this message translates to:
  /// **'Untuk cicilan'**
  String get payInstallment;

  /// No description provided for @payInstallmentAuto.
  ///
  /// In id, this message translates to:
  /// **'Otomatis (cicilan terdekat)'**
  String get payInstallmentAuto;

  /// No description provided for @payInstallmentOption.
  ///
  /// In id, this message translates to:
  /// **'Cicilan {n} · sisa {amount}'**
  String payInstallmentOption(int n, String amount);

  /// No description provided for @payNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan (opsional)'**
  String get payNote;

  /// No description provided for @paySubmit.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get paySubmit;

  /// No description provided for @payErrorAmount.
  ///
  /// In id, this message translates to:
  /// **'Isi nominal pembayaran.'**
  String get payErrorAmount;

  /// No description provided for @payErrorExceeds.
  ///
  /// In id, this message translates to:
  /// **'Nominal melebihi sisa hutang ({amount}). Isi paling banyak sebesar sisa.'**
  String payErrorExceeds(String amount);

  /// No description provided for @payErrorFuture.
  ///
  /// In id, this message translates to:
  /// **'Tanggal tidak boleh di masa depan.'**
  String get payErrorFuture;

  /// No description provided for @paySaved.
  ///
  /// In id, this message translates to:
  /// **'Tercatat. Sisa sekarang {amount}.'**
  String paySaved(String amount);

  /// No description provided for @payFailed.
  ///
  /// In id, this message translates to:
  /// **'Belum bisa menyimpan pembayaran. Coba lagi sebentar lagi.'**
  String get payFailed;

  /// No description provided for @payUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Hutang ini tidak bisa dibayar lagi. Mungkin sudah lunas atau sudah dihapus.'**
  String get payUnavailable;

  /// No description provided for @celebrationClose.
  ///
  /// In id, this message translates to:
  /// **'Oke'**
  String get celebrationClose;

  /// No description provided for @pickerTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih hutang'**
  String get pickerTitle;

  /// No description provided for @pickerEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada hutang aktif untuk dicatat.'**
  String get pickerEmpty;

  /// No description provided for @pickerAddDebt.
  ///
  /// In id, this message translates to:
  /// **'Tambah hutang'**
  String get pickerAddDebt;

  /// No description provided for @paymentDeleteTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus pembayaran?'**
  String get paymentDeleteTitle;

  /// No description provided for @paymentDeleteBody.
  ///
  /// In id, this message translates to:
  /// **'Sisa hutang akan kembali seperti sebelum pembayaran ini.'**
  String get paymentDeleteBody;

  /// No description provided for @paymentDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get paymentDeleteConfirm;

  /// No description provided for @paymentDeleteTooltip.
  ///
  /// In id, this message translates to:
  /// **'Hapus pembayaran'**
  String get paymentDeleteTooltip;

  /// No description provided for @paymentDeleteFailed.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran belum bisa dihapus. Coba lagi sebentar lagi.'**
  String get paymentDeleteFailed;

  /// No description provided for @detailMenuSettle.
  ///
  /// In id, this message translates to:
  /// **'Tandai lunas'**
  String get detailMenuSettle;

  /// No description provided for @detailMenuArchive.
  ///
  /// In id, this message translates to:
  /// **'Arsipkan'**
  String get detailMenuArchive;

  /// No description provided for @detailMenuDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get detailMenuDelete;

  /// No description provided for @actionArchiveTitle.
  ///
  /// In id, this message translates to:
  /// **'Arsipkan hutang?'**
  String get actionArchiveTitle;

  /// No description provided for @actionArchiveBody.
  ///
  /// In id, this message translates to:
  /// **'Hutang tidak tampil lagi di daftar, tetapi datanya tetap tersimpan.'**
  String get actionArchiveBody;

  /// No description provided for @actionArchiveConfirm.
  ///
  /// In id, this message translates to:
  /// **'Arsipkan'**
  String get actionArchiveConfirm;

  /// No description provided for @actionDeleteTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus hutang?'**
  String get actionDeleteTitle;

  /// No description provided for @actionDeleteBody.
  ///
  /// In id, this message translates to:
  /// **'Hutang beserta jadwal dan riwayat pembayarannya akan dihapus dan tidak bisa dikembalikan.'**
  String get actionDeleteBody;

  /// No description provided for @actionDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get actionDeleteConfirm;

  /// No description provided for @actionSettleTitle.
  ///
  /// In id, this message translates to:
  /// **'Tandai lunas?'**
  String get actionSettleTitle;

  /// No description provided for @actionSettleBody.
  ///
  /// In id, this message translates to:
  /// **'Kami catat satu pembayaran sebesar sisa ({amount}) pada hari ini.'**
  String actionSettleBody(String amount);

  /// No description provided for @actionSettleConfirm.
  ///
  /// In id, this message translates to:
  /// **'Tandai lunas'**
  String get actionSettleConfirm;

  /// No description provided for @actionFailed.
  ///
  /// In id, this message translates to:
  /// **'Belum bisa menyelesaikannya. Coba lagi sebentar lagi.'**
  String get actionFailed;
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
