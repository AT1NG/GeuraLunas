# GeuraLunas

Aplikasi mobile untuk mengatur hutang dan piutang (pinjol, cicilan, hutang ke/dari teman) sekaligus menjaga jatah jajan harian dan mingguan agar pelunasan tetap aman.

**Status:** Fase 1 (fondasi: navigasi, login, onboarding, pengaturan, rules) selesai di sisi kode. Fase 2 (hutang dan pembayaran) berikutnya. Lihat [TODO.md](TODO.md).

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

## Menjalankan

Prasyarat: Flutter 3.41+ (Dart 3.11+), Android SDK dengan lisensi diterima (`flutter doctor --android-licenses`), emulator atau HP Android.

```
flutter pub get
flutter run
flutter analyze
flutter test
(cd firebase && npm install && npm test)   # test security rules, butuh Java 17+
```

### Setup Firebase (sekali saja)

1. Buat project Firebase `geuralunas-dev` (`firebase projects:create geuralunas-dev`).
2. Di console: Authentication, aktifkan **Google** dan **Email/Password**; buat database **Firestore** (production, lokasi `asia-southeast2`).
3. `dart pub global activate flutterfire_cli`, lalu `flutterfire configure --project=geuralunas-dev --platforms=android --android-package-name=com.geuralunas.app --yes`.
4. Daftarkan SHA-1 debug (untuk Google Sign-In): ambil dengan `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`, lalu `firebase apps:android:sha:create <appId> <sha1> --project geuralunas-dev`. Jalankan `flutterfire configure` lagi agar `google-services.json` memuat klien OAuth.

`android/app/google-services.json` dan `lib/firebase_options.dart` di-commit: keduanya konfigurasi publik, bukan rahasia. Perlindungan data ada di security rules Firestore dan pembatasan API key di console.

Catatan build Windows: `android/gradle.properties` mematikan `kotlin.incremental` karena cache Pub (drive C:) dan project (drive D:) berbeda root.

## Catatan

Simulasi dan perhitungan di aplikasi bersifat alat bantu, bukan nasihat keuangan. GeuraLunas tidak menawarkan pinjaman.
