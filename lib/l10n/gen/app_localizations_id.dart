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
  String get addMenuExpense => 'Catat pengeluaran';

  @override
  String get addMenuPayment => 'Catat pembayaran';

  @override
  String get addMenuDebt => 'Tambah hutang';
}
