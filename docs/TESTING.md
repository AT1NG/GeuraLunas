# TESTING — Lunasin

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
| Security rules | Akses lintas pengguna, validasi field | Firebase Emulator | semua aturan |
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

**Simulasi**
- Satu hutang: snowball = avalanche.
- Dua hutang: urutan prioritas benar menurut metode; avalanche total bunga ≤ snowball.
- Dana ekstra 0 menghasilkan jadwal normal.
- Cicilan hutang lunas dialihkan ke prioritas berikutnya.
- Simulasi berhenti (tidak loop tak terbatas) jika pembayaran tidak menutupi bunga; hasil menandai "tidak pernah lunas".

## 4. Security rules

Dengan emulator: pengguna A tidak bisa membaca/menulis data B; pengguna anonim ditolak; `amount ≤ 0` ditolak; nilai enum tidak dikenal ditolak; `remaining < 0` ditolak.

## 5. Checklist manual sebelum rilis

- [ ] Notifikasi muncul H-3, H-1, hari-H tanpa internet
- [ ] Notifikasi tetap terjadwal setelah restart HP
- [ ] Notifikasi berhenti setelah cicilan dibayar
- [ ] Mode pesawat: tambah hutang & bayar, lalu online → tersinkron
- [ ] Login Google dan email, reset password
- [ ] Data muncul setelah masuk di HP lain
- [ ] Dark mode, teks besar, TalkBack
- [ ] Hapus akun menghapus semua data

## 6. Cara menjalankan

```
flutter analyze
flutter test --coverage
firebase emulators:exec "flutter test test/rules"   # security rules
```

Untuk gerbang kualitas penuh gunakan skill `vgv-ai-flutter-plugin:green-gate`.
