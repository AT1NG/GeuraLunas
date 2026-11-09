# DECISIONS — GeuraLunas

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

## ADR-010 — Nama aplikasi: GeuraLunas
Tanggal: 2026-11-09 · Status: diterima
- **Keputusan:** Nama final GeuraLunas (menggantikan nama kerja "Lunasin"), package `com.geuralunas.app`, repo `AT1NG/GeuraLunas`, project Firebase `geuralunas-dev` / `geuralunas-prod`.
- **Konsekuensi:** Folder lokal `D:\Project\Lunasin` belum diganti nama.

## ADR-011 — Denda manual, siklus budget pilihan pengguna, ekspor CSV masuk
Tanggal: 2026-11-09 · Status: diterima
- **Keputusan:** (1) Denda keterlambatan tidak dihitung otomatis; pengguna mencatat dan menyesuaikan hutangnya sendiri. (2) Pengguna memilih tanggal mulai siklus budget (1–28). (3) Ekspor CSV masuk versi 1 (US-14, Fase 6).
- **Alasan:** Aturan denda tiap pinjol berbeda-beda; fokus aplikasi adalah pencatatan oleh pengguna. Siklus mengikuti tanggal gajian masing-masing.
- **Konsekuensi:** Sisa hutang bisa berbeda dari aplikasi pinjol bila ada denda; sediakan penyesuaian sisa manual.

## ADR-012 — Satu lingkungan Firebase di Fase 1, test rules dengan runner JS
Tanggal: 2026-11-09 · Status: diterima
- **Keputusan:** (1) Fase 1 hanya memakai project `geuralunas-dev`; flavor Android `dev`/`prod` dan project `geuralunas-prod` ditunda ke Fase 6 (rilis). (2) Security rules diuji dengan emulator Firestore dan runner JavaScript (`firebase/`, `node:test` + `@firebase/rules-unit-testing`), bukan `flutter test`. (3) Aturan lint `public_member_api_docs` dimatikan karena ini aplikasi, bukan package.
- **Alasan:** Belum ada pengguna nyata, jadi dua lingkungan hanya menambah konfigurasi. Pustaka resmi test rules ada untuk JavaScript; Dart tidak punya padanannya.
- **Konsekuensi:** Mengerjakan rules butuh Node.js dan Java 17+ (emulator). Sebelum rilis, siapkan project prod dan flavor, lalu terapkan ulang `google-services.json` dan rules.

## ADR-013 — Tulis lewat WriteBatch dan jangan menunggu commit di UI
Tanggal: 2026-11-09 · Status: diterima
- **Keputusan:** Repository hutang membaca keadaan terkini dengan `get()`, menghitung hasilnya di `lib/domain`, lalu menulis semua dokumen terkait dalam satu `WriteBatch` (maksimal 450 operasi per batch). Tidak memakai transaksi. Method tulis memulai `commit()` tetapi tidak menunggunya; layar mengikuti stream lokal, dan penulisan yang ditolak server dilaporkan lewat `DebtRepository.writeErrors`.
- **Alasan:** Transaksi Firestore butuh koneksi, sedangkan aplikasi harus bisa dipakai offline. `commit()` baru selesai setelah server menjawab, jadi menunggunya membuat layar macet saat offline.
- **Konsekuensi:** Dua perangkat yang menulis hutang yang sama bersamaan bisa saling menimpa (last write wins); dapat diterima karena satu pengguna per akun. Kegagalan karena rules baru terlihat belakangan lewat `writeErrors`. Menghapus hutang dengan lebih dari 450 dokumen tidak atomik.

## ADR-014 — Piutang tanpa alarm; Tagih lewat berbagi teks
Tanggal: 2026-11-09 · Status: diterima
- **Keputusan:** Hanya hutang "aku berutang" yang punya notifikasi terjadwal. Untuk piutang, aplikasi tidak menjadwalkan apa pun; detail piutang aktif punya tombol Tagih yang membuka teks sopan yang bisa diedit lalu dibagikan lewat share sheet sistem (`share_plus`). Tidak ada yang disimpan ke Firestore setelah berbagi.
- **Alasan:** Pengguna hanya perlu tahu siapa yang berutang kepadanya; alarm untuk menagih terasa mengganggu. Membagikan teks tidak butuh integrasi WhatsApp atau izin tambahan.
- **Konsekuensi:** US-07 berubah dari "pengingat untuk menagih" menjadi "membagikan teks tagih". Tidak ada penanda "sudah ditagih"; daftar piutang untuk ditagih di Beranda menyusul di Fase 4.

## ADR-015 — Alarm tepat dengan cadangan alarm tidak tepat
Tanggal: 2026-11-09 · Status: diterima
- **Keputusan:** Notifikasi dijadwalkan sebagai alarm tepat (`exactAllowWhileIdle`, izin `SCHEDULE_EXACT_ALARM`). Bila izin tidak diberikan, dipakai `inexactAllowWhileIdle` dan Pengaturan menampilkan catatan "Pengingat bisa meleset beberapa menit" dengan tombol ke pengaturan sistem. Zona waktu dibaca dari `settings.timezone` (bawaan `Asia/Jakarta`); `flutter_timezone` tidak dipakai karena zona sudah ada di profil.
- **Alasan:** Pengingat bayar paling berguna bila tepat waktu, tetapi tidak boleh gagal total bila pengguna menolak izin.
- **Konsekuensi:** Google Play membatasi izin ini untuk app non-alarm. Bila ditolak saat rilis, ganti ke alarm tidak tepat saja tanpa mengubah desain lain. Penghemat baterai pabrikan tertentu bisa menunda notifikasi; Pengaturan memuat tipnya.
