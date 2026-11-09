# PRD — Lunasin

Versi 0.1 · 2026-11-09 · Status: draft untuk direview

## 1. Latar belakang

Banyak orang punya beberapa kewajiban sekaligus: pinjol, cicilan paylater/kartu/kendaraan, dan hutang ke teman atau keluarga. Catatannya tersebar di chat, kepala, dan aplikasi masing-masing, sehingga:

- jatuh tempo terlewat dan kena denda,
- tidak tahu total hutang dan sisa yang harus dibayar,
- tidak tahu berapa uang yang aman dipakai sampai gajian,
- piutang ke teman lupa ditagih, atau menagih terasa canggung.

## 2. Tujuan

1. Satu tempat untuk semua hutang dan piutang, dengan sisa dan jatuh tempo yang jelas.
2. Pengguna tidak telat bayar karena ada pengingat.
3. Pengguna tahu "jatah aman" jajan hari ini/minggu ini setelah cicilan diperhitungkan.
4. Pengguna bisa melihat kapan lunas dan strategi pelunasan yang paling hemat.

## 3. Bukan tujuan (versi 1)

- Menawarkan, menyalurkan, atau membandingkan pinjaman.
- Integrasi bank/e-wallet atau membaca SMS/notifikasi otomatis.
- Verifikasi legalitas pinjol (OJK).
- Hutang yang dibagi bersama dua pengguna (sinkron dua akun).
- iOS, web, multi mata uang, monetisasi/iklan.
- Pencatat keuangan lengkap (investasi, tabungan, laporan pajak). Sudah ada proyek `Financial Tracker` terpisah.

## 4. Pengguna

**Persona utama — Rani, 24, karyawan baru.** Punya 2 pinjol kecil, 1 cicilan paylater, dan pinjam uang ke teman kos. Gaji bulanan. Sering lupa tanggal jatuh tempo dan bingung sisa uang sampai gajian. Ingin tidak dihakimi, ingin cepat mencatat.

**Persona kedua — Dimas, 28, freelancer.** Meminjamkan uang ke beberapa teman dan sering lupa siapa yang belum bayar. Canggung menagih.

## 5. Ruang lingkup versi 1 (MVP)

Lima kemampuan inti: catat hutang/piutang, pengingat, catat pembayaran, budget + jatah aman, simulasi pelunasan. Pendekatan bertahap: lihat [TODO.md](../TODO.md).

## 6. User story dan kriteria terima

### Akun
**US-00 Masuk ke aplikasi.** Sebagai pengguna, saya bisa daftar dan masuk dengan Google atau email+password agar data saya tersimpan dan bisa dipulihkan di HP lain.
- Bisa daftar, masuk, keluar, dan reset password via email.
- Data tiap pengguna terpisah dan tidak bisa dibaca pengguna lain.
- Setelah masuk ulang di perangkat lain, semua data muncul.

### Hutang & piutang
**US-01 Tambah hutang.** Saya bisa menambah hutang dengan arah (aku berutang / dia berutang ke aku), jenis (pinjol / cicilan / teman), nama pihak, pokok, bunga (opsional), tenor, jatuh tempo, dan catatan.
- Wajib: arah, jenis, nama pihak, pokok, tanggal mulai.
- Untuk jenis teman, bunga dan tenor boleh kosong (satu jatuh tempo, atau tanpa jatuh tempo).
- Jika ada tenor, jadwal cicilan dibuat otomatis dan bisa diubah per cicilan.
- Total yang harus dibayar dan sisa terhitung otomatis.

**US-02 Lihat daftar hutang.** Saya melihat semua hutang dikelompokkan "Aku berutang" dan "Piutang", dengan sisa, jatuh tempo terdekat, dan penanda terlambat.
- Bisa filter aktif/lunas.
- Total sisa per kelompok ditampilkan di atas.

**US-03 Lihat detail hutang.** Saya melihat jadwal cicilan, riwayat pembayaran, sisa, dan progres lunas.

**US-04 Ubah/hapus/arsip hutang.** Saya bisa mengubah data, mengarsipkan, atau menghapus hutang dengan konfirmasi.

**US-05 Catat pembayaran.** Saya bisa mencatat pembayaran (aku bayar, atau teman membayar ke aku) dengan nominal, tanggal, dan catatan.
- Sisa hutang berkurang; cicilan terkait ditandai lunas/sebagian.
- Pembayaran melebihi sisa ditolak dengan pesan jelas.
- Sisa mencapai 0: hutang otomatis berstatus lunas dan muncul tanda selamat.
- Pembayaran bisa dibatalkan/dihapus, sisa dikembalikan.

### Pengingat
**US-06 Pengingat jatuh tempo.** Saya mendapat notifikasi sebelum cicilan jatuh tempo.
- Default H-3, H-1, dan hari-H jam 09:00; bisa diatur.
- Notifikasi berhenti setelah cicilan dibayar atau hutang lunas.
- Tetap berfungsi tanpa internet dan setelah HP restart.

**US-07 Pengingat tagih teman.** Untuk piutang, saya mendapat pengingat untuk menagih, dan bisa membagikan teks tagih yang sopan lewat aplikasi chat.
- Teks bisa diedit sebelum dibagikan.
- Teks tidak memuat kata kasar/mengancam.

### Budget & jatah aman
**US-08 Atur budget bulanan.** Saya mengisi pemasukan bulan ini, dan opsional batas per kategori.

**US-09 Catat pengeluaran.** Saya mencatat pengeluaran dengan nominal, kategori, tanggal, dan catatan dalam maksimal 3 ketukan dari beranda.
- Ada kategori default dan saya bisa menambah/ubah/arsipkan kategori.

**US-10 Jatah aman.** Beranda menampilkan jatah aman hari ini dan sisa minggu ini/bulan ini.
- Rumus di [DATABASE.md bagian 6](DATABASE.md).
- Cicilan yang jatuh tempo bulan ini sudah dikurangi dari pemasukan.
- Piutang tidak dihitung sebagai pemasukan sebelum benar-benar diterima.

**US-11 Peringatan melebihi jatah.** Jika pengeluaran melampaui jatah, saya melihat dampaknya (misalnya jatah hari berikutnya mengecil) tanpa nada menyalahkan.

### Simulasi
**US-12 Simulasi pelunasan.** Saya memasukkan dana ekstra per bulan dan melihat kapan semua hutang "aku berutang" lunas dan total bunga, untuk metode snowball (terkecil dulu) dan avalanche (bunga tertinggi dulu).
- Hasil kedua metode ditampilkan berdampingan dengan selisih bunga.

**US-13 Grafik penurunan hutang.** Saya melihat grafik sisa hutang dari waktu ke waktu menurut hasil simulasi.

## 7. Kebutuhan fungsional ringkas

| ID | Kebutuhan | Story |
|---|---|---|
| FR-01 | Auth Google dan email+password | US-00 |
| FR-02 | CRUD hutang dengan arah, jenis, bunga, tenor | US-01, 04 |
| FR-03 | Generator jadwal cicilan | US-01 |
| FR-04 | Catat/batal pembayaran atomik | US-05 |
| FR-05 | Penjadwalan notifikasi lokal | US-06, 07 |
| FR-06 | Budget bulanan, kategori, pengeluaran | US-08, 09 |
| FR-07 | Kalkulasi jatah aman | US-10, 11 |
| FR-08 | Simulator snowball/avalanche | US-12, 13 |

## 8. Kebutuhan non-fungsional

- **Offline:** semua baca/tulis berjalan tanpa internet (cache Firestore) dan tersinkron saat online.
- **Keamanan dan privasi:** data per-`uid`, security rules ketat, tanpa log nominal/nama di analitik, tidak ada data yang dibagikan ke pihak ketiga.
- **Akurasi uang:** integer rupiah, pembulatan terdefinisi, tanpa `double`.
- **Performa:** daftar 200 hutang dan 5.000 pengeluaran tetap mulus (60 fps), buka aplikasi < 2 dtk di HP menengah.
- **Aksesibilitas:** label semantik, target sentuh ≥ 48 dp, kontras WCAG AA, skala teks sistem.
- **Bahasa:** Indonesia, format `Rp1.250.000`, tanggal `9 Nov 2026`.
- **Kompatibilitas:** Android sesuai syarat FlutterFire (minSdk ≥ 23).
- **Kepatuhan:** deklarasi Google Play untuk aplikasi finansial; aplikasi tidak menawarkan pinjaman; disclaimer bahwa simulasi bukan nasihat keuangan.

## 9. Pertanyaan terbuka

1. Nama final aplikasi dan package ID.
2. Bunga pinjol: cukup empat model (tanpa bunga, flat per bulan, flat per hari, menurun per bulan) atau perlu denda keterlambatan otomatis? Usulan: denda dicatat manual di versi 1.
3. Siklus budget: mulai tanggal 1, atau mengikuti tanggal gajian? Usulan: pengguna memilih tanggal mulai (1–28).
4. Perlu kunci aplikasi (PIN/biometrik) di versi 1? Usulan: tunda ke versi 2.
5. Perlu ekspor data (CSV)? Usulan: tunda.

## 10. Metrik keberhasilan

- 80% pengguna uji menambah ≥ 1 hutang dalam sesi pertama.
- 0 cicilan terlewat tanpa notifikasi pada uji manual 2 minggu.
- Selisih hasil kalkulasi dengan hitungan manual/Excel = Rp0 pada seluruh kasus uji di TESTING.md.

## 11. Risiko

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Notifikasi dimatikan sistem hemat baterai | Pengingat gagal | Minta izin exact alarm, panduan pengecualian baterai, jadwal ulang saat aplikasi dibuka |
| Rumus bunga pinjol beragam | Sisa tidak cocok dengan aplikasi pinjol | Sisa bisa disesuaikan manual, tampilkan asumsi rumus |
| Data finansial sensitif | Kebocoran | Security rules, tanpa data pribadi berlebih, tinjau keamanan Fase 6 |
| Kebijakan Google Play untuk aplikasi pinjaman | Ditolak | Deklarasi jelas bahwa ini pencatat, bukan pemberi pinjaman |
| Scope besar | Molor | Pendekatan bertahap, tiap fase bisa dipakai sendiri |
