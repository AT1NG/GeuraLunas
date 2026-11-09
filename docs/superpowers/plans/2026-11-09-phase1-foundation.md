# Fase 1 — Fondasi: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aplikasi Flutter Android yang bisa dijalankan, punya tema, navigasi bawah, onboarding, login (Google + email), pengaturan dasar, dan aturan keamanan Firestore yang teruji.

**Architecture:** Satu package Flutter dengan lapisan Data → Repository → Bloc → Presentation plus `domain` Dart murni (lihat `docs/ARCHITECTURE.md`). Auth lewat Firebase Auth; profil pengguna di `users/{uid}` Firestore. Routing `go_router` dengan redirect berdasar status auth dan status onboarding.

**Tech Stack:** Flutter 3.41.7 / Dart 3.11.5, `flutter_bloc`, `go_router`, `firebase_core`, `firebase_auth`, `google_sign_in`, `cloud_firestore`, `intl`, `shared_preferences`, `very_good_analysis`, `bloc_test`, `mocktail`; Firebase Emulator + `@firebase/rules-unit-testing` untuk rules.

**Spec:** `docs/PRD.md` (US-00), `docs/ARCHITECTURE.md`, `docs/DATABASE.md` (3.1, 5), `docs/UI-UX.md`, `docs/TESTING.md`, `docs/DECISIONS.md`, `docs/DIAGRAMS.md` (sitemap, arsitektur).

## Global Constraints

- Flutter stable 3.41.7, Dart 3.11.5; platform Android saja; `applicationId` dan `namespace` = `com.geuralunas.app`; minSdk = nilai terbesar antara 23 dan default Flutter.
- Lint `very_good_analysis`; `flutter analyze` harus 0 isu sebelum tiap commit.
- Bahasa UI Indonesia lewat ARB (`lib/l10n/app_id.arb`), tanpa string UI hardcoded di widget. Nama kode, komentar, pesan commit: Inggris.
- Tidak ada warna, ukuran font, atau jarak hardcoded di widget; semua dari `ThemeData`/`Spacing`. Satu-satunya warna literal adalah seed di `lib/app/theme/app_theme.dart`.
- Uang = `int` rupiah (`Money`), tidak pernah `double`.
- Widget tidak memanggil Firebase/Firestore langsung; urutan dependensi searah (Presentation → Bloc → Repository → Data). `lib/domain` tidak meng-import Flutter maupun Firebase.
- Format: `Rp1.250.000`, tanggal `9 Nov 2026` (locale `id_ID`).
- Password minimal 8 karakter; email dinormalisasi (`trim` + huruf kecil) sebelum dikirim ke Firebase.
- Setelah tiap task: centang item terkait di `TODO.md` dan isi Log selesai (aturan CLAUDE.md). Langkah commit hanya dijalankan karena user menyetujui eksekusi rencana ini; jangan `push` kecuali diminta.
- Hanya satu lingkungan Firebase (`geuralunas-dev`) di Fase 1. Flavor `dev`/`prod` ditunda ke Fase 6 (menyimpang dari `ARCHITECTURE.md` bagian 8; diperbarui di Task 11).

## Review Focus

1. Login Google dibatalkan pengguna (tutup dialog) harus kembali ke form tanpa pesan error. *(Task 6, 8)*
2. Email dengan spasi di awal/akhir atau huruf besar (` Rani@Mail.COM `) harus tetap bisa masuk/daftar. *(Task 6, 8)*
3. Buka aplikasi dingin saat sudah login (termasuk offline): tidak boleh sempat menampilkan layar login; tampil splash sampai status auth diketahui. *(Task 8)*
4. Layar login/daftar dengan skala teks sistem 2.0 tidak overflow dan tetap bisa di-scroll. *(Task 8)*
5. `Money` negatif, nol, dan sangat besar (`Rp999.999.999.999`) diformat benar. *(Task 2)*

---

## File Structure

```
pubspec.yaml, analysis_options.yaml, l10n.yaml
android/app/google-services.json                  (Task 5)
firebase.json, firestore.rules, firestore.indexes.json   (Task 9)
firebase/test/rules.test.js, firebase/package.json       (Task 9)
lib/
  main.dart                      # runApp(await bootstrap())
  bootstrap.dart                 # init Firebase, bangun dependensi
  firebase_options.dart          # hasil flutterfire configure
  app/app.dart                   # MaterialApp.router + providers
  app/router.dart                # createRouter(...)
  app/router_redirect.dart       # resolveRedirect(...) murni
  app/theme/app_theme.dart, spacing.dart
  l10n/app_id.arb, l10n.dart, gen/…
  domain/money.dart
  domain/auth/app_user.dart
  shared/formatters/rupiah.dart  # formatRupiah, formatDate
  shared/validators.dart         # validateEmail, validatePassword, validateName
  data/auth_data_source.dart
  data/user_profile_data_source.dart
  repositories/auth_repository.dart, auth_failure.dart
  repositories/user_profile_repository.dart
  repositories/onboarding_repository.dart
  features/auth/bloc/{auth_bloc,login_cubit,register_cubit,forgot_password_cubit}.dart
  features/auth/view/{splash_page,login_page,register_page,forgot_password_page}.dart
  features/onboarding/{bloc/onboarding_cubit.dart,view/onboarding_page.dart}
  features/shell/{app_shell.dart,add_menu_sheet.dart}
  features/home|debts|budget|more/view/*_page.dart   # placeholder, kecuali more
  features/settings/view/settings_page.dart
test/…  (cermin lib/) + test/helpers/pump_app.dart
```

---

### Task 1: Scaffold project, lint, dan smoke test

**Files:**
- Create: seluruh proyek Flutter di root repo (`flutter create`), `lib/main.dart`, `lib/bootstrap.dart`, `lib/app/app.dart`, `test/app/app_test.dart`
- Modify: `pubspec.yaml`, `analysis_options.yaml`, `android/app/build.gradle.kts`, `README.md`

**Interfaces:**
- Produces: `Future<Widget> bootstrap()` (di `bootstrap.dart`, sementara hanya `WidgetsFlutterBinding.ensureInitialized()` lalu `const App()`), `class App extends StatelessWidget` (`lib/app/app.dart`).

- [ ] **Step 1 (manual — user): terima lisensi Android SDK.** Jalankan `! flutter doctor --android-licenses`. Verifikasi: `flutter doctor` menampilkan `[✓] Android toolchain`.
- [ ] **Step 2: scaffold.** Dari root repo: `flutter create . --org com.geuralunas --project-name geuralunas --platforms android --empty`. Jangan menimpa `README.md`, `CLAUDE.md`, `docs/` (jika `flutter create` mengubah `README.md`/`.gitignore`, kembalikan README dan gabungkan `.gitignore`).
- [ ] **Step 3: set `applicationId` dan `namespace` ke `com.geuralunas.app`** di `android/app/build.gradle.kts`; pindahkan `MainActivity` ke package `com.geuralunas.app` (path `android/app/src/main/kotlin/com/geuralunas/app/`). Set `minSdk = maxOf(23, flutter.minSdkVersion)`.
- [ ] **Step 4: dependensi.** `flutter pub add flutter_bloc equatable go_router intl shared_preferences` lalu `flutter pub add flutter_localizations --sdk=flutter` dan `flutter pub add --dev very_good_analysis bloc_test mocktail`. Firebase ditambahkan di Task 5.
- [ ] **Step 5: lint.** `analysis_options.yaml` berisi `include: package:very_good_analysis/analysis_options.yaml`; kecualikan `lib/l10n/gen/**` dan `lib/firebase_options.dart` dari analisis.
- [ ] **Step 6: tulis test gagal.** `test/app/app_test.dart`: `testWidgets('App builds a MaterialApp', …)` — pump `const App()`, `expect(find.byType(MaterialApp), findsOneWidget)`.
- [ ] **Step 7: jalankan** `flutter test test/app/app_test.dart` → FAIL (`App` belum ada).
- [ ] **Step 8: implementasi** `App` (`MaterialApp` dengan `home: Scaffold(body: Center(child: Text('GeuraLunas')))` — sementara), `bootstrap()`, dan `main.dart` (`runApp(await bootstrap())`). Teks sementara akan diganti Task 3.
- [ ] **Step 9: verifikasi.** `flutter analyze` → `No issues found!`; `flutter test` → semua lulus; `flutter build apk --debug` → sukses.
- [ ] **Step 10: ubah bagian "Menjalankan" di `README.md`** (`flutter pub get`, `flutter run`), centang item scaffold & lint di `TODO.md`.
- [ ] **Step 11: commit** `chore: scaffold flutter project with very_good_analysis`.

---

### Task 2: `Money` dan formatter rupiah/tanggal

**Files:**
- Create: `lib/domain/money.dart`, `lib/shared/formatters/rupiah.dart`, `test/domain/money_test.dart`, `test/shared/formatters/rupiah_test.dart`

**Interfaces:**
- Produces:
  - `final class Money implements Comparable<Money>` — `const Money(int rupiah)`, `static const Money zero`, `final int rupiah`, `Money operator +(Money other)`, `Money operator -(Money other)`, `Money operator -()`, `bool get isNegative`, `bool get isZero`, `int compareTo(Money other)`, `==`/`hashCode` berdasar `rupiah`.
  - `String formatRupiah(Money value)`; `String formatDate(DateTime date)`; `Future<void> initializeFormatting()` (memanggil `initializeDateFormatting('id_ID')`).

- [ ] **Step 1: tulis test `Money` (gagal).** Nama dan assertion: `adds` — `Money(100) + Money(50) == Money(150)`; `subtracts to negative` — `(Money(10) - Money(30)).isNegative`; `negation` — `-Money(5) == Money(-5)`; `zero is zero` — `Money.zero.isZero`; `equality by value` — `Money(7) == Money(7)` dan hash sama; `compares` — `Money(1).compareTo(Money(2)) < 0`.
- [ ] **Step 2: tulis test formatter (gagal).** `setUpAll(initializeFormatting)`. `formatRupiah(Money(1250000)) == 'Rp1.250.000'`; `Money(0) → 'Rp0'`; `Money(950) → 'Rp950'`; `Money(-1000) → '-Rp1.000'`; `Money(999999999999) → 'Rp999.999.999.999'`; `formatDate(DateTime(2026, 11, 9)) == '9 Nov 2026'`.
- [ ] **Step 3: jalankan** `flutter test test/domain test/shared` → FAIL.
- [ ] **Step 4: implementasi `Money`** (kelas `final`, `const`, tanpa import Flutter).
- [ ] **Step 5: implementasi formatter** dengan `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)`; pastikan tanpa spasi setelah `Rp` dan tanda minus di depan `Rp` (sesuaikan hasil `NumberFormat` bila perlu).
- [ ] **Step 6: jalankan** test yang sama → PASS; `flutter analyze` bersih.
- [ ] **Step 7: commit** `feat(domain): add Money and rupiah/date formatters`.

---

### Task 3: Tema Material 3, lokalisasi, dan helper test

**Files:**
- Create: `lib/app/theme/app_theme.dart`, `lib/app/theme/spacing.dart`, `l10n.yaml`, `lib/l10n/app_id.arb`, `lib/l10n/l10n.dart`, `test/helpers/pump_app.dart`, `test/app/theme_test.dart`
- Modify: `lib/app/app.dart`, `lib/bootstrap.dart`, `pubspec.yaml` (`flutter: generate: true`)

**Interfaces:**
- Produces: `abstract final class AppTheme { static ThemeData light(); static ThemeData dark(); }`; `abstract final class Spacing { static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32; }`; `extension L10nX on BuildContext { AppLocalizations get l10n }`; `Future<void> pumpApp(WidgetTester tester, Widget child, {List<BlocProvider> providers = const []})` membungkus `MaterialApp` dengan tema, delegates, `supportedLocales: [Locale('id')]`.
- Kunci ARB awal: `appName`, `navHome`, `navDebts`, `navBudget`, `navMore`, `addMenuExpense`, `addMenuPayment`, `addMenuDebt`.

- [ ] **Step 1: test gagal** `test/app/theme_test.dart`: `light theme uses material3 and light brightness` (`AppTheme.light().useMaterial3`, `.colorScheme.brightness == Brightness.light`); `dark theme is dark`; `text theme has bodyMedium`.
- [ ] **Step 2: jalankan** → FAIL.
- [ ] **Step 3: implementasi `AppTheme`** dengan `ColorScheme.fromSeed(seedColor: Color(0xFF1B7F6B), brightness: …)`; `NavigationBarTheme`, `InputDecorationTheme` (outline), `FilledButtonTheme` didefinisikan di sini agar widget tidak styling sendiri. Implementasi `Spacing`.
- [ ] **Step 3b: lokalisasi.** `l10n.yaml`: `arb-dir: lib/l10n`, `template-arb-file: app_id.arb`, `output-dir: lib/l10n/gen`, `output-localization-file: app_localizations.dart`, `synthetic-package: false`. Isi ARB dengan kunci di atas; jalankan `flutter gen-l10n`.
- [ ] **Step 4: `App`** memakai `AppTheme.light()/dark()`, `themeMode: ThemeMode.system`, delegates dan `supportedLocales`, `onGenerateTitle: (c) => c.l10n.appName`; `bootstrap()` memanggil `initializeFormatting()`.
- [ ] **Step 5: `pump_app.dart`** helper; perbarui `test/app/app_test.dart` agar tetap lulus.
- [ ] **Step 6: verifikasi** `flutter test` hijau, `flutter analyze` bersih.
- [ ] **Step 7: commit** `feat(app): add Material 3 theme and Indonesian localization`.

---

### Task 4: Router dan shell navigasi bawah

**Files:**
- Create: `lib/app/router.dart`, `lib/features/shell/app_shell.dart`, `lib/features/shell/add_menu_sheet.dart`, `lib/features/{home,debts,budget,more}/view/{home,debts,budget,more}_page.dart`, `test/features/shell/app_shell_test.dart`
- Modify: `lib/app/app.dart` (pakai `MaterialApp.router`)

**Interfaces:**
- Produces: `GoRouter createRouter({String initialLocation = '/home', Listenable? refreshListenable, GoRouterRedirect? redirect})`; nama rute dan path: `/home`, `/debts`, `/budget`, `/more` (4 cabang `StatefulShellRoute.indexedStack`). `AppShell({required StatefulNavigationShell navigationShell})`: `NavigationBar` 5 tujuan (Beranda, Hutang, **+**, Budget, Lainnya); indeks tab 2 tidak punya cabang, hanya memanggil `showAddMenu(context)`; pemetaan indeks UI→cabang: 0→0, 1→1, 3→2, 4→3. `Future<void> showAddMenu(BuildContext)` menampilkan bottom sheet 3 item (`addMenuExpense`, `addMenuPayment`, `addMenuDebt`) yang sementara hanya menutup sheet.

- [ ] **Step 1: test gagal** `app_shell_test.dart` (pump `MaterialApp.router(routerConfig: createRouter())`): `shows five destinations` (label Beranda, Hutang, Budget, Lainnya + ikon tambah); `tapping Hutang shows debts page` (`find.byKey(const Key('debts-page'))`); `tapping add opens the three-item menu` (tiga `ListTile`); `selected tab is kept when add sheet closes` (setelah buka-tutup sheet, tab sebelumnya tetap terpilih).
- [ ] **Step 2: jalankan** → FAIL.
- [ ] **Step 3: implementasi** router, shell, sheet, dan keempat halaman placeholder (masing-masing `Scaffold` + `Key('<nama>-page')` + `AppBar` berjudul dari l10n). Semua teks dari ARB; tambahkan kunci judul halaman baru bila perlu.
- [ ] **Step 4: verifikasi** test PASS, `flutter analyze` bersih; jalankan `flutter run` di emulator dan cek navigasi (manual).
- [ ] **Step 5: centang item routing di `TODO.md`; commit** `feat(nav): add go_router shell with bottom navigation`.

---

### Task 5: Firebase (project, konfigurasi, inisialisasi)

**Files:**
- Create: `android/app/google-services.json`, `lib/firebase_options.dart` (keduanya dihasilkan alat)
- Modify: `pubspec.yaml`, `android/settings.gradle.kts`, `android/app/build.gradle.kts` (plugin google-services, ditambahkan `flutterfire configure`), `lib/bootstrap.dart`, `README.md`

**Interfaces:**
- Produces: `bootstrap()` memanggil `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` sebelum membangun `App`.

Tugas ini sebagian manual karena butuh akun Google user. Kerjakan berurutan dan hentikan bila ada langkah manual yang belum dilakukan.

- [ ] **Step 1 (manual — user): login.** `! firebase login`. Verifikasi: `firebase projects:list` berjalan.
- [ ] **Step 2 (manual — user): buat project** `geuralunas-dev` di console Firebase (atau `firebase projects:create geuralunas-dev`; bila ID dipakai orang lain, pakai ID lain dan catat di `docs/DECISIONS.md`). Aktifkan **Authentication** → Sign-in method: **Google** dan **Email/Password**. Buat **Firestore** mode production, lokasi `asia-southeast2` (Jakarta).
- [ ] **Step 3: pasang flutterfire.** `dart pub global activate flutterfire_cli`; pastikan `flutterfire --version` jalan (tambah `%LOCALAPPDATA%\Pub\Cache\bin` ke PATH bila perlu).
- [ ] **Step 4: tambah paket.** `flutter pub add firebase_core firebase_auth cloud_firestore google_sign_in`.
- [ ] **Step 5: konfigurasi.** `flutterfire configure --project=geuralunas-dev --platforms=android --android-package-name=com.geuralunas.app --yes`. Verifikasi: `lib/firebase_options.dart` dan `android/app/google-services.json` ada.
- [ ] **Step 6 (manual — user): daftarkan SHA-1 debug** untuk Google Sign-In: ambil dengan `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android`, tambahkan di Firebase console → Project settings → app Android → SHA certificate fingerprints. Unduh ulang `google-services.json` jika diminta.
- [ ] **Step 7: inisialisasi** di `bootstrap()`; Firestore persistence default Android sudah aktif (tidak perlu pengaturan).
- [ ] **Step 8: verifikasi.** `flutter analyze` bersih, `flutter test` hijau, `flutter build apk --debug` sukses; `flutter run` di emulator/HP tidak crash dan log tidak memuat error Firebase (manual).
- [ ] **Step 9: catat di `README.md`** langkah setup Firebase singkat (project, provider, SHA-1, `flutterfire configure`); `google-services.json` dan `firebase_options.dart` di-commit (konfigurasi publik; perlindungan dari security rules dan pembatasan API key di console).
- [ ] **Step 10: centang item Firebase di `TODO.md`; commit** `feat(firebase): configure geuralunas-dev and initialize Firebase`.

---

### Task 6: Logika auth (data source, repository, bloc/cubit, validator)

**Files:**
- Create: `lib/domain/auth/app_user.dart`, `lib/data/auth_data_source.dart`, `lib/repositories/auth_failure.dart`, `lib/repositories/auth_repository.dart`, `lib/shared/validators.dart`, `lib/features/auth/bloc/{auth_bloc,login_cubit,register_cubit,forgot_password_cubit}.dart`, serta test cerminnya di `test/…`

**Interfaces:**
- Produces:
  - `final class AppUser extends Equatable { const AppUser({required String uid, required String email, String? displayName}) }`.
  - `sealed class AuthFailure implements Exception` dengan subtipe: `InvalidCredentials`, `InvalidEmail`, `EmailInUse`, `WeakPassword`, `TooManyRequests`, `NetworkFailure`, `AccountExistsWithDifferentCredential`, `UnknownAuthFailure`.
  - `class AuthDataSource` (pembungkus tipis `FirebaseAuth` + `GoogleSignIn`): `Stream<User?> authStateChanges()`, `Future<void> signInWithEmail(String email, String password)`, `Future<void> signUpWithEmail(String email, String password, String displayName)`, `Future<bool> signInWithGoogle()` (mengembalikan `false` bila dibatalkan pengguna), `Future<void> sendPasswordReset(String email)`, `Future<void> signOut()`. Untuk Google Sign-In ikuti README versi `google_sign_in` yang terpasang (API versi 7 memakai `GoogleSignIn.instance.initialize()` dan `authenticate()`).
  - `abstract interface class AuthRepository { Stream<AppUser?> get authStateChanges; Future<void> signInWithEmail({required String email, required String password}); Future<void> signUpWithEmail({required String email, required String password, required String displayName}); Future<bool> signInWithGoogle(); Future<void> sendPasswordReset(String email); Future<void> signOut(); }` dan `AuthRepositoryImpl(AuthDataSource)`: normalisasi email (`trim().toLowerCase()`), mapping `User → AppUser`, mapping `FirebaseAuthException.code → AuthFailure` (`invalid-credential|wrong-password|user-not-found → InvalidCredentials`; `invalid-email → InvalidEmail`; `email-already-in-use → EmailInUse`; `weak-password → WeakPassword`; `too-many-requests → TooManyRequests`; `network-request-failed → NetworkFailure`; `account-exists-with-different-credential → AccountExistsWithDifferentCredential`; lainnya → `UnknownAuthFailure`).
  - `enum ValidationError { required, invalidEmail, passwordTooShort }` dan `ValidationError? validateEmail(String? v)`, `ValidationError? validatePassword(String? v)`, `ValidationError? validateName(String? v)` — `null` berarti valid; UI memetakan `ValidationError` ke teks ARB.
  - `AuthBloc(AuthRepository)`: event `AuthStarted`, `AuthSignOutRequested`; `AuthState({required AuthStatus status, AppUser? user})` dengan `enum AuthStatus { unknown, authenticated, unauthenticated }`; awal `unknown`.
  - `LoginCubit(AuthRepository)`: `emailChanged`, `passwordChanged`, `submit()`, `submitGoogle()`; state memuat `FormzStatus`-setara sendiri: `enum SubmitStatus { idle, submitting, success, failure }` dan `AuthFailure? failure`. `RegisterCubit` dan `ForgotPasswordCubit` analog (`ForgotPasswordCubit` punya status `sent`).

- [ ] **Step 1: test validator (gagal).** `validateEmail('') == ValidationError.required`; `' Rani@Mail.COM '` valid (`null`); `'rani@'` → `invalidEmail`; `validatePassword('1234567') == passwordTooShort`, `'12345678'` → `null`; `validateName('  ') == required`.
- [ ] **Step 2: test repository (gagal)** dengan `mocktail` mock `AuthDataSource`: `normalizes email before sign in` (verify dipanggil dengan `'rani@mail.com'` saat input `' Rani@Mail.COM '`); satu test per baris mapping kode Firebase di atas; `google cancelled returns false and does not throw`; `maps firebase user to AppUser`.
- [ ] **Step 3: test bloc/cubit (gagal)** dengan `bloc_test`: `AuthBloc` — `emits authenticated when stream emits user`, `emits unauthenticated when stream emits null`, `starts as unknown`, `sign out calls repository`. `LoginCubit` — `submit emits [submitting, success]`, `submit failure emits [submitting, failure] with InvalidCredentials`, `invalid email does not call repository`, `google cancelled returns to idle without failure`. `RegisterCubit` — `EmailInUse` menjadi failure; `ForgotPasswordCubit` — `emits [submitting, sent]`.
- [ ] **Step 4: jalankan** `flutter test test/shared test/repositories test/features/auth/bloc` → FAIL.
- [ ] **Step 5: implementasi** validator, `AppUser`, `AuthFailure`, `AuthDataSource`, `AuthRepositoryImpl`, `AuthBloc`, tiga cubit. `AuthBloc` mendengarkan `authStateChanges` via `emit.forEach`.
- [ ] **Step 6: verifikasi** semua test PASS, `flutter analyze` bersih.
- [ ] **Step 7: commit** `feat(auth): add auth repository, bloc, cubits, and validators`.

---

### Task 7: Onboarding

**Files:**
- Create: `lib/repositories/onboarding_repository.dart`, `lib/features/onboarding/bloc/onboarding_cubit.dart`, `lib/features/onboarding/view/onboarding_page.dart`, `test/repositories/onboarding_repository_test.dart`, `test/features/onboarding/onboarding_cubit_test.dart`, `test/features/onboarding/onboarding_page_test.dart`
- Modify: `lib/l10n/app_id.arb`, `pubspec.yaml` (bila perlu)

**Interfaces:**
- Produces: `abstract interface class OnboardingRepository { Future<bool> isSeen(); Future<void> markSeen(); }` + `SharedPrefsOnboardingRepository(SharedPreferences)` (kunci `onboarding_seen`); `OnboardingCubit(OnboardingRepository)` dengan state `OnboardingState({required bool? seen})` (`null` = belum dimuat), method `load()` dan `complete()`; `OnboardingPage({required VoidCallback onFinished})` — 3 slide (catat semua hutang, jangan telat bayar, jatah aman harian) dengan tombol Lewati dan Lanjut/Mulai.
- Kunci ARB baru: `onboardingTitle1..3`, `onboardingBody1..3`, `onboardingSkip`, `onboardingNext`, `onboardingStart`. Teks mengikuti nada suportif `docs/UI-UX.md` bagian 6.

- [ ] **Step 1: test gagal.** Repository (pakai `SharedPreferences.setMockInitialValues`): `isSeen false by default`, `markSeen persists true`. Cubit: `load emits seen false then true after complete` (`seen` `null → false`, `complete → true`, dan `markSeen` terpanggil). Widget: `shows first slide and Lewati`; `Lanjut moves to next slide`; `Mulai on last slide calls onFinished`; `Lewati calls onFinished`; `renders without overflow at text scale 2.0` (set `MediaQuery` `textScaler: TextScaler.linear(2)`, tidak ada exception).
- [ ] **Step 2: jalankan** → FAIL.
- [ ] **Step 3: implementasi** ketiganya; `PageView` + indikator titik, konten dibungkus `SingleChildScrollView` agar aman pada teks besar.
- [ ] **Step 4: verifikasi** test PASS, analyze bersih.
- [ ] **Step 5: commit** `feat(onboarding): add three-slide onboarding with persisted flag`.

---

### Task 8: Layar auth dan redirect router

**Files:**
- Create: `lib/app/router_redirect.dart`, `lib/features/auth/view/{splash_page,login_page,register_page,forgot_password_page}.dart`, `test/app/router_redirect_test.dart`, `test/features/auth/view/{login_page,register_page,forgot_password_page}_test.dart`
- Modify: `lib/app/router.dart`, `lib/app/app.dart`, `lib/bootstrap.dart`, `lib/l10n/app_id.arb`

**Interfaces:**
- Consumes: `AuthBloc`, `LoginCubit`, `RegisterCubit`, `ForgotPasswordCubit`, `validate*`, `OnboardingCubit` (Task 6, 7); `createRouter(...)` (Task 4).
- Produces: `String? resolveRedirect({required AuthStatus status, required bool? onboardingSeen, required String location})`; rute `/splash`, `/onboarding`, `/login`, `/register`, `/forgot-password`; `createRouter(...)` kini menerima `AuthBloc` dan `OnboardingCubit` dan memakai `refreshListenable` dari keduanya (`GoRouterRefreshStream`). `bootstrap()` membangun `AuthRepositoryImpl`, `SharedPrefsOnboardingRepository`, dan menyediakannya lewat `MultiRepositoryProvider`/`MultiBlocProvider` di `App`.

Tabel `resolveRedirect` (tulis sebagai test tabel):

| status | onboardingSeen | location | hasil |
|---|---|---|---|
| unknown | any | apa pun selain `/splash` | `/splash` |
| unknown | any | `/splash` | `null` |
| unauthenticated | `null` (memuat) | apa pun selain `/splash` | `/splash` |
| unauthenticated | `false` | apa pun selain `/onboarding` | `/onboarding` |
| unauthenticated | `true` | `/login`, `/register`, `/forgot-password` | `null` |
| unauthenticated | `true` | `/home`, `/splash`, `/onboarding` | `/login` |
| authenticated | any | `/login`, `/register`, `/forgot-password`, `/splash`, `/onboarding` | `/home` |
| authenticated | any | `/home`, `/debts`, `/more/...` | `null` |

- [ ] **Step 1: test tabel `resolveRedirect` (gagal)** — satu `test` per baris tabel.
- [ ] **Step 2: test widget (gagal).** Login: `shows validation errors for empty fields`; `submit calls cubit with trimmed email` (ketik ` Rani@Mail.COM `, verifikasi `AuthRepository.signInWithEmail` menerima `rani@mail.com` lewat mock); `failure InvalidCredentials shows error message from l10n`; `google cancelled shows no error`; `Daftar link navigates to register`; `Lupa password link navigates`; `no overflow at text scale 2.0 and scrollable`. Register: `requires name, email, password >= 8`; `EmailInUse shows message`. Forgot: `sent state shows confirmation`. Splash: `shows progress indicator`.
- [ ] **Step 3: jalankan** → FAIL.
- [ ] **Step 4: implementasi** `resolveRedirect`, empat layar (semua `Scaffold` + `SafeArea` + `SingleChildScrollView`, tombol `FilledButton` dengan indikator saat `submitting`, pesan error dipetakan dari `AuthFailure` ke ARB, tanpa nada menyalahkan), perbarui router, `App`, dan `bootstrap`.
- [ ] **Step 5: verifikasi otomatis.** `flutter test` hijau; `flutter analyze` bersih.
- [ ] **Step 6 (manual — user): uji di emulator/HP.** Alur: buka pertama kali → onboarding → daftar email → masuk Beranda; keluar app, buka lagi → langsung Beranda tanpa melihat layar login (Review Focus 3, ulangi dengan mode pesawat); Google Sign-In sukses dan batal; lupa password mengirim email; salah password menampilkan pesan.
- [ ] **Step 7: centang item Auth, onboarding di `TODO.md`; commit** `feat(auth): add auth screens and auth-aware routing`.

---

### Task 9: Firestore security rules dan test emulator

**Files:**
- Create: `firebase.json`, `firestore.rules`, `firestore.indexes.json` (isi `{"indexes": [], "fieldOverrides": []}`), `firebase/package.json`, `firebase/test/rules.test.js`
- Modify: `docs/TESTING.md` (bagian 4 dan 6), `docs/DATABASE.md` (bagian 5), `.gitignore` (`firebase/node_modules/`)

**Interfaces:**
- Produces: `firestore.rules` (versi 2) yang: (a) menolak semua akses bila `request.auth == null`; (b) mengizinkan baca/tulis di `users/{uid}/{document=**}` hanya bila `request.auth.uid == uid`; (c) untuk dokumen `users/{uid}` memvalidasi tulis: kunci hanya `displayName`, `email`, `createdAt`, `settings`; `settings.reminderTime` string `HH:mm`, `settings.reminderDaysBefore` list int, `settings.budgetCycleStartDay` int 1–28, `settings.timezone` string. Validasi subkoleksi (hutang, dll.) ditambahkan di fase masing-masing.
- Skrip: `npm test` di `firebase/` menjalankan `firebase emulators:exec --only firestore "node --test test/"`.

- [ ] **Step 1: siapkan alat.** `firebase/package.json` dengan devDependency `@firebase/rules-unit-testing` dan `firebase-admin`; `npm install` di `firebase/`. Emulator Firestore butuh Java; verifikasi `java -version` (jika tidak ada, minta user memasang JDK 17+).
- [ ] **Step 2: tulis test gagal** `rules.test.js` (`node:test`, `initializeTestEnvironment`, rules dari `../../firestore.rules`): `owner can create own profile`; `owner can read own profile`; `other user cannot read profile`; `other user cannot write profile`; `unauthenticated cannot read or write`; `owner can write to a subcollection doc` (`users/a/debts/d1`); `other user cannot read subcollection doc`; `profile with unknown field is denied`; `budgetCycleStartDay 0 and 29 are denied, 1 and 28 allowed`; `reminderDaysBefore must be a list`; `reminderTime must match HH:mm`; `document outside users/ is denied`.
- [ ] **Step 3: jalankan** `npm test` (di `firebase/`) → FAIL (rules belum ada/terlalu longgar).
- [ ] **Step 4: implementasi `firestore.rules` dan `firebase.json`** (`"firestore": {"rules": "firestore.rules", "indexes": "firestore.indexes.json"}`, emulator Firestore port 8080).
- [ ] **Step 5: verifikasi** `npm test` → semua PASS.
- [ ] **Step 6: deploy rules ke dev** (setelah user setuju): `firebase deploy --only firestore:rules,firestore:indexes --project geuralunas-dev`.
- [ ] **Step 7: perbarui dokumen:** `TESTING.md` (rules diuji dengan JS runner di `firebase/`, bukan `flutter test`), `DATABASE.md` bagian 5 (rules final Fase 1).
- [ ] **Step 8: centang item rules di `TODO.md`; commit** `feat(security): add Firestore rules with emulator tests`.

---

### Task 10: Profil pengguna dan layar Pengaturan

**Files:**
- Create: `lib/data/user_profile_data_source.dart`, `lib/repositories/user_profile_repository.dart`, `lib/features/settings/view/settings_page.dart`, `test/repositories/user_profile_repository_test.dart`, `test/features/settings/settings_page_test.dart`
- Modify: `lib/features/auth/bloc/auth_bloc.dart` (+ test), `lib/features/more/view/more_page.dart`, `lib/app/router.dart` (rute `/more/settings`), `lib/l10n/app_id.arb`, `lib/bootstrap.dart`

**Interfaces:**
- Consumes: `AppUser`, `AuthBloc` (Task 6).
- Produces: `class UserProfileDataSource(FirebaseFirestore)` — `Future<bool> exists(String uid)`, `Future<void> create(String uid, Map<String, Object?> data)`; `abstract interface class UserProfileRepository { Future<void> ensureProfile(AppUser user); }` + `UserProfileRepositoryImpl` yang membuat `users/{uid}` bila belum ada dengan `displayName`, `email`, `createdAt: FieldValue.serverTimestamp()`, `settings: {reminderTime: '09:00', reminderDaysBefore: [3, 1, 0], budgetCycleStartDay: 1, timezone: 'Asia/Jakarta'}` (sesuai `docs/DATABASE.md` 3.1) dan tidak menimpa profil yang sudah ada. `AuthBloc` menerima `UserProfileRepository` dan memanggil `ensureProfile` saat pertama kali status menjadi `authenticated`; kegagalan `ensureProfile` tidak membatalkan login (dicatat, dicoba lagi pada pembukaan berikutnya). `SettingsPage`: kartu akun (nama, email), tombol **Keluar** dengan dialog konfirmasi yang memanggil `AuthSignOutRequested`. `MorePage` memuat tile Pengaturan (menuju `/more/settings`) dan tile Simulasi pelunasan (nonaktif, label "Segera hadir").

- [ ] **Step 1: test gagal.** Repository (mock `UserProfileDataSource`): `creates profile with default settings when missing` (verifikasi map persis nilai default di atas); `does not overwrite existing profile`. `AuthBloc`: `calls ensureProfile once when authenticated`; `login still succeeds when ensureProfile throws`. Widget `SettingsPage`: `shows name and email`; `sign out asks for confirmation` (batal tidak memanggil sign out, konfirmasi memanggilnya).
- [ ] **Step 2: jalankan** → FAIL.
- [ ] **Step 3: implementasi** data source, repository, perubahan `AuthBloc`, `SettingsPage`, `MorePage`, rute, dan wiring di `bootstrap()`.
- [ ] **Step 4: verifikasi otomatis:** `flutter test`, `flutter analyze` bersih.
- [ ] **Step 5 (manual — user): uji di perangkat.** Setelah daftar baru, dokumen `users/{uid}` muncul di Firestore console dengan nilai default; keluar lalu masuk dengan akun lain tidak menampilkan data akun sebelumnya; keluar mengembalikan ke layar login.
- [ ] **Step 6: centang item pengaturan dasar di `TODO.md`; commit** `feat(settings): create user profile on first login and add settings screen`.

---

### Task 11: Penutup Fase 1 — gerbang kualitas dan dokumen

**Files:**
- Modify: `TODO.md`, `CHANGELOG.md`, `README.md`, `docs/ARCHITECTURE.md` (bagian 8: flavor ditunda; bagian 3 bila struktur berbeda), `docs/DECISIONS.md` (ADR-012: satu lingkungan Firebase di Fase 1; JS runner untuk rules), `docs/DIAGRAMS.md` bila ada alur berubah

- [ ] **Step 1: gerbang kualitas.** Jalankan skill `vgv-ai-flutter-plugin:green-gate` (analyze, format, test, coverage). Target: `domain` 100%, bloc/cubit ≥ 90%, keseluruhan ≥ 80% (`docs/TESTING.md`). Lihat angka coverage hasil run sebelum menyatakan lulus; bila di bawah target, tambah test pada modul yang kurang.
- [ ] **Step 2: ulang `npm test`** di `firebase/` → semua PASS.
- [ ] **Step 3: `flutter build apk --debug`** sukses; jalankan checklist manual Task 8 dan 10 sekali lagi pada build terakhir.
- [ ] **Step 4: perbarui dokumen** sesuai daftar di atas; tambah entri `CHANGELOG.md` (`Ditambahkan`: fondasi app, tema, navigasi, auth, onboarding, rules).
- [ ] **Step 5: `TODO.md`:** semua item Fase 1 tercentang, "Sedang dikerjakan" menunjuk ke Fase 2 Task pertama, Log selesai diisi.
- [ ] **Step 6: commit** `docs: close phase 1 foundation` (dan `git push` hanya bila user meminta).

---

## Self-Review

**Cakupan spec (Fase 1 di `TODO.md`):** scaffold + lint + folder (T1); Firebase (T5); tema, format rupiah, lokalisasi (T2, T3); routing + navigasi bawah (T4); auth Google + email, daftar, masuk, lupa password, keluar (T6, T8, T10); rules + test emulator (T9); onboarding + pengaturan dasar (T7, T10). US-00 tercakup oleh T6, T8, T10. Tidak ada kesenjangan.

**Konsistensi tipe:** `AuthStatus`, `AuthState`, `AuthRepository`, `AuthFailure`, `OnboardingCubit.state.seen (bool?)`, `resolveRedirect` memakai nama yang sama di T6–T8 dan T10; `createRouter` ditambah parameter bertahap (T4 → T8) tanpa mengganti nama.

**Proporsi:** rencana memuat keputusan (file, signature, nilai spec, test) dan tidak memuat isi fungsi.

**Penyimpangan dari dokumen:** flavor ditunda (dicatat T11); test rules memakai JS runner (diperbarui T9). Keduanya dicatat di `DECISIONS.md`.
