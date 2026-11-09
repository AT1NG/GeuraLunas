# Fase 3 — Pengingat dan Tagih Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hutang "aku berutang" mengirim notifikasi lokal tepat waktu sebelum jatuh tempo (US-06), dan detail piutang punya tombol Tagih yang membagikan teks sopan (US-07).

**Architecture:** Logika murni (`planReminders`, ID stabil) di `lib/domain/reminder`; `NotificationDataSource` membungkus plugin; `ReminderRepository.rescheduleAll()` diantre serial; `ReminderCoordinator` di lapisan app memicu penjadwalan ulang dari auth, stream hutang, dan lifecycle. Teks notifikasi dan teks tagih dibuat dari l10n (`id`), bukan di domain.

**Tech Stack:** Flutter 3.41 / Dart 3.11, flutter_bloc, go_router, Firestore, `flutter_local_notifications`, `timezone`, `flutter_timezone`, `share_plus`, mocktail, bloc_test, very_good_analysis.

**Spec:** `docs/superpowers/specs/2026-11-09-reminders-design.md`

## Global Constraints

- Cabang kerja: `phase-3-reminders` (dari `main`). Commit dan push hanya atas permintaan user; plan ini menyuruh commit per task karena user memilih eksekusi native/subagent, tidak ada push.
- Uang selalu `int` rupiah (`Money`). Tidak ada `double` untuk nominal.
- Bahasa UI Indonesia lewat `lib/l10n/app_id.arb` (hasil generate ke `lib/l10n/gen`). Nama kode, komentar, dan commit Inggris.
- Lint `very_good_analysis`: `flutter analyze` harus 0 isu. `flutter test` harus lulus sebelum task dinyatakan selesai.
- `lib/domain` Dart murni (tanpa Flutter, Firebase, intl, l10n).
- Setiap task yang menyelesaikan item di `TODO.md` mencentangnya dan menambah baris Log selesai.
- Penulisan Firestore tidak ditunggu UI (ADR-013); pola ini berlaku untuk simpan pengaturan.
- Notifikasi hanya untuk hutang `owe` berstatus `active`. Piutang (`lent`) tidak pernah punya alarm.
- ID notifikasi: `(fnv1a32(debtId) % 500000) * 4096 + seq * 8 + n` dengan `n` = hari sebelum jatuh tempo (0–7), sehingga selalu di bawah 2^31 dan stabil antar proses (jangan pakai `String.hashCode`).
- Batas jadwal: 60 hari ke depan, maksimal 200 notifikasi.
- `reminderDaysBefore`: bilangan bulat 0–7, minimal satu, tanpa duplikat (sesuai rules).

## Review Focus

Masukan yang tidak disebut spesifikasi tetapi paling mungkin menggigit pengguna; tiap baris punya tes di task pemiliknya.

1. **Pengingat hari-H setelah jamnya lewat** (cicilan jatuh tempo hari ini, sekarang 14:00, jam pengingat 09:00): tidak boleh dijadwalkan di masa lalu dan tidak boleh langsung muncul. (Task 1)
2. **Cicilan `partial`**: teks memakai sisa cicilan, bukan jumlah penuh. (Task 1)
3. **Keluar akun lalu masuk akun lain di perangkat yang sama**: notifikasi akun lama harus hilang. (Task 6)
4. **Izin ditolak atau plugin melempar error**: aplikasi tetap berjalan, tidak ada crash, percobaan berikutnya tetap jalan. (Task 4, 5)
5. **Banyak hutang** (lebih dari 200 pengingat dalam 60 hari) dan **tanggal akhir bulan** (jatuh tempo 31, pengingat H-3 jatuh di bulan sebelumnya). (Task 1)
6. **Teks tagih untuk piutang yang sudah lunas atau nama panjang/berkarakter khusus**: tombol tidak tampil untuk piutang lunas; nama tidak merusak teks. (Task 2, 8)

---

## File Structure

Baru:
- `lib/domain/reminder/reminder_settings.dart` — `ReminderSettings`, validasi.
- `lib/domain/reminder/reminder_plan.dart` — `ReminderPlan`, `planReminders`, `notificationId`.
- `lib/shared/reminder_text.dart` — `reminderTitle`, `reminderBody` dari l10n.
- `lib/features/debts/collection_message.dart` — `buildCollectionMessage`.
- `lib/data/notification_data_source.dart` — pembungkus plugin.
- `lib/repositories/reminder_repository.dart` — `ReminderRepository` dan impl.
- `lib/app/reminder_coordinator.dart` — pemicu penjadwalan ulang, permintaan izin, navigasi tap.
- `lib/features/settings/bloc/reminder_settings_cubit.dart` dan `lib/features/settings/view/reminder_settings_section.dart`.
- `lib/features/debts/view/collection_sheet.dart` — lembar Tagih.

Diubah: `pubspec.yaml`, `android/app/build.gradle.kts` dan `AndroidManifest.xml`, `lib/data/user_profile_data_source.dart`, `lib/repositories/user_profile_repository.dart`, `lib/app/app.dart`, `lib/bootstrap.dart`, `lib/app/router.dart` (hanya bila perlu untuk tap), `lib/features/settings/view/settings_page.dart`, `lib/features/debts/view/debt_detail_page.dart`, `lib/l10n/app_id.arb`, `test/helpers/fakes.dart`, dokumen.

---

### Task 1: Domain pengingat (`ReminderSettings`, `planReminders`, ID stabil)

**Files:**
- Create: `lib/domain/reminder/reminder_settings.dart`, `lib/domain/reminder/reminder_plan.dart`
- Test: `test/domain/reminder/reminder_settings_test.dart`, `test/domain/reminder/reminder_plan_test.dart`

**Interfaces:**
- Consumes: `Debt`, `Installment` (`lib/domain/debt/debt.dart`), `DebtState` (`lib/domain/debt/payments.dart`), `DebtDirection`, `DebtStatus`, `InstallmentStatus`, `Money`.
- Produces:
  - `ReminderSettings({required int hour, required int minute, required List<int> daysBefore, required String timezone})` dengan `static const defaults` (09:00, `[3,1,0]`, `Asia/Jakarta`), `ReminderSettings.validDaysBefore(List<int>) → bool` (1–8 isi, tiap isi 0–7, tanpa duplikat), `copyWith`, Equatable.
  - `ReminderPlan({required int id, required DateTime at, required String debtId, required String debtName, required Money amount, required int daysBefore})` Equatable. `at` adalah waktu dinding (wall-clock, tanpa zona) di zona `settings.timezone`.
  - `int notificationId({required String debtId, required int seq, required int daysBefore})`.
  - `List<ReminderPlan> planReminders({required List<DebtState> debts, required ReminderSettings settings, required DateTime now, int horizonDays = 60, int maxCount = 200})`; `now` juga waktu dinding di zona yang sama.

- [ ] **Step 1: Tulis tes `reminder_settings_test.dart`** — `defaults` bernilai 09:00/`[3,1,0]`/`Asia/Jakarta`; `validDaysBefore` menolak `[]`, `[8]`, `[-1]`, `[1,1]`, daftar 9 isi; menerima `[0]`, `[7,5,3,2,1,0]`.
- [ ] **Step 2: Tulis tes `reminder_plan_test.dart`** (helper membuat `DebtState` dari `makeDebt` di `test/helpers/debt_fixtures.dart` plus installment). Tes bernama:
  - `plans one reminder per installment per day before at the reminder time` (cicilan jatuh 20 Des 2026, defaults, now 1 Des → tiga rencana pada 17 Des 09:00, 19 Des 09:00, 20 Des 09:00 dengan `daysBefore` 3, 1, 0).
  - `skips reminders already in the past` (**Review Focus 1**: jatuh tempo hari ini, now 14:00, jam 09:00 → hari-H tidak dijadwalkan; H-1 dan H-3 juga tidak).
  - `ignores lent debts, settled, archived and paid installments`.
  - `partial installment uses the remaining amount` (**Focus 2**: amount 400.000, paidAmount 150.000 → `amount == Money(250000)`).
  - `reminders for the 31st fall into the previous month` (**Focus 5**: jatuh tempo 2 Mar, H-3 → 27 Feb; jatuh tempo 1 Apr H-3 → 29 Mar).
  - `stops at the horizon` (jatuh tempo 100 hari lagi tidak dijadwalkan; 59 hari lagi dijadwalkan).
  - `caps at maxCount, keeping the earliest` (**Focus 5**: 300 cicilan → 200 rencana pertama menurut waktu, terurut naik; uji `maxCount` kecil agar cepat).
  - `ids are stable and unique` (`notificationId('abc', 3, 1)` bernilai sama dua kali dan tidak sama dengan `('abc',3,0)`, `('abc',4,1)`, `('abd',3,1)`; semua id `>= 0` dan `< 2147483648` untuk seq 1–360, n 0–7).
- [ ] **Step 3: Jalankan** `flutter test test/domain/reminder` — Expected: gagal (file belum ada).
- [ ] **Step 4: Implementasi.** `fnv1a32` 32-bit atas code unit string; hasil dipetakan `% 500000`. `planReminders`: untuk tiap `DebtState` dengan `direction == owe` dan `status == active`, tiap installment non-`paid`, tiap `n` di `daysBefore`: `at = DateTime(due.year, due.month, due.day - n, hour, minute)`; buang `at` yang tidak setelah `now` atau lebih dari `horizonDays` dari `now`; `amount = installment.amount - installment.paidAmount`; urutkan menurut `at` lalu `id`; ambil `maxCount` pertama.
- [ ] **Step 5: Jalankan** `flutter test test/domain/reminder` — Expected: semua lulus.
- [ ] **Step 6: Commit** `feat(domain): plan reminders from installments (US-06)`.

---

### Task 2: Teks pengingat dan teks tagih

**Files:**
- Modify: `lib/l10n/app_id.arb` (lalu `flutter gen-l10n` otomatis lewat `flutter pub get`/test)
- Create: `lib/shared/reminder_text.dart`, `lib/features/debts/collection_message.dart`
- Test: `test/shared/reminder_text_test.dart`, `test/features/debts/collection_message_test.dart`

**Interfaces:**
- Consumes: `ReminderPlan` (Task 1), `AppLocalizations` (`lookupAppLocalizations(const Locale('id'))`), `formatRupiah`, `formatDate` (`lib/shared/formatters/rupiah.dart`), `Money`.
- Produces:
  - `String reminderTitle(AppLocalizations l10n)` → "Cicilan jatuh tempo".
  - `String reminderBody(ReminderPlan plan, AppLocalizations l10n)` → "Cicilan {nama} {nominal} jatuh tempo {hari ini|besok|dalam N hari}." (contoh: "Cicilan Paylater A Rp350.000 jatuh tempo besok.").
  - `String buildCollectionMessage({required AppLocalizations l10n, required String name, required Money remaining, DateTime? dueDate, required DateTime now})`.

- [ ] **Step 1: Tulis tes `reminder_text_test.dart`:** `daysBefore 0 → "...jatuh tempo hari ini."`, `1 → "besok"`, `3 → "dalam 3 hari"`, nominal terformat `Rp350.000`, judul sesuai.
- [ ] **Step 2: Tulis tes `collection_message_test.dart`:**
  - belum lewat: `"Halo Budi, mau mengingatkan pinjaman Rp100.000 yang jatuh tempo tanggal 12 Nov. Kapan kira-kira bisa dibayar? Terima kasih ya."` (tanggal dari `formatDate`; sesuaikan literal dengan keluaran `formatDate(DateTime(2026,11,12))` yang dibaca dari tes yang sudah ada).
  - sudah lewat: kalimat memuat "yang jatuh tempo tanggal 12 Nov lalu."
  - tanpa jatuh tempo: `"Halo Budi, mau mengingatkan soal pinjaman Rp100.000. Kapan kira-kira bisa dibayar? Terima kasih ya."`
  - memakai sisa: `remaining` yang dikirim yang tampil (bukan total).
  - nama panjang dan berkarakter khusus (**Focus 6**: 100 karakter, `"Budi {x} 'Pak' \n"`) tidak melempar dan muncul apa adanya; baris baru di nama diganti spasi.
  - tidak memuat satu pun kata dari daftar terlarang (`bodoh`, `ancam`, `lapor`, `polisi`, `awas`) untuk ketiga bentuk.
- [ ] **Step 3: Jalankan** kedua tes — Expected: gagal.
- [ ] **Step 4: Tambah string ke `app_id.arb`** dengan placeholder bertipe (`name`, `amount`, `date`, `when`): `reminderTitle`, `reminderBody`, `reminderWhenToday`, `reminderWhenTomorrow`, `reminderWhenInDays`, `collectionBeforeDue`, `collectionAfterDue`, `collectionNoDue`. Implementasikan dua fungsi di atas; `now` dibandingkan per hari kalender (tanpa jam) untuk menentukan "sudah lewat".
- [ ] **Step 5: Jalankan** kedua tes — Expected: lulus.
- [ ] **Step 6: Commit** `feat(l10n): reminder and collection texts (US-06, US-07)`.

---

### Task 3: Pengaturan pengingat di profil (baca dan simpan)

**Files:**
- Modify: `lib/data/user_profile_data_source.dart`, `lib/repositories/user_profile_repository.dart`, `test/helpers/fakes.dart`
- Test: `test/repositories/user_profile_repository_test.dart` (tambah), `test/data/user_profile_data_source_test.dart` (baru, `fake_cloud_firestore`)

**Interfaces:**
- Consumes: `ReminderSettings` (Task 1).
- Produces:
  - `UserProfileDataSource.watchSettings(String uid) → Stream<Map<String, Object?>?>` (nilai `settings` dari dokumen, null bila tidak ada) dan `updateReminderSettings(String uid, {required String time, required List<int> daysBefore}) → Future<void>` memakai `update({'settings.reminderTime': time, 'settings.reminderDaysBefore': daysBefore})`.
  - `UserProfileRepository.watchReminderSettings(String uid) → Stream<ReminderSettings>` (jatuh ke `ReminderSettings.defaults` bila dokumen/field hilang atau tidak valid) dan `saveReminderSettings(String uid, ReminderSettings s) → Future<void>` (tidak menunggu server; melempar `ArgumentError` bila `daysBefore` tidak valid; jam diformat `HH:mm`).
  - `FakeUserProfileRepository` di `test/helpers/fakes.dart` mendapat `settings` (StreamController), `saved` (daftar panggilan), dan implementasi dua method baru.

- [ ] **Step 1: Tulis tes data source** dengan `FakeFirebaseFirestore`: `watchSettings` memancarkan map `settings`; `updateReminderSettings` mengubah hanya dua field dan tidak menyentuh `createdAt`/`displayName`.
- [ ] **Step 2: Tulis tes repository:** nilai tersimpan `{reminderTime: '07:30', reminderDaysBefore: [2,0]}` menjadi `ReminderSettings(hour:7, minute:30, daysBefore:[2,0], timezone:'Asia/Jakarta')`; map kosong/null → `defaults`; `reminderTime: 'xx'` → `defaults`; `saveReminderSettings` dengan `[]` melempar `ArgumentError` dan tidak memanggil data source; jam `7:05` ditulis `'07:05'`.
- [ ] **Step 3: Jalankan** — Expected: gagal.
- [ ] **Step 4: Implementasi** sesuai interface; `timezone` dibaca dari `settings.timezone` bila ada, jika tidak `Asia/Jakarta`.
- [ ] **Step 5: Jalankan** `flutter test test/repositories test/data` — Expected: lulus (tes `ensureProfile` lama tetap lulus).
- [ ] **Step 6: Commit** `feat(data): read and save reminder settings (US-06)`.

---

### Task 4: Dependensi, konfigurasi Android, dan `NotificationDataSource`

**Files:**
- Modify: `pubspec.yaml`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`
- Create: `lib/data/notification_data_source.dart`
- Test: `test/data/notification_data_source_test.dart`

**Interfaces:**
- Consumes: `ReminderPlan`, `reminderTitle`, `reminderBody` (Task 2).
- Produces: `NotificationDataSource` dengan
  - `Future<void> init()` (inisialisasi plugin, `tz.initializeTimeZones()`, kanal `reminders`, ambil `launchDebtId`),
  - `Future<void> cancelAll()`,
  - `Future<void> schedule(List<ReminderPlan> plans, {required String timezone})` — memakai `AndroidScheduleMode.exactAllowWhileIdle` bila alarm tepat diizinkan, jika tidak `inexactAllowWhileIdle`; `payload` = `debtId`; melempar tidak boleh menggagalkan seluruh daftar: error satu notifikasi dicatat dan sisanya tetap dijadwalkan,
  - `Future<ReminderPermissions> permissions()` dan `Future<ReminderPermissions> requestPermissions()` dengan `ReminderPermissions({required bool notifications, required bool exactAlarms})`,
  - `Future<void> openAlarmSettings()`,
  - `Stream<String> get taps` (debtId) dan `String? launchDebtId` (tap yang membuka app dari keadaan mati),
  - `DateTime wallClockNow(String timezone)` (waktu dinding di zona itu; jatuh ke zona perangkat bila nama zona tidak dikenal).
  - Seluruh akses plugin lewat antarmuka tipis `NotificationsPlatform` yang diinjeksikan agar bisa dimock; implementasi default membungkus plugin.

- [ ] **Step 1: Tambah dependensi** dengan `flutter pub add flutter_local_notifications timezone flutter_timezone share_plus` (versi terbaru yang kompatibel Dart 3.11) lalu `flutter pub get`. Ikuti README plugin untuk Android: aktifkan core library desugaring di `build.gradle.kts`; di manifest tambah `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, serta `ScheduledNotificationReceiver` dan `ScheduledNotificationBootReceiver`. Expected: `flutter build apk --debug` sukses.
- [ ] **Step 2: Tulis tes** dengan `NotificationsPlatform` mock (mocktail):
  - `schedule` memanggil platform sekali per rencana dengan id, judul, isi (dari Task 2), payload `debtId`, dan waktu `TZDateTime` di zona `Asia/Jakarta` sesuai `at`.
  - mode `exact` bila `permissions().exactAlarms == true`, `inexact` bila tidak.
  - satu `schedule` yang melempar tidak menghentikan rencana berikutnya (**Focus 4**).
  - `wallClockNow('Zona/Tidakada')` tidak melempar.
  - `cancelAll` meneruskan ke platform.
- [ ] **Step 3: Jalankan** — Expected: gagal.
- [ ] **Step 4: Implementasi** `NotificationDataSource` dan `PluginNotificationsPlatform` (implementasi nyata yang tidak diuji unit; diuji manual di Task 9).
- [ ] **Step 5: Jalankan** `flutter test test/data/notification_data_source_test.dart` dan `flutter build apk --debug` — Expected: lulus dan build sukses.
- [ ] **Step 6: Commit** `feat(data): local notification data source and Android setup (US-06)`.

---

### Task 5: `ReminderRepository`

**Files:**
- Create: `lib/repositories/reminder_repository.dart`
- Test: `test/repositories/reminder_repository_test.dart`

**Interfaces:**
- Consumes: `DebtRepository.watchDebts()` dan `watchInstallments(id)` (ambil `.first`), `UserProfileRepository.watchReminderSettings(uid)` (`.first`), `NotificationDataSource`, `planReminders`.
- Produces: `abstract interface class ReminderRepository { Future<int> rescheduleAll(); Future<void> cancelAll(); Future<ReminderPermissions> requestPermissions(); Future<ReminderPermissions> permissions(); Stream<String> get taps; String? get launchDebtId; }` dan `ReminderRepositoryImpl({required DebtRepository debts, required UserProfileRepository profiles, required NotificationDataSource notifications, required String Function() currentUid})`. `rescheduleAll` mengembalikan jumlah notifikasi yang dijadwalkan.

- [ ] **Step 1: Tulis tes** (semua dependensi mock/fake):
  - `rescheduleAll cancels everything then schedules the plan` (urutan: `cancelAll` sebelum `schedule`; argumen `schedule` sama dengan `planReminders` untuk data uji; nilai kembali = jumlah rencana).
  - `reads installments only for active owe debts`.
  - `concurrent calls run one after another` (**Focus 3/4**: dua panggilan bersamaan tidak membuat `cancelAll` dan `schedule` bersilang; urutan panggilan mock = C S C S).
  - `a failure is swallowed and the next call still works` (**Focus 4**: platform melempar pada panggilan pertama; `rescheduleAll` mengembalikan 0 tanpa melempar; panggilan kedua berhasil).
  - `cancelAll` tidak membaca data apa pun.
- [ ] **Step 2: Jalankan** — Expected: gagal.
- [ ] **Step 3: Implementasi** dengan antrean serial seperti `UserProfileRepositoryImpl.ensureProfile`; `now` dari `notifications.wallClockNow(settings.timezone)`; log kegagalan lewat `developer.log` tanpa nominal atau nama pihak.
- [ ] **Step 4: Jalankan** `flutter test test/repositories/reminder_repository_test.dart` — Expected: lulus.
- [ ] **Step 5: Commit** `feat(repo): reschedule reminders idempotently (US-06)`.

---

### Task 6: `ReminderCoordinator` dan wiring aplikasi

**Files:**
- Create: `lib/app/reminder_coordinator.dart`
- Modify: `lib/app/app.dart`, `lib/bootstrap.dart`, `test/helpers/fakes.dart` (`FakeReminderRepository`)
- Test: `test/app/reminder_coordinator_test.dart`, perbarui `test/app/app_test.dart` bila membangun `App`

**Interfaces:**
- Consumes: `ReminderRepository` (Task 5), `DebtRepository.watchDebts()`, aliran status auth (`AuthBloc.stream` atau `AuthRepository.authStateChanges`), `SharedPreferences`.
- Produces: `ReminderCoordinator({required ReminderRepository reminders, required Stream<bool> signedIn, required Stream<Object?> debtChanges, required SharedPreferences prefs, required void Function(String debtId) openDebt, Duration debounce = const Duration(milliseconds: 500)})` dengan `start()`, `onResumed()`, `dispose()`. `App` mendapat parameter `reminderRepository` dan membuat koordinator; `bootstrap` membuat `NotificationDataSource`/`ReminderRepositoryImpl` dan memanggil `init()` sebelum `runApp`.

- [ ] **Step 1: Tulis tes** dengan `FakeReminderRepository` dan `fake_async`/`pumpEventQueue`:
  - masuk akun → `rescheduleAll` sekali; keluar akun → `cancelAll` (**Focus 3**: urutan keluar lalu masuk akun lain = cancelAll lalu rescheduleAll).
  - perubahan `debtChanges` beruntun dalam jendela debounce → satu `rescheduleAll`.
  - `onResumed` → `rescheduleAll`; tidak jalan bila belum masuk akun.
  - izin: `rescheduleAll` mengembalikan > 0 dan prefs `reminderPermissionAsked` belum ada → `requestPermissions()` sekali lalu flag disimpan; panggilan berikutnya tidak meminta lagi; mengembalikan 0 → tidak meminta.
  - tap notifikasi (`taps` mengirim `d1`) → `openDebt('d1')`; `launchDebtId` non-null saat `start()` → `openDebt` dipanggil sekali.
- [ ] **Step 2: Jalankan** — Expected: gagal.
- [ ] **Step 3: Implementasi** koordinator. Di `App`: `WidgetsBindingObserver` memanggil `onResumed`; `openDebt` = `_router.go('/debts/$id')`; `debtChanges` = `debtRepository.watchDebts()` yang hanya aktif setelah masuk akun. Sediakan `ReminderRepository` lewat `RepositoryProvider` untuk Task 7.
- [ ] **Step 4: Jalankan** `flutter test test/app` dan seluruh `flutter test` — Expected: lulus.
- [ ] **Step 5: Commit** `feat(app): reschedule reminders on auth, data and lifecycle changes (US-06)`.

---

### Task 7: UI pengaturan pengingat

**Files:**
- Create: `lib/features/settings/bloc/reminder_settings_cubit.dart`, `lib/features/settings/view/reminder_settings_section.dart`
- Modify: `lib/features/settings/view/settings_page.dart`, `lib/l10n/app_id.arb`
- Test: `test/features/settings/reminder_settings_cubit_test.dart`, `test/features/settings/reminder_settings_section_test.dart`

**Interfaces:**
- Consumes: `UserProfileRepository.watchReminderSettings/saveReminderSettings` (Task 3), `ReminderRepository.permissions/requestPermissions/rescheduleAll/openAlarmSettings` (Task 5; tambahkan `openAlarmSettings()` ke antarmuka bila belum ada).
- Produces: `ReminderSettingsCubit(profiles, reminders, {required String uid})` dengan state `ReminderSettingsState({settings, permissions, saving})` dan method `setTime(int hour, int minute)`, `toggleDay(int n)` (menolak mengosongkan hari terakhir), `requestPermissions()`, `openAlarmSettings()`. Penyimpanan memanggil `saveReminderSettings` lalu `rescheduleAll()` tanpa menunggu server.

- [ ] **Step 1: Tulis tes cubit** (`bloc_test`): muat awal dari stream; `setTime` menyimpan dan memicu `rescheduleAll`; `toggleDay(3)` menambah/mencabut; mencabut hari terakhir tidak mengubah state dan tidak menyimpan; urutan `daysBefore` tersimpan menurun; `requestPermissions` memperbarui `permissions`.
- [ ] **Step 2: Tulis tes widget:** chip H-0, H-1, H-2, H-3, H-5, H-7 dengan yang bawaan terpilih; ketuk chip memanggil cubit; baris "Izinkan" tampil bila notifikasi dimatikan; catatan "Pengingat bisa meleset beberapa menit" tampil bila alarm tepat tidak diizinkan; teks bantuan baterai tampil; ukuran teks 2.0 tidak overflow.
- [ ] **Step 3: Jalankan** — Expected: gagal.
- [ ] **Step 4: Implementasi** cubit dan section (time picker `showTimePicker`, `FilterChip`); sisipkan section di `SettingsPage` di atas tombol keluar; string baru di `app_id.arb`.
- [ ] **Step 5: Jalankan** `flutter test test/features/settings` dan `flutter test test/features/settings/settings_page_test.dart` (tes lama) — Expected: lulus.
- [ ] **Step 6: Commit** `feat(settings): reminder time, days and permission status (US-06)`.

---

### Task 8: Tombol Tagih dan lembar bagikan

**Files:**
- Create: `lib/features/debts/view/collection_sheet.dart`
- Modify: `lib/features/debts/view/debt_detail_page.dart`, `lib/l10n/app_id.arb`
- Test: `test/features/debts/collection_sheet_test.dart`, tambah ke `test/features/debts/debt_detail_page_test.dart`

**Interfaces:**
- Consumes: `buildCollectionMessage` (Task 2), `share_plus`, `Debt` dan `DebtDetailCubit` yang sudah ada.
- Produces: `showCollectionSheet(BuildContext, {required String name, required Money remaining, DateTime? dueDate})`; fungsi pembagi dibungkus `typedef ShareText = Future<void> Function(String text)` yang dapat diganti di tes lewat parameter `share` (default memakai `SharePlus`).

- [ ] **Step 1: Tulis tes widget:**
  - detail piutang aktif menampilkan tombol `Key('debt-collect')`; detail hutang `owe`, piutang lunas, dan piutang diarsipkan tidak (**Focus 6**).
  - mengetuk tombol membuka lembar berisi teks hasil `buildCollectionMessage` dengan sisa (bukan total) dan jatuh tempo terdekat (`nextDueDate`).
  - teks bisa diedit dan `Bagikan` memanggil `share` dengan teks yang sudah diedit.
  - lembar tidak overflow pada teks 2.0.
- [ ] **Step 2: Jalankan** — Expected: gagal.
- [ ] **Step 3: Implementasi** lembar bawah dengan `TextField` multi-baris, tombol "Bagikan", dan salin cepat; tombol di kartu ringkasan sejajar tombol Bayar/Terima. Tidak ada penulisan Firestore.
- [ ] **Step 4: Jalankan** `flutter test test/features/debts` — Expected: lulus.
- [ ] **Step 5: Commit** `feat(debts): collection message sheet for receivables (US-07)`.

---

### Task 9: Dokumen, gerbang kualitas, dan uji manual

**Files:**
- Modify: `docs/PRD.md` (US-07), `docs/ARCHITECTURE.md` (tabel dependensi, bagian 4.3, struktur folder), `docs/DECISIONS.md` (ADR-014, ADR-015), `docs/TESTING.md`, `CHANGELOG.md`, `TODO.md`, `README.md` bila perlu.

**Interfaces:** tidak ada; ini task penutup.

- [ ] **Step 1: Perbarui dokumen:** US-07 menjadi "membagikan teks tagih yang sopan" tanpa pengingat terjadwal untuk piutang; ADR-014 "Piutang tanpa alarm" dan ADR-015 "Alarm tepat dengan fallback tidak tepat, dengan catatan risiko kebijakan Play Store"; `share_plus` masuk tabel dependensi; ceklis uji manual Fase 3 masuk `docs/TESTING.md`; centang Fase 3 di `TODO.md` dan isi Log selesai.
- [ ] **Step 2: Gerbang kualitas.** Jalankan `flutter analyze` (Expected: 0 isu), `flutter test --coverage` (Expected: semua lulus; `lib/domain` 100%), dan `flutter build apk --debug` (Expected: sukses). Laporkan angka coverage.
- [ ] **Step 3: Uji manual di emulator** (butuh akun uji sementara di `geuralunas-dev` dengan izin user, dihapus sesudahnya): tambah hutang `owe` dengan jatuh tempo besok → notifikasi H-1 muncul pada waktunya (majukan jam emulator atau set jam pengingat dua menit ke depan); bayar cicilan → notifikasi berikutnya hilang; reboot emulator → jadwal bertahan; tap notifikasi → detail hutang terbuka; tolak lalu izinkan notifikasi; matikan alarm tepat → catatan tampil; keluar akun → tidak ada notifikasi tersisa; piutang → tombol Tagih membuka lembar dan share sheet.
- [ ] **Step 4: Commit** `docs: close phase 3 reminders and collection message`.

---

## Self-Review

- **Cakupan spesifikasi:** aturan dan domain (Task 1), teks (2), pengaturan di profil (3), data source dan izin dan manifest (4), repository dan antrean serial (5), pemicu dan reboot dan tap dan keluar akun dan permintaan izin (4 dan 6), UI pengaturan (7), Tagih (8), dokumen dan pengujian manual (9). Tidak ada bagian spesifikasi tanpa task.
- **Ruling terhadap spesifikasi:** (a) `buildCollectionMessage` dan teks notifikasi tinggal di `lib/features/debts` dan `lib/shared` (bukan `lib/domain`) karena memakai l10n dan format rupiah; tetap fungsi murni yang diuji unit. (b) `ReminderPlan` membawa data terstruktur, teks dibuat sesudahnya, supaya domain tetap Dart murni.
- **Konsistensi tipe:** `ReminderSettings`, `ReminderPlan`, `ReminderPermissions`, `ReminderRepository` dipakai dengan nama sama di semua task. `watchReminderSettings(uid)` dan `saveReminderSettings(uid, s)` didefinisikan di Task 3 dan dipakai di Task 5 dan 7. `openAlarmSettings` didefinisikan di data source (Task 4) dan diteruskan lewat `ReminderRepository` (Task 7 menambahkannya ke antarmuka).
- **Proporsi:** rencana berisi tanda tangan, nama tes, dan nilai nyata; badan fungsi tidak ditulis ulang.
