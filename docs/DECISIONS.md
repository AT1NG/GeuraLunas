# DECISIONS — Lunasin

Catatan keputusan (ADR). Tambahkan entri baru di bawah; jangan menghapus entri lama, tandai `Digantikan oleh ADR-xxx`.

Format: **Konteks → Keputusan → Alasan → Konsekuensi**

---

## ADR-001 — Cakupan: semua jenis hutang dalam satu aplikasi
Tanggal: 2026-11-09 · Status: diterima
- **Konteks:** Pengguna punya pinjol, cicilan, dan hutang teman sekaligus.
- **Keputusan:** Satu dashboard untuk semuanya, dengan arah (`owe`/`lent`) dan jenis (`pinjol`/`installment`/`personal`) pada satu model data.
- **Alasan:** Gambaran total hutang dan jatah aman hanya akurat bila semua terhitung.
- **Konsekuensi:** Scope besar; diatasi dengan pembangunan bertahap (ADR-005).

## ADR-002 — Flutter + Firebase, Android dulu
Tanggal: 2026-11-09 · Status: diterima
- **Keputusan:** Flutter untuk klien, Firebase Auth + Cloud Firestore untuk akun dan data. Platform Android dulu; iOS menyusul.
- **Alasan:** Pengguna sudah memakai Flutter dan Firebase (proyek `duluin`); sinkron antar perangkat dan backup tanpa membangun server; pengembangan di Windows hanya bisa build Android.
- **Konsekuensi:** Data finansial berada di cloud (perlu security rules ketat dan kebijakan privasi); butuh internet untuk login pertama; biaya Firebase di skala besar.

## ADR-003 — Login Google dan email+password
Tanggal: 2026-11-09 · Status: diterima
- **Keputusan:** Dukung dua metode lewat Firebase Auth.
- **Konsekuensi:** Perlu alur reset password dan verifikasi email; perlu SHA-1 pada konsol Firebase untuk Google Sign-In.

## ADR-004 — Satu package dengan folder berlapis
Tanggal: 2026-11-09 · Status: diterima
- **Keputusan:** Arsitektur empat lapis (Data, Repository, Bloc, Presentation) plus `domain` Dart murni, dalam satu package Flutter. Bukan monorepo multi-package dulu.
- **Alasan:** Proyek solo; monorepo menambah overhead. Dependensi searah membuat pemecahan ke package mudah nanti.
- **Konsekuensi:** Disiplin impor harus dijaga lewat review dan lint.

## ADR-005 — Pembangunan bertahap per modul
Tanggal: 2026-11-09 · Status: diterima (asumsi dari rekomendasi; user belum menolak)
- **Keputusan:** Fondasi → hutang & pembayaran → pengingat → budget → simulasi → polish.
- **Alasan:** Setiap fase menghasilkan sesuatu yang bisa dipakai dan diuji; bug cepat ketahuan.
- **Konsekuensi:** Integrasi budget ↔ hutang baru utuh di Fase 4.

## ADR-006 — Budget dengan kategori, terhubung ke hutang ("jatah aman")
Tanggal: 2026-11-09 · Status: diterima
- **Konteks:** User meminta pengaturan uang, jatah jajan per minggu/bulan, dan memilih "Budget + kategori".
- **Keputusan:** Budget bulanan dengan pemasukan, batas per kategori opsional, dan angka utama "jatah aman" yang sudah dikurangi cicilan.
- **Alasan:** Pembeda dari pencatat keuangan biasa; menjawab "berapa yang aman kupakai".
- **Konsekuensi:** Cakupan lebih besar dari opsi sederhana; tidak menduplikasi fitur pencatat keuangan lengkap (investasi, laporan) yang ada di `Financial Tracker`.

## ADR-007 — Uang sebagai integer rupiah
Tanggal: 2026-11-09 · Status: diterima
- **Keputusan:** Semua nominal `int` rupiah utuh; pembulatan `round half up` di domain; selisih pembulatan jadwal masuk cicilan terakhir.
- **Alasan:** Hindari galat floating point pada uang.

## ADR-008 — Pengingat lewat notifikasi lokal
Tanggal: 2026-11-09 · Status: diterima
- **Keputusan:** Jadwalkan notifikasi di perangkat (`flutter_local_notifications`), bukan push dari server.
- **Alasan:** Tanpa server/biaya, berfungsi offline, cukup untuk jatuh tempo yang diketahui di muka.
- **Konsekuensi:** Rentan terhadap penghemat baterai vendor; mitigasi: jadwal ulang saat aplikasi dibuka, panduan pengecualian baterai.

## ADR-009 — Piutang tidak dihitung sebagai pemasukan
Tanggal: 2026-11-09 · Status: diterima
- **Keputusan:** Jatah aman hanya memakai pemasukan yang diisi pengguna; uang dari penagihan piutang dicatat sebagai pemasukan manual ketika diterima.
- **Alasan:** Konservatif; piutang tidak pasti tertagih.
