# Fase 4a — Kategori, Pengeluaran, Jatah Aman Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pengguna bisa mencatat pengeluaran dengan kategori (US-09) dan domain kalkulasi jatah aman (dasar US-10/US-11) siap dan teruji, tanpa UI jatah.

**Architecture:** Logika uang murni di `lib/domain/budget/` (test dulu). Data lewat `BudgetDataSource` → `CategoryRepository` / `ExpenseRepository` (batch, tidak ditunggu UI, ADR-013). UI memakai Cubit: sheet catat pengeluaran dari menu tambah, tab Budget berisi daftar pengeluaran siklus berjalan, layar kelola kategori.

**Tech Stack:** Flutter 3.41, flutter_bloc Cubit, go_router, cloud_firestore, `fake_cloud_firestore`, mocktail, bloc_test, very_good_analysis, firebase emulator + `node --test` untuk rules.

**Spec:** `docs/superpowers/specs/2026-11-10-expenses-allowance-design.md` (spec adalah otoritas; konflik diputuskan terhadapnya).

## Global Constraints

- Nominal rupiah selalu `int` (`Money`); domain Dart murni tanpa import Flutter/Firebase (CLAUDE.md 4, 5).
- Test dulu untuk logika uang: tulis test, lihat gagal, baru implementasi.
- Penulisan Firestore lewat `WriteBatch` dan UI tidak menunggu commit (ADR-013); galat server lewat `writeErrors`.
- Teks UI Indonesia dari `lib/l10n/app_id.arb`; setelah mengubah arb jalankan `flutter gen-l10n`. Nada suportif, tidak menghakimi. Nama kode, komentar, commit: Inggris.
- Setiap commit menyebut ID story: `(US-09)` atau `(US-10)`. Trailer commit sesuai instruksi sesi.
- Gerbang tiap task: `flutter analyze` 0 isu dan `flutter test` penuh hijau. Jalankan `dart format lib test` sebelum commit.
- Berkas repo ber-CRLF: ubah berkas yang ada dengan Edit, bukan penggantian multi-baris lewat skrip.
- `settings.budgetCycleStartDay` belum punya UI (4b). Di 4a layar memakai `defaultBudgetCycleStartDay = 1`; domain tetap menerima `startDay` 1–28.
- Kategori tidak pernah dihapus, hanya diarsipkan. Pembayaran hutang bukan pengeluaran.

## Review Focus

Masukan yang tidak dicakup spec secara eksplisit, paling mungkin mengganggu pengguna; tiap baris punya test di task yang disebut.

1. Pengeluaran jam 23:59 hari terakhir siklus dan 00:00 hari pertama siklus berikutnya jatuh ke siklus yang benar, termasuk Feb 28/29 dan pergantian tahun (Task 1, 3).
2. Kategori diarsipkan setelah dipakai: baris pengeluaran lama tetap menampilkan nama kategori, chip pilihan tidak menampilkannya (Task 8, 9).
3. Nominal tempelan `Rp 1.500.000`, `0`, kosong, dan di atas `maxAmount` ditolak dengan pesan ramah, tidak menulis ke Firestore (Task 8).
4. Dua `ensureDefaults()` bersamaan dan pemanggilan ulang tidak menggandakan atau menimpa perubahan nama pengguna (Task 5).
5. Nama kategori hanya spasi atau lebih dari 50 karakter ditolak di cubit dan di rules (Task 10, 11).

---

### Task 1: `BudgetCycle`

**Files:**
- Create: `lib/domain/budget/budget_cycle.dart`
- Test: `test/domain/budget/budget_cycle_test.dart`

**Interfaces:**
- Produces: `const defaultBudgetCycleStartDay = 1;` dan
  `final class BudgetCycle extends Equatable { const BudgetCycle({required DateTime start, required DateTime endInclusive}); factory BudgetCycle.of(DateTime day, {required int startDay}); String get id; bool contains(DateTime day); int remainingDays(DateTime today); }`. Semua tanggal dinormalisasi ke `DateTime(y, m, d)`.

- [ ] **Step 1: Tulis test gagal** dengan nilai pasti:
  - `of(2026-11-10, startDay: 1)` → `start 2026-11-01`, `endInclusive 2026-11-30`, `id '2026-11'`.
  - `of(2026-11-10, startDay: 25)` → `2026-10-25`..`2026-11-24`, `id '2026-10'`; `of(2026-11-25, startDay: 25)` → `2026-11-25`..`2026-12-24`, `id '2026-11'`.
  - `of(2027-01-10, startDay: 25)` → `2026-12-25`..`2027-01-24`, `id '2026-12'` (pergantian tahun).
  - `of(2027-03-05, startDay: 28)` → `2027-02-28`..`2027-03-27`; `of(2028-02-10, startDay: 1)` berakhir `2028-02-29`.
  - `contains`: `2026-11-30 23:59` benar, `2026-12-01 00:00` salah untuk siklus `2026-11`.
  - `remainingDays(2026-11-10)` = 21, hari terakhir = 1, `today` di luar siklus (setelah akhir) = 1.
  - `startDay` 0 dan 29 melempar `ArgumentError`.
- [ ] **Step 2: Jalankan** `flutter test test/domain/budget/budget_cycle_test.dart` — Expected: FAIL (berkas belum ada).
- [ ] **Step 3: Implement `BudgetCycle`** di `budget_cycle.dart`: siklus mulai `startDay` bulan ini bila `day.day >= startDay`, bila tidak bulan sebelumnya; akhir = sehari sebelum `startDay` bulan berikutnya (pakai `DateTime(y, m + 1, startDay - 1)` yang menangani batas bulan); `id` = `yyyy-MM` dari `start`.
- [ ] **Step 4: Jalankan test** — Expected: PASS.
- [ ] **Step 5: Commit** `feat(domain): budget cycle from a start day (US-10)`.

---

### Task 2: `Category`, `Expense`, `defaultCategories`

**Files:**
- Create: `lib/domain/budget/category.dart`, `lib/domain/budget/expense.dart`
- Test: `test/domain/budget/category_test.dart`, `test/domain/budget/expense_test.dart`

**Interfaces:**
- Consumes: `Money` (`lib/domain/money.dart`).
- Produces:
  - `final class Category extends Equatable { const Category({required String id, required String name, required String icon, required String colorHex, required int sortOrder, bool isDefault = false, bool archived = false}); Category copyWith({String? name, bool? archived}); }`
  - `const List<Category> defaultCategories` dengan ID tetap `makan, transport, belanja, tagihan, hiburan, kesehatan, lainnya`, nama `Makan, Transport, Belanja, Tagihan, Hiburan, Kesehatan, Lainnya`, `sortOrder` 0–6, `isDefault: true`.
  - `final class Expense extends Equatable { const Expense({required String id, required Money amount, required String categoryId, required DateTime spentAt, required DateTime createdAt, String? note}) : assert(amount.rupiah > 0); }`.

- [ ] **Step 1: Test gagal:** `defaultCategories` berisi tepat 7 ID di atas berurutan dan semuanya `isDefault`; `copyWith(archived: true)` hanya mengubah `archived`; `Expense(amount: Money(0), ...)` dan `Money(-5)` melempar `AssertionError`; dua `Expense` sama dengan nilai sama sama-sama setara.
- [ ] **Step 2: Jalankan** kedua test — Expected: FAIL.
- [ ] **Step 3: Implement** kedua entitas dan `defaultCategories`; ikon berupa nama string (mis. `restaurant`, `directions_bus`, `shopping_bag`, `receipt_long`, `movie`, `favorite`, `more_horiz`) dan `colorHex` `#RRGGBB`.
- [ ] **Step 4: Jalankan test** — Expected: PASS.
- [ ] **Step 5: Commit** `feat(domain): category and expense entities (US-09)`.

---

### Task 3: `computeSafeAllowance`

**Files:**
- Create: `lib/domain/budget/safe_allowance.dart`
- Test: `test/domain/budget/safe_allowance_test.dart`

**Interfaces:**
- Consumes: `BudgetCycle` (Task 1), `Expense` (Task 2), `DebtState` (`lib/domain/debt/payments.dart`), `Installment`/`Debt` (`lib/domain/debt/debt.dart`), `DebtDirection`/`DebtStatus`/`InstallmentStatus`, `Money`.
- Produces: `enum AllowanceStatus { ok, installmentsExceedIncome }`;
  `final class SafeAllowance extends Equatable { final AllowanceStatus status; final Money installmentsThisCycle, monthlyLimit, monthlyRemaining, todayAllowance, weekAllowance; final int remainingDays; }`;
  `SafeAllowance computeSafeAllowance({required BudgetCycle cycle, required DateTime today, required Money incomeTotal, required Money savingsTarget, required List<DebtState> debts, required List<Expense> expenses})`.

- [ ] **Step 1: Test gagal.** Gunakan `makeDebt` dari `test/helpers/debt_fixtures.dart` untuk hutang. Siklus `startDay 1`, `today = 2026-11-10` (Selasa, `remainingDays` 21, 6 hari tersisa di minggu). Kasus dan nilai:
  - Dasar: income 5.000.000, savings 300.000, satu cicilan owe aktif `pending` 200.000 jatuh 2026-11-20, pengeluaran total 600.000 → `installmentsThisCycle` 200.000, `monthlyLimit` 4.500.000, `monthlyRemaining` 3.900.000, `todayAllowance` 185.714, `weekAllowance` 1.114.284 (`min(3.900.000, 185.714×6)`), `status ok`.
  - Cicilan `partial` (amount 200.000, paid 50.000) menghitung 150.000; cicilan `paid` tidak dihitung.
  - Diabaikan: cicilan jatuh 2026-12-01, hutang `lent`, hutang `settled`/`archived`, pengeluaran bertanggal 2026-10-31 dan 2026-12-01.
  - Cicilan melebihi pemasukan (income 200.000, cicilan 300.000) → `installmentsExceedIncome`, semua jatah 0, tidak ada angka negatif.
  - Pengeluaran melebihi sisa (income 1.000.000, pengeluaran 1.200.000) → `monthlyRemaining` 0, `todayAllowance` 0, `status ok`.
  - Pembulatan: `monthlyRemaining` 1.000.000, `remainingDays` 21 → `todayAllowance` 47.619.
  - Hari Minggu (`2026-11-15`) memberi `daysLeftInWeek` 1, hari Senin (`2026-11-16`) memberi 7 (via `weekAllowance` = `todayAllowance × n` bila di bawah `monthlyRemaining`); hari terakhir siklus (`2026-11-30`) memberi 1 dan `weekAllowance == todayAllowance`.
  - `weekAllowance` dibatasi `monthlyRemaining` (sisa kecil, hari Senin).
  - Pengeluaran bertanggal `2026-11-30 23:59` masuk siklus; `2026-12-01 00:00` tidak (Review Focus 1).
- [ ] **Step 2: Jalankan** — Expected: FAIL.
- [ ] **Step 3: Implement `computeSafeAllowance`** sesuai spec 2.2–2.3: `daysLeftInWeek` = hari dari `today` sampai Minggu (Senin=1 … Minggu=7 pada `DateTime.weekday`, jadi `8 - weekday`), dibatasi `cycle.remainingDays(today)`; `floor` pakai pembagian bulat `~/`; filter pengeluaran dengan `cycle.contains(spentAt)`.
- [ ] **Step 4: Jalankan test** — Expected: PASS semua.
- [ ] **Step 5: Commit** `feat(domain): safe allowance calculation (US-10)`.

---

### Task 4: Path, DTO, `BudgetDataSource`

**Files:**
- Modify: `lib/data/firestore_paths.dart`, `lib/data/debt_data_source.dart` (ekstrak penulisan batch)
- Create: `lib/data/budget_dtos.dart`, `lib/data/budget_data_source.dart`
- Test: `test/data/budget_dtos_test.dart`, `test/data/budget_data_source_test.dart`

**Interfaces:**
- Consumes: `WriteOp`/`SetOp`/`MergeOp`/`DeleteOp`/`RawDoc` dari `debt_data_source.dart`; `Category`, `Expense`.
- Produces:
  - `FirestorePaths.categories(uid)`, `.category(uid, id)`, `.expenses(uid)`, `.expense(uid, id)`.
  - `Future<void> writeBatches(FirebaseFirestore firestore, List<WriteOp> ops)` top-level di `debt_data_source.dart`; `DebtDataSource.write` memanggilnya (perilaku tidak berubah).
  - `Map<String, Object?> categoryToMap(Category)`, `Category categoryFromMap(String id, Map<String, Object?>)`, `expenseToMap(Expense)`, `expenseFromMap(String id, Map<String, Object?>)` (`Timestamp` ↔ `DateTime`, `amount` ↔ `int`, `note` hanya bila ada).
  - `class BudgetDataSource { BudgetDataSource(FirebaseFirestore); String newCategoryId(String uid); String newExpenseId(String uid); Stream<List<RawDoc>> watchCategories(String uid); Future<List<RawDoc>> getCategories(String uid); Stream<List<RawDoc>> watchExpenses(String uid, {required DateTime from, required DateTime toExclusive}); Future<void> write(List<WriteOp> ops); }`.

- [ ] **Step 1: Test gagal.** DTO: round-trip kategori dan pengeluaran (termasuk `note` null dan terisi, `amount` tetap `int`). Data source dengan `FakeFirebaseFirestore`: `watchExpenses` hanya mengembalikan `spentAt` dalam `[from, toExclusive)` (batas bawah masuk, batas atas keluar); `getCategories` mengembalikan dokumen; `write` dengan `SetOp`/`MergeOp`/`DeleteOp` tertulis.
- [ ] **Step 2: Jalankan** — Expected: FAIL. Jalankan juga `flutter test test/data/debt_dto_test.dart test/repositories/debt_repository_test.dart` sebagai jaring pengaman refaktor.
- [ ] **Step 3: Implement**: tambah path; ekstrak `writeBatches` dari `DebtDataSource.write` tanpa mengubah isi; tulis DTO mengikuti penamaan `debt_dto.dart`; `BudgetDataSource.write` memanggil `writeBatches`.
- [ ] **Step 4: Jalankan** test baru dan test hutang tadi — Expected: PASS.
- [ ] **Step 5: Commit** `feat(data): categories and expenses data source (US-09)`.

---

### Task 5: `CategoryRepository`

**Files:**
- Create: `lib/repositories/category_repository.dart`
- Test: `test/repositories/category_repository_test.dart`

**Interfaces:**
- Consumes: `BudgetDataSource`, `categoryFromMap`/`categoryToMap`, `defaultCategories`, `FirestorePaths`.
- Produces:
  ```dart
  abstract interface class CategoryRepository {
    Stream<List<Category>> watchCategories(); // urut sortOrder, termasuk arsip
    Future<void> ensureDefaults();            // idempoten, diserialkan
    Future<String> add({required String name, required String icon, required String colorHex});
    Future<void> rename(String id, String name);
    Future<void> setArchived(String id, {required bool archived});
    Stream<Object> get writeErrors;
  }
  class CategoryRepositoryImpl implements CategoryRepository {
    CategoryRepositoryImpl(BudgetDataSource dataSource, {required String Function() currentUid});
  }
  ```

- [ ] **Step 1: Test gagal** dengan `FakeFirebaseFirestore`: `ensureDefaults` pada koleksi kosong menulis 7 default; kedua kalinya tidak menulis apa pun; `Future.wait([ensureDefaults(), ensureDefaults()])` menghasilkan tepat 7 dokumen; setelah pengguna `rename('makan', 'Jajan')`, `ensureDefaults` lagi tidak mengembalikan nama `Makan` (Review Focus 4); `add` memberi `sortOrder` = maksimum + 1 dan `isDefault false`; `setArchived` hanya mengubah `archived` dan dokumen tidak terhapus; `watchCategories` terurut `sortOrder`; galat tulis server sampai ke `writeErrors`.
- [ ] **Step 2: Jalankan** — Expected: FAIL.
- [ ] **Step 3: Implement.** Antrean `Future` serial seperti `ReminderRepositoryImpl._serial`. `ensureDefaults`: bila sudah sukses sekali untuk `uid` ini (flag di memori) keluar; baca `getCategories`; bila kosong tulis 7 `SetOp` ber-ID tetap; set flag. Tulis dimulai tanpa di-await (ADR-013): ikuti `DebtRepositoryImpl.addDebt` (mulai `write`, teruskan galat ke `_errors`, kembalikan id).
- [ ] **Step 4: Jalankan** — Expected: PASS.
- [ ] **Step 5: Commit** `feat(repo): category repository with idempotent default seeding (US-09)`.

---

### Task 6: `ExpenseRepository`

**Files:**
- Create: `lib/repositories/expense_repository.dart`
- Test: `test/repositories/expense_repository_test.dart`

**Interfaces:**
- Consumes: `BudgetDataSource`, `expenseToMap`/`expenseFromMap`, `BudgetCycle`.
- Produces:
  ```dart
  abstract interface class ExpenseRepository {
    Stream<List<Expense>> watchExpenses(BudgetCycle cycle); // terbaru dulu
    Future<String> addExpense({required Money amount, required String categoryId, required DateTime spentAt, String? note});
    Future<void> deleteExpense(String id);
    Stream<Object> get writeErrors;
  }
  class ExpenseRepositoryImpl implements ExpenseRepository {
    ExpenseRepositoryImpl(BudgetDataSource dataSource, {required String Function() currentUid, DateTime Function()? now});
  }
  ```

- [ ] **Step 1: Test gagal:** `addExpense` menulis dokumen dengan `amount` `int` dan `createdAt` dari `now`, mengembalikan id; `watchExpenses` memakai rentang `[cycle.start, cycle.endInclusive + 1 hari)` dan urutan terbaru dulu (selisih `spentAt` sama → `createdAt` terbaru dulu); pengeluaran 23:59 hari terakhir masuk, 00:00 hari berikutnya tidak (Review Focus 1); `deleteExpense` menghapus; catatan kosong/spasi disimpan sebagai tanpa `note`.
- [ ] **Step 2: Jalankan** — Expected: FAIL.
- [ ] **Step 3: Implement** mengikuti pola tulis-tanpa-await Task 5.
- [ ] **Step 4: Jalankan** — Expected: PASS.
- [ ] **Step 5: Commit** `feat(repo): expense repository (US-09)`.

---

### Task 7: Wiring dan fake test

**Files:**
- Modify: `lib/bootstrap.dart`, `lib/app/app.dart`, `test/helpers/fakes.dart`, `test/helpers/pump_app.dart` (bila perlu), `test/app/app_test.dart`
- Test: `test/app/app_test.dart`

**Interfaces:**
- Consumes: `CategoryRepositoryImpl`, `ExpenseRepositoryImpl`, `BudgetDataSource`.
- Produces: `App` menerima `categoryRepository` dan `expenseRepository` dan menyediakannya lewat `RepositoryProvider`; `FakeCategoryRepository` (state `List<Category>`, `calls`, `emit(...)`) dan `FakeExpenseRepository` (`added`, `deleted`, `emit(List<Expense>)`) di `test/helpers/fakes.dart`.

- [ ] **Step 1: Test gagal** di `app_test.dart`: kedua repository tersedia dari konteks (`context.read<CategoryRepository>()`, `context.read<ExpenseRepository>()`), dan galat dari `writeErrors` keduanya ikut menampilkan snackbar yang sama seperti galat hutang (gabungkan stream).
- [ ] **Step 2: Jalankan** `flutter test test/app/app_test.dart` — Expected: FAIL (parameter belum ada).
- [ ] **Step 3: Implement** parameter `App`, penyedia repository, penggabungan `writeErrors`, pembuatan di `bootstrap.dart` (`BudgetDataSource(FirebaseFirestore.instance)`, `currentUid` seperti `DebtRepositoryImpl`), dan kedua fake.
- [ ] **Step 4: Jalankan** `flutter test` penuh — Expected: PASS (semua test lama tetap hijau).
- [ ] **Step 5: Commit** `feat(app): provide category and expense repositories (US-09)`.

---

### Task 8: Catat pengeluaran (sheet dan menu tambah)

**Files:**
- Modify: `lib/l10n/app_id.arb`, `lib/features/shell/add_menu_sheet.dart`
- Create: `lib/features/budget/bloc/categories_cubit.dart`, `lib/features/budget/bloc/add_expense_cubit.dart`, `lib/features/budget/view/add_expense_sheet.dart`
- Test: `test/features/budget/categories_cubit_test.dart`, `test/features/budget/add_expense_cubit_test.dart`, `test/features/budget/add_expense_sheet_test.dart`, `test/features/shell/add_menu_sheet_test.dart`

**Interfaces:**
- Consumes: `CategoryRepository`, `ExpenseRepository`, `parseAmount`/`maxAmount`, `AmountField`, `SubmitButton`.
- Produces:
  - `CategoriesCubit(CategoryRepository)` dengan `Future<void> start()` (memanggil `ensureDefaults()` lalu berlangganan `watchCategories`), `CategoriesState({CategoriesStatus status, List<Category> categories})` dan getter `active` (tidak diarsipkan, urut `sortOrder`); `add`, `rename`, `setArchived` (dipakai Task 10).
  - `AddExpenseCubit(ExpenseRepository, {DateTime Function()? now})`: `amountChanged(String)`, `categorySelected(String)`, `dateChanged(DateTime)`, `noteChanged(String)`, `Future<void> submit()`; state `AddExpenseState({String amount, String? categoryId, DateTime date, String note, AddExpenseError? error, SubmitStatus status})` dengan `AddExpenseError { amountRequired, amountInvalid, categoryRequired }`. Tanggal bawaan hari ini.
  - `Future<void> showAddExpenseSheet(BuildContext context)`; key: `Key('expense-amount')`, `Key('expense-save')`, chip `Key('expense-category-<id>')`.
  - arb: `addExpenseTitle`, `addExpenseAmountLabel`, `addExpenseCategory`, `addExpenseMore`, `addExpenseDate`, `addExpenseNote`, `addExpenseSave`, `addExpenseSaved`, `addExpenseAmountRequired`, `addExpenseAmountInvalid`, `addExpenseCategoryRequired`.

- [ ] **Step 1: Test gagal.**
  - `CategoriesCubit`: `start` memanggil `ensureDefaults` sebelum mengeluarkan daftar; `active` menyaring arsip dan terurut.
  - `AddExpenseCubit`: `submit` tanpa nominal → `amountRequired`, nominal `0` atau `Rp 1.500.000` valid/invalid sesuai `parseAmount` (`1.500.000` tersimpan `Money(1500000)`), di atas `maxAmount` → `amountInvalid`, tanpa kategori → `categoryRequired`; `submit` valid memanggil `addExpense` sekali dengan nilai yang benar dan tanggal hari ini; catatan spasi dikirim `null` (Review Focus 3); tidak ada panggilan repository bila tidak valid.
  - Widget: sheet menampilkan hanya kategori aktif (kategori arsip tidak muncul, Review Focus 2); alur tiga ketukan (isi nominal, ketuk kategori, ketuk Simpan) memanggil `addExpense` dan menutup sheet lalu menampilkan snackbar `addExpenseSaved`; pesan galat ramah saat nominal kosong.
  - Menu tambah: ketukan "Catat pengeluaran" membuka sheet (sebelumnya hanya menutup).
- [ ] **Step 2: Jalankan** keempat test — Expected: FAIL.
- [ ] **Step 3: Implement** cubit, sheet (nominal dengan fokus otomatis memakai `AmountField`, chip kategori, bagian "Lainnya" tertutup berisi tanggal dan catatan, tombol Simpan), arb + `flutter gen-l10n`, dan sambungan di `add_menu_sheet.dart` (hapus komentar "wired in a later phase"). Sheet menyediakan `CategoriesCubit` dan `AddExpenseCubit` lewat `BlocProvider` dari `RepositoryProvider`.
- [ ] **Step 4: Jalankan** keempat test dan `flutter test` penuh — Expected: PASS.
- [ ] **Step 5: Commit** `feat(budget): record an expense in three taps (US-09)`.

---

### Task 9: Tab Budget (daftar pengeluaran)

**Files:**
- Modify: `lib/features/budget/view/budget_page.dart`, `lib/l10n/app_id.arb`
- Create: `lib/features/budget/bloc/expenses_cubit.dart`
- Test: `test/features/budget/expenses_cubit_test.dart`, `test/features/budget/budget_page_test.dart`

**Interfaces:**
- Consumes: `ExpenseRepository`, `CategoriesCubit`, `BudgetCycle`, `defaultBudgetCycleStartDay`, `ConfirmDialog`, `EmptyState`, `MoneyText`.
- Produces: `ExpensesCubit(ExpenseRepository, {DateTime Function()? now, int startDay = defaultBudgetCycleStartDay})` dengan `start()`, `Future<void> delete(String id)`; `ExpensesState({status, List<Expense> expenses, BudgetCycle? cycle})` dan getter `byDay` (`Map<DateTime, List<Expense>>` terbaru dulu). Halaman memakai key `Key('budget-page')` (tetap), `Key('expense-row-<id>')`, `Key('expense-delete-<id>')`, `Key('manage-categories')`. arb: `budgetExpensesTitle`, `budgetExpensesEmpty`, `budgetDeleteTitle`, `budgetDeleteBody`, `budgetDeleteConfirm`, `budgetManageCategories`.

- [ ] **Step 1: Test gagal.** Cubit: `start` berlangganan `watchExpenses` untuk siklus dari `now`; `byDay` mengelompokkan per hari, terbaru dulu; `delete` memanggil `deleteExpense`. Halaman: daftar kosong menampilkan `EmptyState` ramah; baris menampilkan nama kategori, nominal (`MoneyText`), catatan; nama kategori yang sudah diarsipkan tetap tampil (Review Focus 2); ikon hapus meminta konfirmasi dan hanya menghapus bila dikonfirmasi; tautan "Kelola kategori" memanggil navigasi ke `/budget/categories`.
- [ ] **Step 2: Jalankan** — Expected: FAIL.
- [ ] **Step 3: Implement** cubit dan halaman (menggantikan placeholder; kunci `budget-page` dipertahankan agar test navigasi lama tetap lulus).
- [ ] **Step 4: Jalankan** kedua test dan `flutter test test/features/shell` — Expected: PASS.
- [ ] **Step 5: Commit** `feat(budget): list and delete this cycle's expenses (US-09)`.

---

### Task 10: Kelola kategori

**Files:**
- Modify: `lib/app/router.dart` (anak rute `categories` di cabang `/budget`; baca `_branch` dulu), `lib/features/budget/bloc/categories_cubit.dart`, `lib/l10n/app_id.arb`
- Create: `lib/features/budget/view/categories_page.dart`
- Test: `test/features/budget/categories_page_test.dart`, tambahan di `test/features/budget/categories_cubit_test.dart` dan `test/app/router_test.dart` (bila ada, kalau tidak di `test/features/shell`)

**Interfaces:**
- Consumes: `CategoriesCubit` (`add`, `rename`, `setArchived`), `Category`.
- Produces: rute `/budget/categories` dan `CategoriesPage`; validasi nama di `CategoriesCubit`: `CategoryNameError { empty, tooLong }` (dipangkas, 1–50 karakter); daftar ikon dan warna kecil sebagai konstanta (`categoryIcons`, `categoryColors`). Key: `Key('category-add')`, `Key('category-name')`, `Key('category-save')`, `Key('category-row-<id>')`, `Key('category-archive-<id>')`. arb: `categoriesTitle`, `categoriesAdd`, `categoriesNameLabel`, `categoriesNameEmpty`, `categoriesNameTooLong`, `categoriesArchive`, `categoriesRestore`, `categoriesArchivedSection`, `categoriesSave`.

- [ ] **Step 1: Test gagal.** Cubit: nama `'   '` → `empty` dan repository tidak dipanggil; 51 karakter → `tooLong`; `' Jajan '` disimpan `Jajan` (Review Focus 5). Halaman: kategori aktif lalu bagian "Diarsipkan"; tambah (nama, ikon, warna) memanggil `add`; ubah nama memanggil `rename`; arsipkan memindahkan baris ke bagian arsip tanpa menghapus; pulihkan mengembalikannya; kategori default bisa diubah nama dan diarsipkan, tidak ada tombol hapus. Rute `/budget/categories` membuka halaman dan tombol kembali ke tab Budget.
- [ ] **Step 2: Jalankan** — Expected: FAIL.
- [ ] **Step 3: Implement** validasi di cubit, halaman, rute, dan sambungan tautan Task 9.
- [ ] **Step 4: Jalankan** test baru dan `flutter test` penuh — Expected: PASS.
- [ ] **Step 5: Commit** `feat(budget): manage expense categories (US-09)`.

---

### Task 11: Security rules dan tes emulator

**Files:**
- Modify: `firestore.rules`, `firebase/test/rules.test.js`

**Interfaces:**
- Produces: `validCategory(d)` (`name` string 1–50, `icon` string, `colorHex` string, `sortOrder` int, `isDefault` bool, `archived` bool; hanya kunci itu) dan `validExpense(d)` (`amount` int > 0, `categoryId` string, `spentAt` timestamp, `note` string ≤ 500 opsional, `createdAt` timestamp; hanya kunci itu); blok `match /categories/{id}` dan `match /expenses/{id}` ber-`isOwner` dan validasi; catch-all menjadi `sub != 'debts' && sub != 'categories' && sub != 'expenses'`.

- [ ] **Step 1: Tulis test gagal** di `rules.test.js` mengikuti gaya test hutang: kategori valid dan pengeluaran valid dari pemilik lolos; ditolak: pemilik lain, `amount` 0, `amount` string, `amount` desimal, kunci asing, `name` kosong, `name` 51 karakter (Review Focus 5), `note` 501 karakter, `spentAt` bukan timestamp; baca oleh pemilik lain ditolak; hapus oleh pemilik lolos; dan satu test bahwa tulis dokumen tak valid ke `users/u1/expenses/x` tidak lolos lewat catch-all.
- [ ] **Step 2: Jalankan** `cd firebase && npm test` — Expected: test baru FAIL (aturan longgar meloloskannya), test lama PASS.
- [ ] **Step 3: Implement** aturan di `firestore.rules`.
- [ ] **Step 4: Jalankan** `cd firebase && npm test` — Expected: semua PASS.
- [ ] **Step 5: Commit** `feat(rules): validate categories and expenses (US-09)`.

---

### Task 12: Dokumen, uji manual, penutup

**Files:**
- Modify: `docs/DATABASE.md`, `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`, `docs/TESTING.md`, `docs/DIAGRAMS.md` (hanya bila ada perubahan alur), `docs/PRD.md` (centang kriteria US-09), `CHANGELOG.md`, `TODO.md`

- [ ] **Step 1: DATABASE.md bagian 6:** tambah definisi minggu (Senin–Minggu, dibatasi akhir siklus), siklus dinamai bulan awalnya, ID kategori default tetap, dan catatan bahwa jatah harian memakai sisa setelah pengeluaran hari ini. **DECISIONS.md:** ADR-016 (rumus apa adanya + definisi minggu/siklus) dan ADR-017 (kategori default ber-ID tetap, seeding idempoten dan diserialkan, risiko perangkat baru offline pertama kali). **ARCHITECTURE.md:** `domain/budget`, `BudgetDataSource`, `CategoryRepository`, `ExpenseRepository`, cubit budget.
- [ ] **Step 2: TESTING.md** tambah daftar uji manual 4a: catat pengeluaran tiga ketukan, nominal tempelan `Rp 1.500.000`, offline lalu sinkron, arsip kategori yang sudah dipakai, hapus pengeluaran, kategori default muncul sekali saat dua perangkat/masuk ulang.
- [ ] **Step 3: Gerbang akhir:** `dart format lib test`, `flutter analyze` (Expected: 0 isu), `flutter test` (Expected: semua hijau; catat jumlahnya), `cd firebase && npm test` (Expected: semua hijau). Coverage domain `lib/domain/budget` harus 100%: `flutter test --coverage` lalu periksa `coverage/lcov.info` untuk berkas `lib/domain/budget/*`.
- [ ] **Step 4: TODO.md:** centang "Kategori default dan kelola kategori", "Catat pengeluaran", dan "Domain: kalkulasi jatah aman"; isi log selesai dengan jumlah test; ubah "Sedang dikerjakan" ke Fase 4b (budget bulanan, Beranda jatah, peringatan, dampak ke pelunasan). **CHANGELOG.md:** tambah entri Ditambahkan (kategori, catat pengeluaran, domain jatah aman).
- [ ] **Step 5: Commit** `docs: close phase 4a (US-09, US-10)`.

---

## Self-review

- **Cakupan spec:** 2.1→Task 1, 2.2/2.3→Task 3, 2.4→Task 2, 3.1→Task 4, 3.2→Task 5, 3.3→Task 6, 4.1→Task 8, 4.2→Task 9, 4.3→Task 10, 5→Task 11, 7→Task 12, bagian 6 (tes) tersebar di tiap task. Wiring (Task 7) mendukung semuanya.
- **Penyimpangan dari spec (ruling):** (1) `ensureDefaults` dipanggil dari `CategoriesCubit.start()` dengan flag memori di repository sehingga tidak berulang, bukan "sekali setelah masuk" (alasan: cubit adalah pemilik state kategori; idempoten). (2) Siklus di UI memakai `defaultBudgetCycleStartDay = 1` karena `budgetCycleStartDay` belum punya UI atau pembacaan di profil sampai 4b.
- **Konsistensi tipe:** `BudgetCycle.of/remainingDays/contains` (Task 1) dipakai Task 3, 6, 9; `Expense`/`Category` (Task 2) dipakai Task 3–10; `CategoriesCubit.start/active/add/rename/setArchived` (Task 8) dipakai Task 9 dan 10; `writeErrors` pada kedua repository dipakai Task 7.
