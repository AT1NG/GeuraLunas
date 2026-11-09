# TODO — GeuraLunas

> Aturan: update file ini setiap tugas selesai (centang, isi Log selesai, pindahkan "Sedang dikerjakan"). Lihat [CLAUDE.md](CLAUDE.md).

## Sedang dikerjakan

- Fase 2 Task 7: detail hutang (lihat docs/superpowers/plans/2026-11-09-phase2-debts-payments.md). Menunggu persetujuan user: deploy rules Fase 2 ke geuralunas-dev.

## Fase 0 — Perencanaan (dokumen)

- [x] Brainstorming kebutuhan dan scope
- [x] `docs/PRD.md`
- [x] `docs/ARCHITECTURE.md`
- [x] `docs/DATABASE.md`
- [x] `docs/UI-UX.md`
- [x] `docs/DIAGRAMS.md` (use case, ERD, arsitektur, sitemap, sequence, state, flowchart)
- [x] `docs/TESTING.md`
- [x] `docs/DECISIONS.md`
- [x] `README.md`, `CLAUDE.md`, `CHANGELOG.md`
- [ ] User mereview dan menyetujui dokumen
- [ ] Putuskan pertanyaan terbuka di PRD (bagian 9): semua sudah diputuskan
- [x] `git init` dan commit dokumen (atas izin user)

## Fase 1 — Fondasi

- [x] Scaffold project Flutter (`vgv-ai-flutter-plugin:create-project`), package `com.geuralunas.app`
- [x] Setup lint `very_good_analysis`, struktur folder sesuai ARCHITECTURE
- [x] Buat project Firebase, daftarkan app Android, pasang `google-services.json`
- [x] Tema Material 3 (light/dark), format rupiah, lokalisasi `id`
- [x] Routing `go_router` dan kerangka navigasi bawah
- [x] Auth: Google Sign-In dan email+password (daftar, masuk, lupa password, keluar) (kode + test; uji di perangkat belum)
- [x] Firestore security rules awal dan test dengan emulator (sudah di-deploy ke geuralunas-dev)
- [x] Onboarding singkat dan layar pengaturan dasar

## Fase 2 — Hutang & pembayaran (US-01 s.d. US-05)

- [x] Domain: `Money`, kalkulasi bunga, generator jadwal cicilan (+ unit test; selesai)
- [ ] Repository dan Bloc hutang (repository + rules selesai; bloc di task layar)
- [x] Layar daftar hutang (filter: aku berutang / piutang, aktif / lunas)
- [x] Form tambah/ubah hutang (pinjol, cicilan, teman)
- [ ] Detail hutang: jadwal, riwayat, progres
- [ ] Catat pembayaran (batch atomik: payment + installment + sisa hutang)
- [ ] Tandai lunas, arsip, hapus

## Fase 3 — Pengingat (US-06, US-07)

- [ ] Izin notifikasi (Android 13+) dan exact alarm
- [ ] Penjadwalan notifikasi lokal dari jadwal cicilan
- [ ] Jadwal ulang saat data berubah dan setelah reboot
- [ ] Pengaturan jam dan hari pengingat
- [ ] Template pesan tagih sopan + bagikan (share)

## Fase 4 — Budget & jatah aman (US-08 s.d. US-11)

- [ ] Kategori default dan kelola kategori
- [ ] Catat pengeluaran (cepat dari beranda)
- [ ] Budget bulanan: pemasukan dan batas per kategori
- [ ] Domain: kalkulasi jatah aman (+ unit test)
- [ ] Beranda: jatah hari ini, sisa minggu/bulan, peringatan
- [ ] Dampak pengeluaran berlebih ke pelunasan

## Fase 5 — Simulasi pelunasan (US-12, US-13)

- [ ] Domain: simulator snowball dan avalanche (+ unit test)
- [ ] Layar simulasi: input dana ekstra per bulan, hasil perbandingan
- [ ] Grafik penurunan hutang

## Fase 6 — Polish & rilis

- [ ] Ekspor CSV hutang, pembayaran, pengeluaran (US-14)
- [ ] Aksesibilitas (label semantik, ukuran sentuh, kontras)
- [ ] Empty state, loading, error state konsisten
- [ ] Green gate: analyze, format, test, coverage
- [ ] Tinjau keamanan (`static-security`), cek lisensi dependensi
- [ ] Ikon, nama app, splash
- [ ] Build rilis, uji di perangkat nyata, siapkan Play Console (deklarasi aplikasi finansial)

## Log selesai

| Tanggal | Tugas |
|---|---|
| 2026-11-09 | Brainstorming dan dokumen perencanaan Fase 0 ditulis |
| 2026-11-09 | `git init` dan commit awal dokumen |
| 2026-11-09 | Keputusan: denda manual, siklus budget pilihan user, ekspor CSV masuk (US-14) |
| 2026-11-09 | `docs/DIAGRAMS.md` dibuat (10 diagram Mermaid) |
| 2026-11-09 | Diagram dirender ke PNG (`docs/diagrams/`) agar tampil di semua penampil Markdown |
| 2026-11-09 | Fase 1 Task 1: scaffold Flutter, lint very_good_analysis, smoke test |
| 2026-11-09 | Fase 1 Task 2: Money dan formatter rupiah/tanggal (12 test) |
| 2026-11-09 | Fase 1 Task 3: tema Material 3, lokalisasi id, helper pumpApp |
| 2026-11-09 | Fase 1 Task 4: go_router + shell navigasi bawah 5 tab (6 widget test) |
| 2026-11-09 | Fase 1 Task 5: project Firebase geuralunas-dev, Auth (Google + email) dan Firestore aktif, google-services.json memuat OAuth client |
| 2026-11-09 | Fase 1 Task 6: logika auth (validator, AuthRepository, AuthBloc, Login/Register/ForgotPassword cubit; 60 test hijau). UI auth di Task 8 |
| 2026-11-09 | Fase 1 Task 7: onboarding 3 slide dengan flag tersimpan (shared_preferences), 69 test hijau |
| 2026-11-09 | Fase 1 Task 8: layar splash/login/daftar/lupa password, redirect berbasis auth+onboarding (102 test hijau). Uji manual di perangkat belum dilakukan; item Auth tetap terbuka sampai tombol keluar (Task 10) |
| 2026-11-09 | Fase 1 Task 9: firestore.rules v2 (profil tervalidasi, subkoleksi hanya pemilik) + 12 test emulator |
| 2026-11-09 | Fase 1 Task 10: profil users/{uid} dibuat saat login pertama (gagal tidak memblokir), layar Pengaturan + keluar dengan konfirmasi, tile Lainnya (110 test hijau) |
| 2026-11-09 | Fase 1 Task 11: gerbang kualitas (analyze bersih, 113 test, coverage domain 100% / bloc 99% / total 93%), ADR-012, CHANGELOG |
| 2026-11-09 | Fase 1 review akhir: perbaikan nama hilang setelah daftar, emit pada cubit tertutup, error Google yang membuat spinner macet (124 test hijau) |
| 2026-11-09 | Fase 1 penutup: rules diperketat (createdAt server, batas panjang) dan di-deploy ke geuralunas-dev; sign-out Google tahan error; splash tak menggantung; test layar HP skala teks 2.0 dan cold start (131 test, 18 test rules) |
| 2026-11-09 | Fase 1 uji manual di emulator Pixel_API34: onboarding, validasi, pesan salah password, daftar → Beranda, nama di Pengaturan, dokumen profil di Firestore, buka ulang tanpa kilasan login (termasuk mode pesawat), keluar dengan konfirmasi, login ulang. Belum: Google Sign-In sukses |
| 2026-11-09 | Fase 2 Task 1: model domain hutang (enum, Debt, Installment, Payment) dan rumus total bayar termasuk anuitas; domain 100% |
| 2026-11-09 | Fase 2 Task 2: generator jadwal cicilan (akhir bulan tidak melorot, sisa pembulatan ke cicilan terakhir, 183 test) |
| 2026-11-09 | Fase 2 Task 3: penerapan dan pembatalan pembayaran (replay dari nol, pembatalan persis seperti sebelum dibayar; domain 100%, 206 test) |
| 2026-11-09 | Fase 2 Task 4: DTO, DebtRepository (WriteBatch, offline-aman), rules debts/installments/payments dengan 35 test emulator, ADR-013 (242 test Flutter) |
| 2026-11-09 | Fase 2 Task 5: daftar hutang (tab Aku berutang/Piutang, filter, total sisa, kartu dengan status+ikon, label semantik) dan komponen bersama (275 test) |
| 2026-11-09 | Fase 2 Task 6: form tambah/ubah hutang dengan pratinjau jadwal, parseAmount, AmountField, planDebt di domain (356 test) |
| 2026-11-09 | Nama final ditetapkan: GeuraLunas (`com.geuralunas.app`), dokumen diperbarui |
