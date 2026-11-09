# TODO — GeuraLunas

> Aturan: update file ini setiap tugas selesai (centang, isi Log selesai, pindahkan "Sedang dikerjakan"). Lihat [CLAUDE.md](CLAUDE.md).

## Sedang dikerjakan

- Fase 1 Task 2: `Money` dan formatter (lihat docs/superpowers/plans/2026-11-09-phase1-foundation.md).

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
- [ ] Buat project Firebase, daftarkan app Android, pasang `google-services.json`
- [ ] Tema Material 3 (light/dark), format rupiah, lokalisasi `id`
- [ ] Routing `go_router` dan kerangka navigasi bawah
- [ ] Auth: Google Sign-In dan email+password (daftar, masuk, lupa password, keluar)
- [ ] Firestore security rules awal dan test dengan emulator
- [ ] Onboarding singkat dan layar pengaturan dasar

## Fase 2 — Hutang & pembayaran (US-01 s.d. US-05)

- [ ] Domain: `Money`, kalkulasi bunga, generator jadwal cicilan (+ unit test)
- [ ] Repository dan Bloc hutang
- [ ] Layar daftar hutang (filter: aku berutang / piutang, aktif / lunas)
- [ ] Form tambah/ubah hutang (pinjol, cicilan, teman)
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
| 2026-11-09 | Nama final ditetapkan: GeuraLunas (`com.geuralunas.app`), dokumen diperbarui |
