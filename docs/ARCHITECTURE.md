# ARCHITECTURE — Lunasin

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
| Pengingat | `flutter_local_notifications`, `timezone`, `flutter_timezone` | Terjadwal lokal, tanpa server |
| Format | `intl` | Rupiah dan tanggal `id_ID` |
| Berbagi | `share_plus` | Teks tagih |
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
     → Firestore WriteBatch/transaction, atomik:
         1. buat payments/{id}
         2. update installments/{seq}.paidAmount & status
         3. update debts/{id}: remaining, nextDueDate, status
  → stream debts memancarkan data baru → Bloc → UI
  → ReminderRepository.reschedule(debtId)
```

### 4.2 Jatah aman (FR-07)

Beranda mendengarkan tiga stream (budget bulan ini, cicilan jatuh tempo bulan ini, pengeluaran bulan ini). `HomeBloc` menggabungkan, lalu memanggil `SafeToSpendCalculator` (domain) untuk menghasilkan angka. Rumus ada di DATABASE.md bagian 6.

### 4.3 Pengingat (FR-05)

- Sumber kebenaran adalah data cicilan di Firestore.
- `ReminderRepository.rescheduleAll()` membatalkan semua notifikasi terjadwal lalu menjadwalkan ulang dari cicilan belum lunas dengan jatuh tempo di masa depan (H-n sesuai pengaturan).
- Dipanggil: setelah login, setiap perubahan hutang/pembayaran, saat aplikasi dibuka, dan setelah boot (receiver bawaan plugin).
- Android 13+: izin `POST_NOTIFICATIONS`. Android 12+: `SCHEDULE_EXACT_ALARM`; jika ditolak, pakai alarm tidak tepat dan beri tahu pengguna.
- ID notifikasi deterministik dari `debtId + seq + offset` agar pembatalan/penjadwalan ulang idempoten.

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

- Dev: project Firebase `lunasin-dev`, emulator untuk test rules.
- Prod: project Firebase `lunasin-prod`.
- Flavor Android `dev` dan `prod`.
- CI (opsional, Fase 6): `flutter analyze`, `flutter test`, format check.
