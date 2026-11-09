# CLAUDE.md — Panduan untuk Claude di proyek GeuraLunas

GeuraLunas adalah aplikasi mobile (Flutter + Firebase, Android dulu) untuk mengatur hutang dan piutang: pinjol, cicilan, dan pinjaman antar teman. Aplikasi juga membantu mengatur jatah jajan harian/mingguan supaya aman dari sisi pelunasan.

## Dokumen rujukan (sumber kebenaran)

Baca dokumen yang relevan sebelum mengerjakan tugas. Kalau kode dan dokumen bertentangan, hentikan pekerjaan, tanyakan ke user, lalu perbarui yang salah.

| Dokumen | Isi | Kapan dibaca |
|---|---|---|
| [README.md](README.md) | Gambaran proyek, cara menjalankan | Awal sesi |
| [TODO.md](TODO.md) | Daftar tugas per fase, status | Setiap awal dan akhir tugas |
| [docs/PRD.md](docs/PRD.md) | Kebutuhan produk, user story, kriteria terima | Sebelum membuat atau mengubah fitur |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layer, struktur folder, alur data, dependensi | Sebelum menambah file atau package |
| [docs/DATABASE.md](docs/DATABASE.md) | Skema Firestore, index, security rules, rumus turunan | Sebelum menyentuh data |
| [docs/UI-UX.md](docs/UI-UX.md) | Peta layar, alur, gaya bahasa, desain | Sebelum membuat UI |
| [docs/TESTING.md](docs/TESTING.md) | Strategi test, target coverage | Sebelum menulis test |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Catatan keputusan (ADR) dan alasannya | Sebelum mengubah keputusan teknis |
| [CHANGELOG.md](CHANGELOG.md) | Riwayat perubahan per rilis | Saat rilis |

## Aturan wajib

1. **Update `TODO.md` setiap tugas selesai.** Centang item, isi tanggal di bagian "Log selesai", dan pindahkan "Sedang dikerjakan" ke tugas berikutnya. Jangan menutup sesi dengan `TODO.md` yang basi.
2. **Dokumen mengikuti keputusan.** Kalau keputusan berubah (skema data, arsitektur, scope), perbarui dokumen terkait dalam perubahan yang sama dan tambah entri di `docs/DECISIONS.md`.
3. **Tidak ada kode fitur tanpa user story.** Setiap fitur harus ada ID di `docs/PRD.md` (contoh `US-03`). Sebut ID itu di commit/PR.
4. **Test dulu untuk logika uang.** Perhitungan bunga, jadwal cicilan, sisa hutang, jatah aman, dan simulasi wajib punya unit test sebelum dipakai di UI.
5. **Jangan menyimpan uang sebagai `double`.** Semua nominal rupiah adalah `int` (rupiah utuh). Lihat `docs/DATABASE.md`.
6. **Satu tugas selesai = terverifikasi.** Jalankan `flutter analyze` dan `flutter test` dan lihat hasilnya sebelum menyatakan selesai.
7. **Commit dan push hanya atas permintaan user.**

## Konvensi

- Bahasa UI: Indonesia. Nama kode, komentar kode, dan nama commit: Inggris.
- Nada teks di UI: suportif, tidak menghakimi (lihat `docs/UI-UX.md`).
- Arsitektur berlapis dan state management memakai Bloc (lihat `docs/ARCHITECTURE.md`).
- Lint: `very_good_analysis`.

## Alur kerja per tugas

1. Ambil tugas teratas yang belum dicentang di `TODO.md`, tandai sebagai "Sedang dikerjakan".
2. Baca dokumen rujukan yang relevan.
3. Tulis test, lalu implementasi.
4. Verifikasi (`flutter analyze`, `flutter test`).
5. Update `TODO.md` dan dokumen yang terdampak.

## Skill yang berguna (plugin terpasang)

`vgv-ai-flutter-plugin:bloc`, `:layered-architecture`, `:navigation`, `:material-theming`, `:testing`, `:internationalization`, `:accessibility`, `:static-security`, `:green-gate`; `superpowers:test-driven-development`, `:verification-before-completion`, `:systematic-debugging`.
