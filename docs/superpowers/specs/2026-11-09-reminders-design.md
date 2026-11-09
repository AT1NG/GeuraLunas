# Fase 3 — Pengingat dan Tagih: Spesifikasi Desain

Tanggal: 2026-11-09 · Status: menunggu review user

Mencakup US-06 (pengingat jatuh tempo) dan US-07 (tagih teman) dari [PRD](../../PRD.md). Keputusan arsitektur dasar ada di ADR-008 (notifikasi lokal) dan [ARCHITECTURE.md bagian 4.3](../../ARCHITECTURE.md).

## 1. Keputusan hasil brainstorming

1. **Alarm tepat dengan izin.** Notifikasi dijadwalkan sebagai alarm tepat (`SCHEDULE_EXACT_ALARM`). Bila izin ditolak, jatuh ke alarm tidak tepat dan pengguna diberi tahu di Pengaturan. Risiko: Play Store membatasi izin ini untuk app non-alarm; bila perlu, ganti ke alarm tidak tepat tanpa mengubah desain lain.
2. **Piutang tanpa alarm.** Hanya hutang "aku berutang" yang punya notifikasi. Untuk piutang cukup melihat siapa yang berutang; tidak ada pengingat terjadwal.
3. **Tombol Tagih hanya di detail piutang.** Tidak ada perubahan pada kartu di daftar. Daftar "piutang untuk ditagih" di Beranda menyusul di Fase 4.

Perubahan terhadap PRD: US-07 tidak lagi berarti "mendapat pengingat untuk menagih"; artinya menjadi "membagikan teks tagih yang sopan". US-06 tidak berubah.

## 2. Pengingat bayar (US-06)

### 2.1 Aturan

- Satu notifikasi per cicilan belum lunas per hari pengingat. Hari pengingat mengikuti `settings.reminderDaysBefore` (bawaan `[3, 1, 0]`), waktu mengikuti `settings.reminderTime` (bawaan `09:00`), zona waktu `settings.timezone`.
- Hanya hutang berarah `owe`, berstatus aktif, dengan cicilan yang belum `paid`.
- Dibuang dari rencana: cicilan lunas, hutang lunas atau diarsipkan, piutang, dan waktu pengingat yang sudah lewat.
- Cicilan `partial` tetap diingatkan. Teks memakai sisa cicilan, bukan jumlah penuh.
- Hutang tanpa jatuh tempo tidak punya cicilan, jadi tidak ada pengingat.
- Contoh teks: judul "Cicilan jatuh tempo", isi "Cicilan Paylater A Rp350.000 jatuh tempo besok." Bentuk waktu: hari-H "hari ini", H-1 "besok", selebihnya "dalam N hari".
- Tap notifikasi membuka `/debts/{debtId}`.

### 2.2 Domain (Dart murni, `lib/domain/reminder/`)

- `ReminderSettings({required TimeOfDayValue time, required List<int> daysBefore, required String timezone})`. Memakai tipe sendiri untuk jam, bukan `TimeOfDay` Flutter, supaya domain tetap murni.
- `ReminderPlan({required int id, required DateTime at, required String title, required String body, required String debtId})`.
- `List<ReminderPlan> planReminders({required List<DebtState> debts, required ReminderSettings settings, required DateTime now, int horizonDays = 60, int maxCount = 200})`:
  - Menyaring seperti 2.1, lalu mengurutkan menurut waktu dan memotong pada `horizonDays` dan `maxCount`.
  - ID deterministik dari `debtId`, `seq`, dan `offset` (hash stabil, dalam rentang int 31-bit yang diterima Android). Panggilan berulang dengan data sama menghasilkan ID sama.
- Perhitungan "waktu pengingat" memakai tanggal jatuh tempo kalender dikurangi `n` hari, pada `reminderTime` di zona `timezone`.

### 2.3 Data dan repository

- `NotificationDataSource` (`lib/data/`), pembungkus tipis `flutter_local_notifications`, `timezone`, dan `flutter_timezone`: `init()`, `cancelAll()`, `schedule(List<ReminderPlan>)`, `permissionStatus()`, `requestPermissions()`, aliran tap notifikasi berisi `debtId`.
- `ReminderRepository` (`lib/repositories/`): `rescheduleAll()` membaca hutang dan cicilan lewat `DebtRepository`, membaca `ReminderSettings`, memanggil `planReminders`, lalu `cancelAll()` dan `schedule`. Idempoten. Penjadwalan berjalan serial (antrean, seperti `ensureProfile`) agar dua pemicu bersamaan tidak saling menimpa.
- Kegagalan menjadwalkan tidak boleh memblokir app: dicatat ke log tanpa nominal atau nama, dan dicoba lagi pada pemicu berikutnya.

### 2.4 Pemicu penjadwalan ulang

- Saat login dan saat app dibuka (cold start dan kembali dari background).
- Setiap data hutang atau cicilan berubah, lewat stream hutang yang sudah ada, dengan debounce pendek supaya satu pembayaran yang mengubah beberapa dokumen hanya memicu satu kali.
- Saat pengaturan pengingat diubah.
- Setelah reboot, lewat receiver bawaan plugin.
- Saat keluar akun: `cancelAll()`.

### 2.5 Izin dan manifest

- `POST_NOTIFICATIONS` (Android 13+): diminta saat pertama kali ada hutang `owe` dengan jadwal (setelah menyimpan hutang, bukan saat app baru dibuka). Penolakan tidak mengganggu fitur lain; status tampil di Pengaturan.
- `SCHEDULE_EXACT_ALARM` (Android 12+): bila tidak diberikan, jadwalkan sebagai alarm tidak tepat.
- `RECEIVE_BOOT_COMPLETED` dan receiver plugin untuk jadwal ulang setelah reboot.
- Notifikasi tidak memuat data lain selain nama pihak dan nominal (sesuai template di UI-UX).

## 3. Pengaturan pengingat

Di layar Pengaturan yang sudah ada:

- Pemilih jam (time picker), bawaan 09:00.
- Chip hari pengingat yang dapat dipilih bersamaan: H-0, H-1, H-2, H-3, H-5, H-7. Minimal satu aktif. Sesuai rules (bilangan 0–7, maksimal 8 isi).
- Baris status izin: notifikasi dimatikan menampilkan tombol "Izinkan"; alarm tepat tidak diizinkan menampilkan catatan "Pengingat bisa meleset beberapa menit" dan tombol ke pengaturan sistem.
- Teks bantuan baterai: "Kalau notifikasi tidak muncul, matikan penghemat baterai untuk GeuraLunas."
- `ReminderSettingsCubit` memuat dan menyimpan `settings.reminderTime` dan `settings.reminderDaysBefore` ke `users/{uid}` lewat `UserProfileRepository`, lalu memicu `rescheduleAll()`. Menyimpan mengikuti pola offline-safe yang sama (tidak menunggu server).

## 4. Tagih (US-07)

- Tombol "Tagih" di kartu ringkasan detail piutang, hanya untuk piutang yang aktif.
- Mengetuk membuka lembar bawah berisi teks yang bisa diedit dan tombol "Bagikan" (share sheet sistem lewat `share_plus`). Tidak ada integrasi WhatsApp atau API pihak ketiga.
- Teks dihasilkan oleh fungsi domain murni `buildCollectionMessage({required String name, required Money remaining, DateTime? dueDate, required DateTime now})`:
  - Jatuh tempo belum lewat: "Halo {nama}, mau mengingatkan pinjaman {sisa} yang jatuh tempo tanggal {tgl}. Kapan kira-kira bisa dibayar? Terima kasih ya."
  - Sudah lewat: "... yang jatuh tempo tanggal {tgl} lalu. Kapan kira-kira bisa dibayar? Terima kasih ya."
  - Tanpa jatuh tempo: "Halo {nama}, mau mengingatkan soal pinjaman {sisa}. Kapan kira-kira bisa dibayar? Terima kasih ya."
  - Nominal yang ditagih adalah sisa (setelah cicilan yang sudah dibayar), bukan total.
- Teks hanya dari template tetap; catatan pengguna tidak disisipkan. Karena itu tidak pernah memuat kata kasar atau mengancam.
- Tidak ada yang disimpan ke Firestore setelah berbagi. Menandai "sudah ditagih" bukan bagian Fase 3.

## 5. Dependensi baru

`flutter_local_notifications`, `timezone`, `flutter_timezone`, `share_plus`. Semua sudah sejalan dengan ARCHITECTURE bagian 2 kecuali `share_plus`, yang ditambahkan ke tabel itu. Versi dipilih yang kompatibel dengan Flutter 3.41 / Dart 3.11 saat rencana implementasi disusun.

## 6. Pengujian

- **Domain (target 100%):** `planReminders` (hari pengingat, jam, hutang `lent` diabaikan, cicilan lunas dan `partial`, hutang lunas atau diarsipkan, batas 60 hari dan 200 notifikasi, ID stabil, tanggal akhir bulan, pergantian zona waktu), `buildCollectionMessage` (tiga bentuk, sisa setelah cicilan), nama hari relatif.
- **Repository:** `rescheduleAll` memanggil `cancelAll` lalu `schedule` dengan rencana yang benar (data source dimock); serial untuk panggilan bersamaan; kegagalan tidak melempar.
- **Cubit:** pengaturan (muat, validasi minimal satu hari, simpan memicu penjadwalan ulang), izin.
- **Widget:** layar pengaturan pengingat, lembar Tagih (teks bisa diedit, tombol Bagikan memanggil share).
- **Manual di emulator:** alarm tepat tampil pada waktunya (uji dengan jam yang dimajukan), notifikasi hilang setelah cicilan dibayar, jadwal bertahan setelah reboot, tap membuka detail, izin ditolak lalu diizinkan.

## 7. Di luar cakupan

Pengingat untuk piutang, penanda "sudah ditagih", daftar piutang untuk ditagih di Beranda (Fase 4), mengubah teks template secara permanen, notifikasi push dari server.

## 8. Dokumen yang diperbarui bersama implementasi

PRD (US-07), ARCHITECTURE (tabel dependensi, bagian 4.3), DECISIONS (ADR-014 piutang tanpa alarm, ADR-015 alarm tepat dengan fallback), TESTING, CHANGELOG, TODO.
