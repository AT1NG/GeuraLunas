# Changelog

Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/) dan versi mengikuti [SemVer](https://semver.org/lang/id/).

## [Belum dirilis]

### Ditambahkan
- Dokumen perencanaan: README, CLAUDE, TODO, PRD, ARCHITECTURE, DATABASE, UI-UX, TESTING, DECISIONS, DIAGRAMS.
- Fondasi aplikasi Flutter (Android): tema Material 3 terang/gelap, format rupiah dan tanggal Indonesia, lokalisasi `id`.
- Navigasi bawah 5 tab dengan `go_router` dan menu tambah.
- Autentikasi Firebase: masuk dengan Google atau email, daftar, lupa password, keluar.
- Onboarding 3 slide dengan penanda tersimpan.
- Profil pengguna di Firestore (`users/{uid}`) dengan pengaturan bawaan, dan layar Pengaturan.
- Security rules Firestore awal dengan 12 test emulator.
- Hutang dan piutang: tambah (pinjol, cicilan, teman) dengan bunga flat/anuitas dan pratinjau jadwal, ubah, lihat daftar (Aku berutang / Piutang, filter aktif/lunas), detail dengan jadwal dan riwayat, tandai lunas, arsip, dan hapus.
- Pembayaran: catat dengan nominal, tanggal, dan catatan (sisa dan cicilan terkait ikut diperbarui secara atomik), batalkan pembayaran, dan pesan perayaan saat lunas.
- Rules Firestore untuk hutang, cicilan, dan pembayaran dengan 35 test emulator.
- Pengingat jatuh tempo (US-06): notifikasi lokal tepat waktu untuk cicilan hutang "aku berutang" (bawaan H-3, H-1, hari-H pukul 09:00), dijadwalkan ulang saat data berubah, saat app dibuka, dan setelah restart; pengaturan jam dan hari di layar Pengaturan, dengan status izin notifikasi dan alarm tepat.
- Tagih teman (US-07): tombol Tagih di detail piutang aktif membuka teks sopan yang bisa diedit lalu dibagikan lewat share sheet.
- Pengeluaran: catat dalam tiga ketukan dari menu Tambah, daftar pengeluaran siklus berjalan di tab Budget, kategori default dan kelola kategori (tambah, ubah nama, arsipkan).
- Kalkulasi jatah aman di domain (belum tampil di Beranda): siklus budget, sisa bulanan, jatah hari ini dan minggu ini.
