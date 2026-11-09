// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'GeuraLunas';

  @override
  String get navHome => 'Beranda';

  @override
  String get navDebts => 'Hutang';

  @override
  String get navBudget => 'Budget';

  @override
  String get navMore => 'Lainnya';

  @override
  String get navAdd => 'Tambah';

  @override
  String get addMenuExpense => 'Catat pengeluaran';

  @override
  String get addMenuPayment => 'Catat pembayaran';

  @override
  String get addMenuDebt => 'Tambah hutang';

  @override
  String get onboardingTitle1 => 'Catat semua hutang di satu tempat';

  @override
  String get onboardingBody1 =>
      'Pinjol, cicilan, atau pinjaman dari teman. Semua terlihat jelas, tanpa perlu diingat-ingat.';

  @override
  String get onboardingTitle2 => 'Jangan sampai telat bayar';

  @override
  String get onboardingBody2 =>
      'Kami ingatkan sebelum jatuh tempo, supaya kamu tenang dan terhindar dari denda.';

  @override
  String get onboardingTitle3 => 'Jatah jajan harian yang aman';

  @override
  String get onboardingBody3 =>
      'Kami hitung sisa uangmu setelah cicilan, jadi kamu tahu berapa yang aman dipakai hari ini.';

  @override
  String get onboardingSkip => 'Lewati';

  @override
  String get onboardingNext => 'Lanjut';

  @override
  String get onboardingStart => 'Mulai';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authName => 'Nama';

  @override
  String get authOr => 'atau';

  @override
  String get authShowPassword => 'Tampilkan password';

  @override
  String get authHidePassword => 'Sembunyikan password';

  @override
  String get validationRequired => 'Wajib diisi';

  @override
  String get validationInvalidEmail => 'Format email belum benar';

  @override
  String get validationPasswordTooShort => 'Minimal 8 karakter';

  @override
  String get authErrorInvalidCredentials =>
      'Email atau password belum cocok. Coba cek lagi ya.';

  @override
  String get authErrorInvalidEmail => 'Format email belum benar.';

  @override
  String get authErrorEmailInUse =>
      'Email ini sudah terdaftar. Coba masuk, atau pakai email lain.';

  @override
  String get authErrorWeakPassword =>
      'Password terlalu mudah ditebak. Pakai minimal 8 karakter.';

  @override
  String get authErrorTooManyRequests =>
      'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';

  @override
  String get authErrorNetwork =>
      'Tidak ada koneksi internet. Coba lagi setelah tersambung.';

  @override
  String get authErrorDifferentCredential =>
      'Email ini sudah dipakai dengan cara masuk lain. Coba masuk dengan email dan password.';

  @override
  String get authErrorUnknown =>
      'Ada yang tidak beres. Coba lagi sebentar lagi.';

  @override
  String get loginTitle => 'Masuk';

  @override
  String get loginSubtitle =>
      'Senang melihatmu lagi. Yuk lanjut beresin hutang.';

  @override
  String get loginSubmit => 'Masuk';

  @override
  String get loginGoogle => 'Masuk dengan Google';

  @override
  String get loginForgot => 'Lupa password?';

  @override
  String get loginNoAccount => 'Belum punya akun?';

  @override
  String get loginToRegister => 'Daftar';

  @override
  String get registerTitle => 'Buat akun';

  @override
  String get registerSubtitle => 'Mulai catat hutangmu dengan tenang.';

  @override
  String get registerSubmit => 'Daftar';

  @override
  String get registerHaveAccount => 'Sudah punya akun?';

  @override
  String get registerToLogin => 'Masuk';

  @override
  String get forgotTitle => 'Lupa password';

  @override
  String get forgotBody =>
      'Masukkan email akunmu. Kami kirim tautan untuk membuat password baru.';

  @override
  String get forgotSubmit => 'Kirim tautan';

  @override
  String get forgotSent =>
      'Kalau email itu terdaftar, tautan sudah kami kirim. Cek kotak masuk atau folder spam.';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonComingSoon => 'Segera hadir';

  @override
  String get moreSimulation => 'Simulasi pelunasan';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsNoName => 'Tanpa nama';

  @override
  String get settingsSignOut => 'Keluar';

  @override
  String get settingsSignOutConfirmTitle => 'Keluar dari akun?';

  @override
  String get settingsSignOutConfirmBody =>
      'Datamu tetap aman dan akan muncul lagi saat kamu masuk.';

  @override
  String get debtsTabOwe => 'Aku berutang';

  @override
  String get debtsTabLent => 'Piutang';

  @override
  String get debtsTotalOwe => 'Total yang harus kamu bayar';

  @override
  String get debtsTotalLent => 'Total yang akan kamu terima';

  @override
  String get debtsFilterActive => 'Aktif';

  @override
  String get debtsFilterSettled => 'Lunas';

  @override
  String get debtsEmptyOwe =>
      'Belum ada hutang yang tercatat. Mulai dari yang pertama, pelan-pelan saja.';

  @override
  String get debtsEmptyLent => 'Belum ada piutang yang tercatat.';

  @override
  String get debtsEmptySettled =>
      'Belum ada yang lunas. Satu per satu pasti sampai.';

  @override
  String get debtsEmptyAction => 'Tambah hutang pertamamu';

  @override
  String get debtsLoadError =>
      'Datamu belum bisa dimuat. Coba lagi sebentar lagi.';

  @override
  String get statusOverdue => 'Terlambat';

  @override
  String get statusDueSoon => 'Segera jatuh tempo';

  @override
  String get statusSettled => 'Lunas';

  @override
  String get statusActive => 'Aktif';

  @override
  String debtCardRemaining(String amount) {
    return 'Sisa $amount';
  }

  @override
  String debtCardDue(String date) {
    return 'Jatuh tempo $date';
  }

  @override
  String get debtCardNoDue => 'Tanpa jatuh tempo';

  @override
  String debtCardSemantics(String name, String amount, String due) {
    return '$name, sisa $amount, $due';
  }
}
