# Changelog

Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/) dan versi mengikuti [SemVer](https://semver.org/lang/id/).

## [Belum dirilis]

### Diperbaiki
- Daftar akun tidak lagi memicu penulisan profil ganda yang ditolak server.

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
