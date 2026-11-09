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
}
