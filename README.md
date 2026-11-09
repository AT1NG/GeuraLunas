# GeuraLunas

Aplikasi mobile untuk mengatur hutang dan piutang (pinjol, cicilan, hutang ke/dari teman) sekaligus menjaga jatah jajan harian dan mingguan agar pelunasan tetap aman.

**Status:** tahap perencanaan selesai (dokumen), implementasi belum dimulai. Lihat [TODO.md](TODO.md).

## Fitur versi pertama

- Catat hutang dan piutang: pinjol, cicilan, dan hutang teman.
- Pengingat jatuh tempo, dan pengingat sopan untuk menagih teman.
- Catat pembayaran, sisa hutang dan progres lunas.
- Budget bulanan dengan kategori, plus "jatah aman" per hari/minggu yang sudah dikurangi cicilan.
- Simulasi pelunasan (snowball dan avalanche).

## Teknologi

Flutter (Android dulu), Firebase Auth (Google + email), Cloud Firestore, notifikasi lokal. Detail di [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Dokumentasi

| Dokumen | Isi |
|---|---|
| [CLAUDE.md](CLAUDE.md) | Aturan kerja untuk Claude dan rujukan semua dokumen |
| [TODO.md](TODO.md) | Rencana dan status tugas |
| [docs/PRD.md](docs/PRD.md) | Kebutuhan produk |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Arsitektur |
| [docs/DATABASE.md](docs/DATABASE.md) | Skema database |
| [docs/DIAGRAMS.md](docs/DIAGRAMS.md) | ERD, use case, sequence, state, flowchart |
| [docs/UI-UX.md](docs/UI-UX.md) | Desain dan alur layar |
| [docs/TESTING.md](docs/TESTING.md) | Strategi pengujian |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Keputusan teknis |
| [CHANGELOG.md](CHANGELOG.md) | Riwayat perubahan |

## Menjalankan (setelah Fase 1)

Langkah akan diisi saat scaffold project dibuat. Prasyarat yang sudah pasti: Flutter SDK, Android Studio/emulator, project Firebase, dan `google-services.json`.

## Catatan

Simulasi dan perhitungan di aplikasi bersifat alat bantu, bukan nasihat keuangan. GeuraLunas tidak menawarkan pinjaman.
