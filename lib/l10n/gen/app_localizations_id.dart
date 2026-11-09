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

  @override
  String get debtFormNewTitle => 'Tambah hutang';

  @override
  String get debtFormEditTitle => 'Ubah hutang';

  @override
  String get formDirectionOwe => 'Aku berutang';

  @override
  String get formDirectionLent => 'Dia berutang ke aku';

  @override
  String get formKindPinjol => 'Pinjol';

  @override
  String get formKindInstallment => 'Cicilan';

  @override
  String get formKindPersonal => 'Teman';

  @override
  String get formName => 'Nama pihak (platform, toko, atau teman)';

  @override
  String get formPrincipal => 'Pokok pinjaman';

  @override
  String get formInterestTitle => 'Bunga';

  @override
  String get formInterestNone => 'Tanpa bunga';

  @override
  String get formInterestFlatMonthly => 'Flat per bulan';

  @override
  String get formInterestFlatDaily => 'Flat per hari';

  @override
  String get formInterestReducing => 'Anuitas (menurun)';

  @override
  String get formRateMonthly => 'Bunga (% per bulan)';

  @override
  String get formRateDaily => 'Bunga (% per hari)';

  @override
  String get formAdminFee => 'Biaya admin (opsional)';

  @override
  String get formTenor => 'Jumlah cicilan';

  @override
  String get formTenorDays => 'Tenor (hari)';

  @override
  String get formFrequencyTitle => 'Cicilan setiap';

  @override
  String get formFrequencyMonthly => 'Bulan';

  @override
  String get formFrequencyWeekly => 'Minggu';

  @override
  String get formStartDate => 'Tanggal mulai';

  @override
  String get formFirstDue => 'Jatuh tempo pertama';

  @override
  String get formFirstDueAuto => 'Otomatis';

  @override
  String get formFirstDueClear => 'Hapus tanggal';

  @override
  String get formNote => 'Catatan (opsional)';

  @override
  String get formPreviewTitle => 'Pratinjau';

  @override
  String formPreviewTotal(String amount) {
    return 'Total yang harus dibayar: $amount';
  }

  @override
  String formPreviewRow(int n) {
    return 'Cicilan $n';
  }

  @override
  String formPreviewMore(int count) {
    return 'dan $count cicilan lainnya';
  }

  @override
  String get formSubmitNew => 'Simpan';

  @override
  String get formSubmitEdit => 'Simpan perubahan';

  @override
  String get formErrorAmount => 'Isi nominal yang benar, lebih dari Rp0.';

  @override
  String get formErrorNumber => 'Isi angka yang benar.';

  @override
  String formErrorBelowPaid(String amount) {
    return 'Total tidak boleh kurang dari yang sudah dibayar ($amount).';
  }

  @override
  String get formSaveFailed => 'Belum bisa menyimpan. Coba lagi sebentar lagi.';

  @override
  String get formPaidWarning =>
      'Hutang ini sudah punya pembayaran. Kalau nominal, bunga, atau tenor diubah, jadwal dihitung ulang dan pembayaran yang ada diterapkan lagi ke cicilan.';

  @override
  String get formNotFound =>
      'Hutang ini tidak ditemukan. Mungkin sudah dihapus.';

  @override
  String get detailKindPinjol => 'Pinjol';

  @override
  String get detailKindInstallment => 'Cicilan';

  @override
  String get detailKindPersonal => 'Pinjaman teman';

  @override
  String get detailDirectionOwe => 'Aku berutang';

  @override
  String get detailDirectionLent => 'Dia berutang ke aku';

  @override
  String detailKindDirection(String kind, String direction) {
    return '$kind · $direction';
  }

  @override
  String get detailRemainingOwe => 'Sisa yang harus dibayar';

  @override
  String get detailRemainingLent => 'Sisa yang akan diterima';

  @override
  String detailPaidOf(String paid, String total) {
    return '$paid dari $total';
  }

  @override
  String detailProgressSemantics(String paid, String total) {
    return 'Sudah dibayar $paid dari $total';
  }

  @override
  String get detailPayOwe => 'Bayar';

  @override
  String get detailPayLent => 'Catat penerimaan';

  @override
  String get detailSettledOwe => 'Lunas! Satu beban berkurang.';

  @override
  String get detailSettledLent => 'Lunas! Semuanya sudah kembali.';

  @override
  String get detailScheduleTitle => 'Jadwal cicilan';

  @override
  String get detailNoSchedule => 'Tidak ada jadwal cicilan.';

  @override
  String installmentTitle(int n) {
    return 'Cicilan $n';
  }

  @override
  String installmentDue(String date) {
    return 'Jatuh tempo $date';
  }

  @override
  String get installmentPaid => 'Lunas';

  @override
  String installmentPartial(String paid, String total) {
    return 'Sebagian ($paid dari $total)';
  }

  @override
  String get installmentPending => 'Belum dibayar';

  @override
  String get detailPaymentsOwe => 'Riwayat pembayaran';

  @override
  String get detailPaymentsLent => 'Riwayat penerimaan';

  @override
  String get detailNoPayments => 'Belum ada pembayaran.';

  @override
  String get detailEdit => 'Ubah';

  @override
  String get detailMenu => 'Menu';

  @override
  String get payTitleOwe => 'Catat pembayaran';

  @override
  String get payTitleLent => 'Catat penerimaan';

  @override
  String get payDirectionOwe => 'Aku bayar';

  @override
  String payDirectionLent(String name) {
    return 'Diterima dari $name';
  }

  @override
  String payRemainingNow(String amount) {
    return 'Sisa sekarang $amount';
  }

  @override
  String get payAmount => 'Nominal';

  @override
  String get payDate => 'Tanggal';

  @override
  String get payInstallment => 'Untuk cicilan';

  @override
  String get payInstallmentAuto => 'Otomatis (cicilan terdekat)';

  @override
  String payInstallmentOption(int n, String amount) {
    return 'Cicilan $n · sisa $amount';
  }

  @override
  String get payNote => 'Catatan (opsional)';

  @override
  String get paySubmit => 'Simpan';

  @override
  String get payErrorAmount => 'Isi nominal pembayaran.';

  @override
  String payErrorExceeds(String amount) {
    return 'Nominal melebihi sisa hutang ($amount). Isi paling banyak sebesar sisa.';
  }

  @override
  String get payErrorFuture => 'Tanggal tidak boleh di masa depan.';

  @override
  String paySaved(String amount) {
    return 'Tercatat. Sisa sekarang $amount.';
  }

  @override
  String get payFailed =>
      'Belum bisa menyimpan pembayaran. Coba lagi sebentar lagi.';

  @override
  String get payUnavailable =>
      'Hutang ini tidak bisa dibayar lagi. Mungkin sudah lunas atau sudah dihapus.';

  @override
  String get celebrationClose => 'Oke';

  @override
  String get pickerTitle => 'Pilih hutang';

  @override
  String get pickerEmpty => 'Belum ada hutang aktif untuk dicatat.';

  @override
  String get pickerAddDebt => 'Tambah hutang';

  @override
  String get paymentDeleteTitle => 'Hapus pembayaran?';

  @override
  String get paymentDeleteBody =>
      'Sisa hutang akan kembali seperti sebelum pembayaran ini.';

  @override
  String get paymentDeleteConfirm => 'Hapus';

  @override
  String get paymentDeleteTooltip => 'Hapus pembayaran';

  @override
  String get paymentDeleteFailed =>
      'Pembayaran belum bisa dihapus. Coba lagi sebentar lagi.';

  @override
  String get detailMenuSettle => 'Tandai lunas';

  @override
  String get detailMenuArchive => 'Arsipkan';

  @override
  String get detailMenuDelete => 'Hapus';

  @override
  String get actionArchiveTitle => 'Arsipkan hutang?';

  @override
  String get actionArchiveBody =>
      'Hutang tidak tampil lagi di daftar, tetapi datanya tetap tersimpan.';

  @override
  String get actionArchiveConfirm => 'Arsipkan';

  @override
  String get actionDeleteTitle => 'Hapus hutang?';

  @override
  String get actionDeleteBody =>
      'Hutang beserta jadwal dan riwayat pembayarannya akan dihapus dan tidak bisa dikembalikan.';

  @override
  String get actionDeleteConfirm => 'Hapus';

  @override
  String get actionSettleTitle => 'Tandai lunas?';

  @override
  String actionSettleBody(String amount) {
    return 'Kami catat satu pembayaran sebesar sisa ($amount) pada hari ini.';
  }

  @override
  String get actionSettleConfirm => 'Tandai lunas';

  @override
  String get actionFailed =>
      'Belum bisa menyelesaikannya. Coba lagi sebentar lagi.';

  @override
  String get writeRejected =>
      'Perubahan terakhir belum bisa disimpan ke server dan dibatalkan. Coba lagi ya.';

  @override
  String get reminderTitle => 'Cicilan jatuh tempo';

  @override
  String reminderBody(String name, String amount, String when) {
    return 'Cicilan $name $amount jatuh tempo $when.';
  }

  @override
  String get reminderWhenToday => 'hari ini';

  @override
  String get reminderWhenTomorrow => 'besok';

  @override
  String reminderWhenInDays(int days) {
    return 'dalam $days hari';
  }

  @override
  String collectionBeforeDue(String name, String amount, String date) {
    return 'Halo $name, mau mengingatkan pinjaman $amount yang jatuh tempo tanggal $date. Kapan kira-kira bisa dibayar? Terima kasih ya.';
  }

  @override
  String collectionAfterDue(String name, String amount, String date) {
    return 'Halo $name, mau mengingatkan pinjaman $amount yang jatuh tempo tanggal $date lalu. Kapan kira-kira bisa dibayar? Terima kasih ya.';
  }

  @override
  String collectionNoDue(String name, String amount) {
    return 'Halo $name, mau mengingatkan soal pinjaman $amount. Kapan kira-kira bisa dibayar? Terima kasih ya.';
  }
}
