# ARCHITECTURE — GeuraLunas

Versi 0.1 · 2026-11-09

## 1. Gambaran

Aplikasi Flutter satu paket, dengan empat lapisan yang dependensinya searah ke bawah. Logika uang dipisah sebagai Dart murni (`domain`) supaya mudah diuji.

```
Presentation (widget, halaman)
      │ memakai
Business Logic (Bloc/Cubit)
      │ memakai
Repository (kontrak + implementasi, ubah model data ↔ model domain)
      │ memakai
Data (Firebase Auth, Firestore, notifikasi lokal)

Domain (Dart murni: Money, bunga, jadwal, jatah aman, simulator)
  ← dipakai oleh Repository dan Bloc, tidak bergantung pada apa pun
```

Aturan: lapisan atas boleh memakai bawah, tidak sebaliknya. Widget tidak pernah memanggil Firestore. `domain` tidak meng-import Flutter maupun Firebase.

## 2. Teknologi

| Kebutuhan | Pilihan | Catatan |
|---|---|---|
| UI | Flutter, Material 3 | Light dan dark |
| State | `flutter_bloc` + `equatable` | Cubit untuk kasus sederhana |
| Routing | `go_router` | Rute bertipe |
| Auth | `firebase_auth`, `google_sign_in` | Google dan email+password |
| Database | `cloud_firestore` | Persistensi offline bawaan |
| Pengingat | `flutter_local_notifications`, `timezone` | Terjadwal lokal, tanpa server |
| Format | `intl` | Rupiah dan tanggal `id_ID` |
| Berbagi | `share_plus` | Teks tagih lewat share sheet sistem |
| Lint | `very_good_analysis` | |
| Test | `flutter_test`, `bloc_test`, `mocktail`, Firebase Emulator | Lihat TESTING.md |

Daftar ini kandidat; versi dikunci saat Fase 1.

## 3. Struktur folder

```
lib/
  main.dart
  bootstrap.dart              # init Firebase, DI, observer
  app/
    app.dart                  # MaterialApp.router, tema
    router.dart               # go_router
    theme/                    # ThemeData, ColorScheme, spacing
  l10n/                       # arb (id)
  domain/                     # Dart murni, tanpa Flutter/Firebase
    money.dart                # Money(int rupiah)
    debt/                     # entitas Debt, Installment, Payment + enum
    interest/                 # kalkulator bunga
    schedule/                 # generator jadwal cicilan
    budget/                   # kalkulator jatah aman
    simulation/               # snowball, avalanche
  data/                       # akses sumber data mentah
    auth_data_source.dart
    firestore_paths.dart
    debt_dto.dart             # model Firestore ↔ Map
    notification_data_source.dart
  repositories/               # kontrak (abstract) + implementasi
    auth_repository.dart
    debt_repository.dart
    budget_repository.dart
    reminder_repository.dart
  features/                   # satu folder per fitur: bloc + view
    auth/ onboarding/ home/ debts/ payments/ budget/ simulation/ settings/
      bloc/  view/  widgets/
  shared/                     # widget dan util lintas fitur
test/                         # cermin struktur lib/
firestore.rules
firestore.indexes.json
```

Keputusan: satu package dengan folder berlapis dulu, bukan monorepo multi-package. Bisa dipecah jadi package nanti karena dependensi sudah searah (ADR-004).

## 4. Alur data utama

### 4.1 Catat pembayaran (FR-04)

```
PaymentForm → DebtDetailBloc.add(PaymentRecorded)
  → DebtRepository.recordPayment(debtId, amount, date, installmentSeq?)
     → validasi domain (tidak melebihi sisa)
     → Firestore WriteBatch (bukan transaksi, agar jalan offline; lihat ADR-013), atomik:
         1. buat payments/{id}
         2. update installments/{seq}.paidAmount & status
         3. update debts/{id}: remaining, nextDueDate, status
  → stream debts memancarkan data baru → Bloc → UI
  → ReminderRepository.reschedule(debtId)
```

### 4.2 Jatah aman (FR-07)

Beranda mendengarkan tiga stream (budget bulan ini, cicilan jatuh tempo bulan ini, pengeluaran bulan ini). `HomeBloc` menggabungkan, lalu memanggil `SafeToSpendCalculator` (domain) untuk menghasilkan angka. Rumus ada di DATABASE.md bagian 6.

### 4.3 Pengingat (FR-05)

- Sumber kebenaran adalah data cicilan di Firestore. Hanya hutang `owe` berstatus aktif yang dijadwalkan (ADR-014).
- `planReminders` (domain, Dart murni) menghitung rencana: satu notifikasi per cicilan belum lunas per hari di `reminderDaysBefore`, pada `reminderTime`, dalam 60 hari ke depan dan maksimal 200. Cicilan sebagian memakai sisa.
- `ReminderRepository.rescheduleAll()` membaca hutang, cicilan, dan pengaturan, memanggil `planReminders`, lalu `cancelAll()` dan menjadwalkan ulang lewat `NotificationDataSource`. Berjalan dalam antrean serial dan tidak pernah melempar; kegagalan dicatat tanpa nama atau nominal.
- `ReminderCoordinator` (lapisan app) memicunya setelah login, pada setiap perubahan daftar hutang (debounce 500 ms), saat app kembali ke latar depan, dan memanggil `cancelAll()` saat keluar akun. Setelah reboot, receiver bawaan plugin yang menjadwalkan ulang.
- Izin: `POST_NOTIFICATIONS` (Android 13+) diminta sekali, setelah pengingat pertama ada. `SCHEDULE_EXACT_ALARM` (Android 12+): bila tidak diberikan, pakai alarm tidak tepat dan Pengaturan memberi tahu pengguna (ADR-015).
- ID notifikasi `(fnv1a32(debtId) % 500000) * 4096 + seq * 8 + n` (n = hari sebelum jatuh tempo): stabil antar proses dan di bawah 2^31, sehingga pembatalan dan penjadwalan ulang idempoten.
- Tap notifikasi membuka `/debts/{id}`. Teks notifikasi dan teks tagih dibuat dari l10n (`lib/shared/reminder_text.dart`, `lib/features/debts/collection_message.dart`), bukan di `lib/domain`, karena memakai l10n dan format rupiah.

## 5. Penanganan error

- Repository melempar exception bertipe (`AuthFailure`, `NetworkFailure`, `ValidationFailure`, `NotFoundFailure`); Bloc mengubahnya menjadi state error dengan pesan Indonesia yang suportif.
- Penulisan offline dianggap berhasil (antrean Firestore); UI menampilkan indikator "belum tersinkron" bila ada pending writes.
- Kesalahan tak terduga ditangkap di `bootstrap.dart` (`FlutterError.onError`, `runZonedGuarded`); log tidak memuat nominal atau nama pihak.

## 6. Keamanan

- Security rules: hanya pemilik (`request.auth.uid == uid`) yang bisa baca/tulis dokumen di bawah `users/{uid}`; validasi tipe dan batas nilai dasar.
- Tidak ada kunci rahasia di repo; `google-services.json` boleh masuk repo privat tapi diperlakukan sebagai konfigurasi, bukan rahasia. Pembatasan lewat SHA-1/aplikasi di konsol Firebase.
- Hapus akun harus menghapus seluruh data pengguna (ditambahkan di Fase 6).

## 7. Observabilitas

Versi 1: tanpa analitik pihak ketiga. Crash reporting (Firebase Crashlytics) dipertimbangkan di Fase 6 dengan data sensitif disaring.

## 8. Build dan lingkungan

- Dev: project Firebase `geuralunas-dev`, emulator untuk test rules.
- Prod: project Firebase `geuralunas-prod`.
- Flavor Android `dev` dan `prod`: ditunda ke Fase 6 (lihat ADR-012). Fase 1 memakai satu project, `geuralunas-dev`.
- CI (opsional, Fase 6): `flutter analyze`, `flutter test`, format check.
