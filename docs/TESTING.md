# TESTING — GeuraLunas

Versi 0.1 · 2026-11-09

## 1. Prinsip

- Logika uang diuji paling ketat karena kesalahan di sini langsung merugikan pengguna.
- Test ditulis sebelum implementasi untuk `domain` (TDD).
- Satu tugas dianggap selesai hanya jika `flutter analyze` dan `flutter test` hijau dan hasilnya terlihat.

## 2. Piramida dan target

| Level | Cakupan | Alat | Target coverage |
|---|---|---|---|
| Unit — domain | Money, bunga, jadwal, jatah aman, simulator | `flutter_test` | 100% |
| Unit — repository | Pemetaan DTO ↔ domain, validasi, atomik batch | `mocktail`, fake Firestore | ≥ 90% |
| Bloc | Transisi state tiap event | `bloc_test` | ≥ 90% |
| Widget | Layar utama, form, validasi, state kosong/error | `flutter_test` | ≥ 70% |
| Security rules | Akses lintas pengguna, validasi field | Firebase Emulator + `node:test` (`firebase/`) | semua aturan |
| Integrasi/E2E | Alur: daftar → tambah hutang → bayar → lunas | `integration_test` | alur kritis |
| Manual | Notifikasi di perangkat nyata, offline, restart | checklist | sebelum rilis |

Coverage keseluruhan ≥ 80%. File yang dikecualikan dari penyebut harus beralasan (kode generated, `main.dart`).

## 3. Kasus uji wajib (domain)

**Bunga dan total**
- Tanpa bunga: `principal + adminFee`.
- Flat bulanan: pokok 1.000.000, 3%/bulan, 3 bulan → bunga 90.000.
- Flat harian: pokok 1.000.000, 0,4%/hari, 30 hari → bunga 120.000.
- Anuitas: bandingkan dengan nilai referensi spreadsheet untuk 3 kombinasi (pokok, bunga, tenor).
- Bunga 0 dan tenor 1 tidak menyebabkan pembagian nol.

**Jadwal cicilan**
- Total dibagi rata; sisa pembulatan ke cicilan terakhir; jumlah cicilan = `totalPayable`.
- Jatuh tempo bulanan dari tanggal 31 Jan → 28/29 Feb → 31 Mar (pemangkasan akhir bulan).
- Tahun kabisat.
- Mingguan melintasi pergantian bulan/tahun.

**Pembayaran**
- Bayar penuh satu cicilan → status `paid`, `nextDueDate` maju.
- Bayar sebagian → `partial`, sisa cicilan benar.
- Bayar melebihi sisa ditolak.
- Hapus pembayaran mengembalikan semua nilai persis seperti sebelum dibayar.
- Hutang `remaining == 0` otomatis `settled`.

**Jatah aman**
- Pemasukan 5.000.000, cicilan 1.500.000, target tabung 500.000, belum ada pengeluaran → batas 3.000.000.
- Pengeluaran melebihi batas → jatah 0 (bukan negatif).
- Cicilan > pemasukan → status khusus.
- Hari terakhir siklus: jatah = sisa penuh.
- Piutang tidak menambah pemasukan.
- Pergantian bulan dan siklus tanggal gajian ≠ 1.
- Minggu berjalan Senin sampai Minggu: hari Selasa memberi 6 hari tersisa, hari Minggu 1, hari Senin 7; dipotong akhir siklus.
- Cicilan sebagian dihitung sisanya; cicilan `paid`, hutang `lent`, `settled`, `archived`, dan cicilan di luar siklus diabaikan.
- Pengeluaran jam 23:59 hari terakhir siklus masuk siklus itu; 00:00 hari berikutnya tidak.
- Siklus melintasi tahun baru, tanggal mulai 28 pada Februari biasa dan kabisat.

**Simulasi**
- Satu hutang: snowball = avalanche.
- Dua hutang: urutan prioritas benar menurut metode; avalanche total bunga ≤ snowball.
- Dana ekstra 0 menghasilkan jadwal normal.
- Cicilan hutang lunas dialihkan ke prioritas berikutnya.
- Simulasi berhenti (tidak loop tak terbatas) jika pembayaran tidak menutupi bunga; hasil menandai "tidak pernah lunas".

## 4. Security rules

Dengan emulator Firestore dan runner JavaScript di `firebase/` (bukan `flutter test`): pengguna A tidak bisa membaca/menulis data B; pengguna anonim ditolak; `amount ≤ 0` ditolak; nilai enum tidak dikenal ditolak; `remaining < 0` ditolak.

## 5. Checklist manual sebelum rilis

- [ ] Notifikasi muncul tepat waktu (jam pengingat dimajukan dua menit ke depan), tanpa internet
- [ ] Notifikasi tetap terjadwal setelah restart HP
- [ ] Notifikasi berikutnya hilang setelah cicilan dibayar
- [ ] Ketuk notifikasi membuka detail hutang yang benar (app mati dan app berjalan)
- [ ] Izin notifikasi ditolak lalu diizinkan dari Pengaturan; matikan alarm tepat: catatan "meleset" tampil
- [ ] Keluar akun: tidak ada notifikasi tersisa; masuk akun lain: hanya hutang akun itu
- [ ] Piutang aktif: tombol Tagih membuka teks sopan, bisa diedit, dan membuka share sheet
- [ ] Catat pengeluaran dalam tiga ketukan dari menu Tambah; nominal tempelan `Rp 1.500.000` diterima, `0` ditolak dengan pesan ramah
- [ ] Catat pengeluaran dalam mode pesawat, lalu online: tersinkron dan muncul di tab Budget
- [ ] Arsipkan kategori yang sudah dipakai: baris pengeluaran lama tetap menampilkan nama kategorinya, kategori tidak muncul di pilihan
- [ ] Hapus pengeluaran meminta konfirmasi; batal tidak menghapus
- [ ] Masuk ulang atau di HP lain: tujuh kategori default muncul sekali, tanpa duplikat
- [ ] Mode pesawat: tambah hutang & bayar, lalu online → tersinkron
- [ ] Login Google dan email, reset password
- [ ] Data muncul setelah masuk di HP lain
- [ ] Dark mode, teks besar, TalkBack
- [ ] Hapus akun menghapus semua data

## 6. Cara menjalankan

```
flutter analyze
flutter test --coverage
cd firebase && npm install && npm test        # security rules (butuh Java 17+)
```

Untuk gerbang kualitas penuh gunakan skill `vgv-ai-flutter-plugin:green-gate`.
