# Fase 2 — Hutang & Pembayaran: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pengguna bisa menambah, melihat, mengubah, mengarsipkan, dan menghapus hutang/piutang (pinjol, cicilan, teman), melihat jadwal cicilan dan progres, serta mencatat dan membatalkan pembayaran secara atomik (US-01 s.d. US-05).

**Architecture:** Semua perhitungan uang (total, jadwal, penerapan pembayaran) berada di `lib/domain` sebagai fungsi murni yang diuji lebih dulu (TDD). `DebtRepository` memetakan domain ↔ Firestore dan menulis lewat `WriteBatch` (bukan transaksi, supaya jalan offline). Bloc/Cubit per layar; layar memakai komponen bersama (`MoneyText`, `DebtCard`, `AmountField`, dst. dari `docs/UI-UX.md` bagian 7).

**Tech Stack:** Sama dengan Fase 1, ditambah dev dependency `fake_cloud_firestore` untuk test repository. Test rules memakai emulator (`firebase/`).

**Spec:** `docs/PRD.md` (US-01..05, FR-02..04), `docs/DATABASE.md` (3.2, 3.3, 3.4, 5, 6, 7), `docs/ARCHITECTURE.md` (3, 4.1), `docs/UI-UX.md` (alur tambah hutang, catat pembayaran, daftar hutang, komponen), `docs/TESTING.md` (bagian 3: kasus uji wajib), `docs/DECISIONS.md` (ADR-007 uang `int`).

## Global Constraints

- Semua yang tertulis di Global Constraints Fase 1 tetap berlaku (lint 0 isu, ARB tanpa string UI hardcoded, tanpa warna/ukuran literal di widget, urutan dependensi searah, `lib/domain` bebas Flutter/Firebase, format `Rp1.250.000` dan `9 Nov 2026`, tanpa `push` kecuali diminta).
- Uang = `Money` (`int` rupiah). Pembulatan `round half up` di domain; selisih pembulatan jadwal masuk cicilan **terakhir** (ADR-007, `DATABASE.md` bagian 6).
- Nilai enum persis seperti `DATABASE.md` 3.2: `direction` `owe|lent`; `kind` `pinjol|installment|personal`; `interestType` `none|flat_monthly|flat_daily|reducing_monthly`; `frequency` `monthly|weekly|once`; `status` `active|settled|archived`. ID cicilan di Firestore zero-pad 3 digit (`"001"`).
- Rumus (`DATABASE.md` bagian 6): `none`: `principal + adminFee`; `flat_monthly`: `principal + round(principal × rate% × bulan) + adminFee`; `flat_daily`: `principal + round(principal × rate% × hari) + adminFee`; `reducing_monthly`: `A = P·r / (1 − (1+r)^−n)`, `totalPayable = A × n + adminFee`. `remaining = max(0, totalPayable − paidTotal)`.
- "Terlambat" tidak disimpan: `status == active && nextDueDate < hari ini` (hari ini = tanggal tanpa jam).
- Tulis ke Firestore memakai `WriteBatch` yang atomik. `commit()` Firestore baru selesai setelah server menjawab, jadi **tidak boleh di-`await` oleh UI**: UI mengikuti stream lokal (latency compensation); kegagalan dicatat dan ditampilkan lewat state error.
- Pesan UI suportif dan tidak menghakimi (`docs/UI-UX.md` bagian 6). Target sentuh ≥ 48 dp, status tidak hanya lewat warna, label semantik pada kartu hutang.
- Setiap task: centang item terkait di `TODO.md`, isi Log selesai, `flutter analyze` 0 isu, `flutter test` hijau sebelum commit.

## Review Focus

1. Jadwal bulanan dari tanggal 31 Jan: 28/29 Feb lalu 31 Mar (tidak "melorot" ke tanggal 28 seterusnya); tahun kabisat; mingguan melintasi pergantian tahun. *(Task 2)*
2. Pembayaran persis sama dengan sisa melunasi hutang; satu rupiah lebih ditolak; menghapus pembayaran dari hutang yang sudah lunas mengaktifkannya lagi dengan nilai persis seperti sebelum dibayar. *(Task 3, 8)*
3. Bunga 0, tenor 1, pokok sangat besar (`Rp999.999.999.999`) tidak membagi nol, tidak negatif, dan jumlah semua cicilan selalu sama dengan `totalPayable`. *(Task 1, 2)*
4. Mode pesawat: tambah hutang lalu catat pembayaran; layar tidak macet menunggu server, data tampil dari cache, dan tersinkron saat online (tidak ada penggandaan). *(Task 4, 8)*
5. Input form jelek: pokok 0 atau negatif, nama pihak kosong/hanya spasi, tenor 0, bunga negatif, nominal bayar kosong ditolak dengan pesan di kolomnya; angka dengan pemisah ribuan (`1.500.000`) terbaca benar. *(Task 6, 8)*

---

## File Structure

```
lib/domain/debt/debt_enums.dart          Task 1  (enum + parse/serialize)
lib/domain/debt/debt.dart                Task 1  (Debt, Installment, Payment)
lib/domain/debt/interest.dart            Task 1  (calculateTotalPayable)
lib/domain/debt/schedule.dart            Task 2  (generateSchedule, addPeriod)
lib/domain/debt/payments.dart            Task 3  (replayPayments + errors)
lib/data/debt_dto.dart                   Task 4
lib/data/firestore_paths.dart            Task 4
lib/data/debt_data_source.dart           Task 4
lib/repositories/debt_repository.dart    Task 4
firestore.rules (+ firebase/test)        Task 4
lib/shared/widgets/*.dart                Task 5  (MoneyText, StatusChip, ProgressBar, EmptyState, ConfirmDialog)
                                         Task 6  (AmountField)
lib/features/debts/                      Task 5-7, 9
lib/features/payments/                   Task 8
```

---

### Task 1: Model domain hutang dan total yang harus dibayar

**Files:**
- Create: `lib/domain/debt/debt_enums.dart`, `lib/domain/debt/debt.dart`, `lib/domain/debt/interest.dart`
- Test: `test/domain/debt/interest_test.dart`, `test/domain/debt/debt_test.dart`

**Interfaces:**
- Consumes: `Money` (`lib/domain/money.dart`).
- Produces:
  - Enum `DebtDirection {owe, lent}`, `DebtKind {pinjol, installment, personal}`, `InterestType {none, flatMonthly, flatDaily, reducingMonthly}`, `Frequency {monthly, weekly, once}`, `DebtStatus {active, settled, archived}`, `InstallmentStatus {pending, partial, paid}`; masing-masing punya `String get wire` (nilai Firestore persis `DATABASE.md`) dan `static T fromWire(String)` yang melempar `ArgumentError` untuk nilai tak dikenal.
  - `final class Installment extends Equatable { const Installment({required int seq, required DateTime dueDate, required Money amount, Money paidAmount = Money.zero, InstallmentStatus status = pending, DateTime? paidAt}) }` dengan `copyWith`.
  - `final class Payment extends Equatable { const Payment({required String id, required Money amount, required DateTime paidAt, int? installmentSeq, String? note, DateTime? createdAt}) }`.
  - `final class Debt extends Equatable` dengan semua field `DATABASE.md` 3.2 (`id`, `direction`, `kind`, `counterpartyName`, `note`, `principal`, `interestType`, `interestRate` (double), `adminFee`, `tenorCount`, `frequency`, `startDate`, `totalPayable`, `paidTotal`, `remaining`, `nextDueDate`, `status`, `createdAt`, `updatedAt`, `settledAt`), `copyWith`, dan `bool isOverdue(DateTime today)`.
  - `Money calculateTotalPayable({required Money principal, required InterestType interestType, required double interestRate, required Money adminFee, int periods = 1})` — `periods` = jumlah bulan (flat/reducing monthly) atau jumlah hari (flat_daily); diabaikan untuk `none`. Melempar `ArgumentError` bila `principal <= 0`, `interestRate < 0`, `adminFee < 0`, atau `periods < 1`.

- [ ] **Step 1: Write failing tests**
  - `interest_test.dart` (nilai dari `docs/TESTING.md` bagian 3): `none` → `principal + adminFee`; flat bulanan pokok 1.000.000, 3%, 3 bulan → bunga 90.000 (total 1.090.000); flat harian 1.000.000, 0,4%, 30 hari → bunga 120.000; anuitas pokok 12.000.000, 2%/bulan, 12 bulan → `A = 1.134.715` (nilai referensi: `12e6·0.02 / (1 − 1.02^−12)` = 1.134.715,09 → 1.134.715), total `13.616.580`; dua kombinasi anuitas lain dengan nilai referensi dari spreadsheet, ditulis sebagai konstanta di test beserta rumusnya di komentar; `interestRate 0` dengan `reducing_monthly` dan `periods 1` tidak membagi nol (total = pokok + biaya); `periods 1` benar; pokok `999999999999` tidak overflow dan tidak negatif; argumen tidak sah melempar `ArgumentError`; `round half up` (mis. bunga 12,5 → 13).
  - `debt_test.dart`: `isOverdue` benar bila aktif dan `nextDueDate` sebelum hari ini; salah pada hari yang sama, bila `settled`/`archived`, atau `nextDueDate == null`; `fromWire` menolak nilai tak dikenal; `wire` bolak-balik untuk semua enum.
- [ ] **Step 2: Run** `flutter test test/domain/debt` → FAIL (file belum ada).
- [ ] **Step 3: Implement** ketiga file sesuai Interfaces. Gunakan aritmetika `int` dan satu pembulatan `round half up` per komponen bunga (untuk anuitas, pembulatan `A` ke rupiah terdekat).
- [ ] **Step 4: Run** `flutter test test/domain/debt` → PASS; `flutter analyze` bersih; coverage `lib/domain/debt` 100%.
- [ ] **Step 5: Commit** `feat(domain): add debt model and total payable calculation (US-01)`

---

### Task 2: Generator jadwal cicilan

**Files:**
- Create: `lib/domain/debt/schedule.dart`
- Test: `test/domain/debt/schedule_test.dart`

**Interfaces:**
- Consumes: `Money`, `Installment`, `Frequency` (Task 1).
- Produces:
  - `DateTime addPeriods(DateTime anchor, Frequency frequency, int count)` — bulanan: tanggal sama bulan ke-`count` dari **anchor** dipangkas ke hari terakhir bulan itu; mingguan: `+7×count` hari; `once`: `anchor`.
  - `List<Installment> generateSchedule({required Money totalPayable, required int count, required Frequency frequency, required DateTime firstDueDate})` — cicilan 1..count, `amount = totalPayable ~/ count` untuk semua kecuali yang terakhir yang menyerap sisa; jatuh tempo ke-`i` = `addPeriods(firstDueDate, frequency, i-1)`; status `pending`, `paidAmount` nol. Melempar `ArgumentError` bila `count < 1` atau `totalPayable <= 0`.
  - `DateTime? nextDueDate(List<Installment> installments)` — jatuh tempo cicilan tak-`paid` terdekat, `null` bila semua `paid` atau daftar kosong.

- [ ] **Step 1: Write failing tests** (`docs/TESTING.md` bagian 3, Review Focus 1 dan 3):
  - Bulanan dari 31 Jan 2026, 4 cicilan → 31 Jan, 28 Feb, 31 Mar, 30 Apr (anchor dipertahankan, tidak melorot).
  - Bulanan dari 31 Jan 2028 (kabisat) → 31 Jan, 29 Feb, 31 Mar.
  - Bulanan dari 29 Feb 2028: cicilan ke-13 jatuh 28 Feb 2029 (hari 29 dipangkas ke akhir bulan).
  - Mingguan dari 28 Des 2026, 3 cicilan → 28 Des, 4 Jan 2027, 11 Jan 2027.
  - `totalPayable 1.000.000`, 3 cicilan → 333.333, 333.333, 333.334; jumlah selalu sama dengan `totalPayable` (uji properti pada beberapa total dan count, termasuk `999999999999` dan `count 1`).
  - `count 1`; `frequency once` menghasilkan satu cicilan di `firstDueDate`.
  - `nextDueDate`: semua pending → cicilan pertama; cicilan 1 `paid` → cicilan 2; semua `paid` → `null`; kosong → `null`.
  - Argumen tidak sah melempar `ArgumentError`.
- [ ] **Step 2: Run** `flutter test test/domain/debt/schedule_test.dart` → FAIL.
- [ ] **Step 3: Implement** ketiga fungsi; `addPeriods` menghitung dari `anchor` (bukan dari tanggal cicilan sebelumnya) agar tidak melorot.
- [ ] **Step 4: Run** test → PASS; analyze bersih; coverage `lib/domain/debt` 100%.
- [ ] **Step 5: Commit** `feat(domain): add installment schedule generator (US-01)`

---

### Task 3: Penerapan dan pembatalan pembayaran (domain)

**Files:**
- Create: `lib/domain/debt/payments.dart`
- Test: `test/domain/debt/payments_test.dart`

**Interfaces:**
- Consumes: `Debt`, `Installment`, `Payment`, `Money`, `nextDueDate` (Task 1, 2).
- Produces:
  - `sealed class PaymentError implements Exception` dengan `InvalidPaymentAmount` (nominal ≤ 0), `PaymentExceedsRemaining({required Money remaining})`, `UnknownInstallment({required int seq})`.
  - `final class DebtState { const DebtState({required Debt debt, required List<Installment> installments}) }`.
  - `DebtState replayPayments({required Debt debt, required List<Installment> installments, required List<Payment> payments, DateTime? now})` — mengembalikan keadaan dari nol: semua `paidAmount` direset lalu `payments` diterapkan berurutan menurut `paidAt` lalu `createdAt`. Pembayaran dengan `installmentSeq` mengisi cicilan itu (kelebihan melimpah ke cicilan tak-`paid` berikutnya); tanpa `installmentSeq` mengisi cicilan tak-`paid` berurutan dari yang paling awal. Status cicilan `pending|partial|paid` dan `paidAt`; `debt.paidTotal`, `debt.remaining = max(0, totalPayable − paidTotal)`, `debt.nextDueDate = nextDueDate(...)`; `status` menjadi `settled` (+ `settledAt = now`) saat `remaining == 0`, kembali `active` (`settledAt = null`) bila sisa > 0 dan sebelumnya `settled`; `archived` tidak diubah. Melempar `PaymentExceedsRemaining` bila jumlah pembayaran melebihi `totalPayable`, `InvalidPaymentAmount` untuk nominal ≤ 0, `UnknownInstallment` bila `installmentSeq` tak ada.
  - `DebtState applyPayment({required DebtState state, required List<Payment> existing, required Payment payment, DateTime? now})` = `replayPayments` atas `[...existing, payment]` setelah memeriksa `payment.amount <= state.debt.remaining` (jika tidak: `PaymentExceedsRemaining`).
  - `DebtState revertPayment({required DebtState state, required List<Payment> existing, required String paymentId, DateTime? now})` = `replayPayments` tanpa pembayaran itu.

- [ ] **Step 1: Write failing tests** (`docs/TESTING.md` bagian 3, Review Focus 2):
  - Bayar penuh satu cicilan → `paid`, `nextDueDate` maju ke cicilan berikut.
  - Bayar sebagian → `partial`, sisa cicilan benar (`amount − paidAmount`).
  - Bayar tanpa `installmentSeq` mengisi cicilan pertama dahulu, lalu melimpah ke berikutnya.
  - Bayar persis sisa → `settled`, `remaining 0`, `settledAt` terisi, `nextDueDate null`.
  - Bayar `remaining + 1` → `PaymentExceedsRemaining` dengan `remaining` benar; nominal `0` dan negatif → `InvalidPaymentAmount`; `installmentSeq` tak ada → `UnknownInstallment`.
  - `revertPayment` mengembalikan `Debt` dan semua `Installment` **persis sama** (`==`) dengan keadaan sebelum pembayaran itu dicatat (uji dengan 3 pembayaran, hapus yang tengah dan yang terakhir).
  - Menghapus pembayaran dari hutang `settled` → kembali `active`, `settledAt null`.
  - Hutang tanpa cicilan (daftar kosong, mis. pinjaman teman bebas tempo): `applyPayment` hanya mengubah `paidTotal/remaining/status`; `nextDueDate` tetap `null`.
  - Hutang `archived` tetap `archived` setelah pembayaran/penghapusan.
- [ ] **Step 2: Run** `flutter test test/domain/debt/payments_test.dart` → FAIL.
- [ ] **Step 3: Implement** — `replayPayments` adalah satu-satunya tempat logika; `applyPayment` dan `revertPayment` tipis di atasnya.
- [ ] **Step 4: Run** test → PASS; analyze bersih; coverage `lib/domain/debt` 100%.
- [ ] **Step 5: Commit** `feat(domain): add payment application and revert (US-05)`

---

### Task 4: DTO, repository hutang, dan security rules

**Files:**
- Create: `lib/data/firestore_paths.dart`, `lib/data/debt_dto.dart`, `lib/data/debt_data_source.dart`, `lib/repositories/debt_repository.dart`
- Modify: `pubspec.yaml` (dev: `fake_cloud_firestore`), `firestore.rules`, `firebase/test/rules.test.js`, `docs/DATABASE.md` (bagian 5), `docs/DECISIONS.md` (ADR-013)
- Test: `test/data/debt_dto_test.dart`, `test/repositories/debt_repository_test.dart`

**Interfaces:**
- Consumes: semua dari Task 1–3; `AppUser`/uid dari `AuthBloc` state.
- Produces:
  - `FirestorePaths`: `debts(uid)`, `debt(uid, id)`, `installments(uid, debtId)`, `payments(uid, debtId)`; `String installmentId(int seq)` → zero-pad 3 digit.
  - `DebtDto`: `Map<String, Object?> debtToMap(Debt)`, `Debt debtFromMap(String id, Map<String, Object?>)`, `installmentToMap/FromMap`, `paymentToMap/FromMap` (timestamp ↔ `DateTime`, `Money` ↔ `int`, enum ↔ `wire`).
  - `class NewDebt` (input pembuatan): `direction, kind, counterpartyName, note, principal, interestType, interestRate, adminFee, tenorCount, frequency, startDate, firstDueDate?` (jadwal dibuat di repository lewat Task 1–2); `class DebtDraft` tidak diperlukan.
  - `abstract interface class DebtRepository`:
    - `Stream<List<Debt>> watchDebts()`; `Stream<Debt?> watchDebt(String id)`; `Stream<List<Installment>> watchInstallments(String debtId)`; `Stream<List<Payment>> watchPayments(String debtId)`;
    - `Future<String> addDebt(NewDebt input)` — membuat id lokal dan menulis `debt + semua installments` dalam satu batch;
    - `Future<void> updateDebt(Debt debt, {List<Installment>? schedule})` — bila `schedule` diberikan, hitung ulang lewat `replayPayments` terhadap pembayaran yang ada;
    - `Future<void> recordPayment({required String debtId, required Money amount, required DateTime paidAt, int? installmentSeq, String? note})` — batch: `payments + installments + debt` memakai `applyPayment`;
    - `Future<void> deletePayment({required String debtId, required String paymentId})` — batch memakai `revertPayment`;
    - `Future<void> setArchived(String debtId, {required bool archived})`; `Future<void> deleteDebt(String debtId)` (hapus `payments`, `installments`, lalu dokumen, dalam batch berpotongan ≤ 450 operasi).
  - `class DebtRepositoryImpl(DebtDataSource, {required String Function() currentUid, DateTime Function() now})`. Repository **membaca** keadaan terkini dengan `get()` lalu menulis dengan `WriteBatch` (bukan transaksi; ADR-013). Method tulis memulai `commit()` tanpa menunggu ack server (lihat Global Constraints); kegagalan komit dicatat lewat `developer.log` dan dikirim ke `Stream` error `writeErrors`.
  - Rules: di `users/{uid}/debts/{debtId}`, `installments/{seq}`, `payments/{pid}` — tulis hanya bila `isOwner` dan memenuhi: debts: kunci hanya field `DATABASE.md` 3.2; enum bernilai sah; `principal` int > 0; `adminFee` int ≥ 0; `interestRate` angka 0–1000; `paidTotal` int ≥ 0; `remaining` int ≥ 0; `counterpartyName` string 1–100; `note` ≤ 500; installments: `amount` int > 0, `paidAmount` int 0..amount, `status` sah; payments: `amount` int > 0, `paidAt` timestamp. Baca tetap hanya pemilik. Rules untuk `categories/expenses/budgets` tetap seperti Fase 1 sampai fasenya.

- [ ] **Step 1: Write failing tests**
  - `debt_dto_test`: bolak-balik `Debt`, `Installment`, `Payment` (termasuk field null, `Money` besar, `interestRate` desimal); `installmentId(7) == '007'`.
  - `debt_repository_test` (pakai `fake_cloud_firestore`): `addDebt creates debt and all installments atomically` (tenor 3 → 1 debt + 3 cicilan, `sum(amount) == totalPayable`, `nextDueDate` = cicilan 1, `remaining == totalPayable`); `addDebt without tenor creates debt without installments`; `recordPayment updates payment installment and debt together`; `recordPayment over remaining throws PaymentExceedsRemaining and writes nothing`; `deletePayment restores exact previous values`; `recording last payment settles debt`; `setArchived`; `deleteDebt removes subcollections`; `watchDebts emits sorted by nextDueDate then name`; `uses current uid path` (uid berbeda → data terpisah).
  - Rules (`firebase/test/rules.test.js`): satu test per aturan di atas — `owner can create valid debt`, `other user cannot read debt`, `principal 0 denied`, `unknown direction denied`, `remaining negative denied`, `unknown field denied`, `installment paidAmount greater than amount denied`, `payment amount 0 denied`, `payment with string amount denied`, `valid payment allowed`.
- [ ] **Step 2: Run** `flutter test test/data test/repositories/debt_repository_test.dart` dan `cd firebase && npm test` → FAIL (sebelum rules diperketat, test penolakan gagal).
- [ ] **Step 3: Implement** path, DTO, data source, repository, dan rules; tambah `fake_cloud_firestore` ke dev dependency.
- [ ] **Step 4: Run** semua test + `npm test` → PASS; analyze bersih.
- [ ] **Step 5: Docs** — `DATABASE.md` bagian 5 (rules Fase 2) dan ADR-013 (`WriteBatch` bukan transaksi karena harus jalan offline; `commit()` tidak di-await UI).
- [ ] **Step 6: Commit** `feat(data): add debt repository with atomic batch writes and rules (US-01, US-05)`

---

### Task 5: Daftar hutang (US-02) dan komponen bersama

**Files:**
- Create: `lib/shared/widgets/{money_text,status_chip,progress_bar,empty_state,confirm_dialog}.dart`, `lib/features/debts/bloc/debts_cubit.dart`, `lib/features/debts/view/debts_page.dart`, `lib/features/debts/widgets/debt_card.dart`
- Modify: `lib/app/app.dart` + `lib/bootstrap.dart` (sediakan `DebtRepository`), `lib/l10n/app_id.arb`, `lib/features/debts/view/debts_page.dart` (ganti placeholder)
- Test: `test/features/debts/debts_cubit_test.dart`, `test/features/debts/debts_page_test.dart`, `test/shared/widgets/*_test.dart`

**Interfaces:**
- Consumes: `DebtRepository.watchDebts()` (Task 4), `Debt.isOverdue`, `formatRupiah`, `formatDate`.
- Produces:
  - `enum DebtFilter {active, settled}`; `DebtsState({required List<Debt> owe, required List<Debt> lent, required Money oweRemaining, required Money lentRemaining, required DebtFilter filter, required DebtsStatus status})` dengan `enum DebtsStatus {loading, loaded, failure}`.
  - `DebtsCubit(DebtRepository)`: `start()` berlangganan `watchDebts`, `setFilter(DebtFilter)`. `active` = `status == active`; `settled` = `settled` (hutang `archived` tidak tampil di daftar). Urutan: terlambat dulu, lalu `nextDueDate` terdekat, lalu nama. Total sisa dihitung dari kelompok yang tampil.
  - Widget: `MoneyText(Money, {style})` (format rupiah, teks semantik lengkap), `StatusChip` (label + ikon: Terlambat / Jatuh tempo dekat / Lunas / Aktif — bukan hanya warna), `ProgressBar(value 0..1)`, `EmptyState({icon, message, actionLabel, onAction})`, `ConfirmDialog.show(context, {title, body, confirmLabel}) → Future<bool>`.
  - `DebtCard(Debt)` dengan `Semantics(label: "Pinjol B, sisa satu juta lima ratus ribu rupiah, jatuh tempo 18 November")`.
  - Halaman: dua tab "Aku berutang" / "Piutang" dengan total sisa di atas tiap tab, `ChoiceChip` filter Aktif/Lunas, state kosong "Tambah hutang pertamamu", FAB tidak dipakai (tombol tambah ada di menu `+`).

- [ ] **Step 1: Write failing tests**: cubit — `groups by direction`, `filter settled shows only settled`, `archived are hidden`, `overdue first then nearest due`, `totals sum remaining of shown group`, `emits failure when stream errors`; widget — `shows empty state with action`, `shows total remaining on top of each tab`, `overdue card shows Terlambat chip with icon`, `card semantics label reads amount in words` (cukup kalimat yang memuat nama, "sisa", dan tanggal), `tapping card navigates to /debts/{id}`, `no overflow at text scale 2.0 on 360x640`; komponen — satu test render per widget.
- [ ] **Step 2: Run** `flutter test test/features/debts test/shared/widgets` → FAIL.
- [ ] **Step 3: Implement** komponen, cubit, kartu, halaman; tambah string ke ARB; sediakan `DebtRepository` di `App` dan `bootstrap()`; rute `/debts/:id` sementara menuju placeholder (diisi Task 7).
- [ ] **Step 4: Run** `flutter test`; `flutter analyze` bersih.
- [ ] **Step 5: TODO + commit** `feat(debts): add debt list with owe/lent tabs and filters (US-02)`

---

### Task 6: Form tambah dan ubah hutang (US-01, US-04)

**Files:**
- Create: `lib/shared/widgets/amount_field.dart`, `lib/shared/parse_amount.dart`, `lib/features/debts/bloc/debt_form_cubit.dart`, `lib/features/debts/view/debt_form_page.dart`
- Modify: `lib/app/router.dart` (rute `/debts/new`, `/debts/:id/edit`), `lib/features/shell/add_menu_sheet.dart` (Tambah hutang → `/debts/new`), `lib/l10n/app_id.arb`
- Test: `test/shared/parse_amount_test.dart`, `test/features/debts/debt_form_cubit_test.dart`, `test/features/debts/debt_form_page_test.dart`

**Interfaces:**
- Consumes: `calculateTotalPayable`, `generateSchedule`, `addPeriods` (Task 1–2), `DebtRepository.addDebt/updateDebt` (Task 4).
- Produces:
  - `Money? parseAmount(String)` — menerima `1.500.000`, `1500000`, `Rp1.500.000`, spasi; mengembalikan `null` untuk kosong, huruf, atau nilai ≤ 0 atau > 999.999.999.999. `AmountField` memformat pemisah ribuan saat mengetik, keypad angka.
  - `DebtFormCubit(DebtRepository, {Debt? editing})`: setter per field; pratinjau `previewTotal`, `previewSchedule` (diperbarui real-time); `submit()`; state `DebtFormState` dengan `FieldError?` per kolom (`ValidationError` dari Fase 1 + `invalidNumber`, `mustBePositive`), `SubmitStatus`.
  - Aturan: wajib arah, jenis, nama pihak (trim, 1–100), pokok > 0, tanggal mulai. `personal`: bunga/tenor boleh kosong; tenor kosong → tanpa jadwal, jatuh tempo opsional (satu cicilan bila diisi). `pinjol|installment`: tenor ≥ 1 bila bunga bukan `none`. `flat_daily`: kolom tenor berarti jumlah **hari**, frequency `once`, satu cicilan di `startDate + hari`; tipe lain tenor = jumlah cicilan. Bunga ≥ 0; biaya admin ≥ 0.
  - Mode ubah: bila hutang sudah punya pembayaran, perubahan pokok/bunga/tenor menghitung ulang jadwal; peringatan jelas bahwa cicilan terbayar mengikuti pembayaran yang ada; tidak boleh menurunkan `totalPayable` di bawah `paidTotal` (pesan di kolom).
  - Halaman: alur sesuai `docs/UI-UX.md` ("pilih arah → jenis → isi → pratinjau jadwal dan total → simpan"); layar scrollable, aman pada teks 2.0; kolom bunga/tenor tampil sesuai jenis.

- [ ] **Step 1: Write failing tests** (Review Focus 3 dan 5): `parseAmount` — `'1.500.000'`, `'1500000'`, `'Rp 1.500.000'`, `' 2000 '` sah; `''`, `'abc'`, `'0'`, `'-5'`, `'1.000.000.000.000'` → `null`; cubit — `empty name is rejected` (juga `'   '`), `principal zero rejected`, `tenor zero rejected for installment`, `negative interest rejected`, `personal without tenor creates no schedule`, `flat_daily creates single installment at start plus days`, `preview total matches calculateTotalPayable`, `preview schedule sums to total`, `submit calls addDebt once with trimmed name`, `edit cannot lower total below paidTotal`, `edit with payments recomputes schedule`, `submit failure shows error and keeps input`; widget — `shows field errors on empty submit`, `typing 1500000 shows 1.500.000`, `kind personal hides interest and tenor fields`, `preview updates when tenor changes`, `no overflow at text scale 2.0 on 360x640`, `menu Tambah hutang opens form`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** parser, `AmountField`, cubit, halaman, rute, dan penautan menu `+`.
- [ ] **Step 4: Run** `flutter test`; analyze bersih.
- [ ] **Step 5: TODO + commit** `feat(debts): add debt form with live schedule preview (US-01, US-04)`

---

### Task 7: Detail hutang (US-03)

**Files:**
- Create: `lib/features/debts/bloc/debt_detail_cubit.dart`, `lib/features/debts/view/debt_detail_page.dart`
- Modify: `lib/app/router.dart` (rute `/debts/:id`), `lib/l10n/app_id.arb`
- Test: `test/features/debts/debt_detail_cubit_test.dart`, `test/features/debts/debt_detail_page_test.dart`

**Interfaces:**
- Consumes: `DebtRepository.watchDebt/watchInstallments/watchPayments`, komponen Task 5.
- Produces:
  - `DebtDetailState({required Debt? debt, required List<Installment> installments, required List<Payment> payments, required DebtDetailStatus status})` dengan `enum DebtDetailStatus {loading, loaded, notFound, failure}`; `DebtDetailCubit(DebtRepository, String debtId)` menggabungkan tiga stream (tanpa paket tambahan: tiga `StreamSubscription` yang diperbarui dan di-cancel di `close()`); getter `double progress` = `paidTotal / totalPayable` (0 bila total 0).
  - Halaman: header (nama, jenis, arah, `StatusChip`), sisa besar (`MoneyText`), `ProgressBar` + "x dari y", tombol **Bayar** (→ `/debts/:id/pay`, diisi Task 8), bagian Jadwal (tiap cicilan: nomor, tanggal, nominal, status `Lunas/Sebagian/Belum`), bagian Riwayat pembayaran (tanggal, nominal, catatan, urut terbaru), menu ⋮ (Ubah, Arsipkan, Hapus — aksi diisi Task 9). State `notFound` menampilkan pesan dan tombol kembali.

- [ ] **Step 1: Write failing tests**: cubit — `combines debt installments and payments`, `progress is 0 when total is 0 and 0.5 at half`, `notFound when debt missing`, `cancels subscriptions on close`; widget — `shows remaining and progress`, `lists installments with status labels`, `lists payments newest first`, `settled debt hides Bayar button and shows congratulation text`, `notFound shows message`, `semantic labels present`, `no overflow at text scale 2.0 on 360x640`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** cubit dan halaman; rute `/debts/:id`.
- [ ] **Step 4: Run** `flutter test`; analyze bersih.
- [ ] **Step 5: TODO + commit** `feat(debts): add debt detail with schedule and payment history (US-03)`

---

### Task 8: Catat dan batalkan pembayaran (US-05)

**Files:**
- Create: `lib/features/payments/bloc/payment_form_cubit.dart`, `lib/features/payments/view/payment_form_page.dart`, `lib/features/payments/view/debt_picker_sheet.dart`, `lib/features/payments/view/settled_celebration.dart`
- Modify: `lib/app/router.dart` (rute `/debts/:id/pay`), `lib/features/shell/add_menu_sheet.dart` (Catat pembayaran → pilih hutang → form), `lib/features/debts/view/debt_detail_page.dart` (hapus pembayaran dengan konfirmasi), `lib/l10n/app_id.arb`
- Test: `test/features/payments/payment_form_cubit_test.dart`, `test/features/payments/payment_form_page_test.dart`, `test/features/payments/debt_picker_sheet_test.dart`, `test/features/debts/debt_detail_payment_delete_test.dart`

**Interfaces:**
- Consumes: `DebtRepository.recordPayment/deletePayment/watchInstallments`, `parseAmount`, `AmountField` (Task 6), `PaymentExceedsRemaining` (Task 3).
- Produces:
  - `PaymentFormCubit(DebtRepository, {required Debt debt, required List<Installment> installments})`: nominal awal = sisa cicilan tak-`paid` terdekat (atau `remaining` bila tanpa cicilan); `amountChanged(String)`, `dateChanged(DateTime)` (default hari ini, tidak boleh lebih dari hari ini + 0), `noteChanged`, `installmentSelected(int?)`, `submit()`; kesalahan kolom: kosong/`≤ 0` ("Isi nominal pembayaran"), melebihi sisa ("Nominal melebihi sisa hutang (Rp…). Isi paling banyak sebesar sisa."), memakai `PaymentExceedsRemaining.remaining`.
  - Label arah: `owe` → "Aku bayar", `lent` → "Diterima dari {nama}".
  - `SettledCelebration`: dialog/overlay singkat "Lunas! Satu beban berkurang." (nada `docs/UI-UX.md` bagian 6), tampil bila `submit()` membuat `remaining == 0`.
  - `DebtPickerSheet` menampilkan hutang aktif (urutan seperti daftar) untuk memilih sebelum membuka form dari menu `+`; kosong → `EmptyState` dengan tombol Tambah hutang.

- [ ] **Step 1: Write failing tests** (Review Focus 2, 4, 5): cubit — `defaults amount to nearest unpaid installment remainder`, `defaults to remaining when no schedule`, `amount over remaining by 1 rupiah is rejected`, `amount equal to remaining succeeds and reports settled`, `empty or zero amount rejected`, `future date rejected`, `submit calls repository once even if tapped twice`, `lent direction uses received wording`; widget — `shows new remaining after submit`, `shows celebration when settled`, `dismissing celebration returns to detail`, `over-remaining shows message under field and does not call repository`, `deleting a payment asks for confirmation and calls deletePayment on confirm only`, `deleting last payment of settled debt reactivates it` (dengan repository fake yang memakai `revertPayment`), `picker lists only active debts`, `picker empty shows add-debt action`, `form does not wait for server: submit completes while repository commit future is pending` (repository fake yang `commit` tidak pernah selesai), `no overflow at text scale 2.0 on 360x640`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** cubit, halaman, picker, perayaan, rute, dan penautan menu `+` serta hapus pembayaran di detail.
- [ ] **Step 4: Run** `flutter test`; analyze bersih.
- [ ] **Step 5: TODO + commit** `feat(payments): add record and revert payment with celebration (US-05)`

---

### Task 9: Tandai lunas, arsip, hapus (US-04), gerbang kualitas Fase 2

**Files:**
- Create: `lib/features/debts/bloc/debt_actions_cubit.dart`
- Modify: `lib/features/debts/view/debt_detail_page.dart` (menu ⋮ aktif), `lib/l10n/app_id.arb`, `TODO.md`, `CHANGELOG.md`, `README.md`, `docs/DIAGRAMS.md` bila alur berubah
- Test: `test/features/debts/debt_actions_cubit_test.dart`, `test/features/debts/debt_actions_test.dart`

**Interfaces:**
- Consumes: `DebtRepository.setArchived/deleteDebt/recordPayment`, `ConfirmDialog`.
- Produces: `DebtActionsCubit(DebtRepository, String debtId)` dengan `archive()`, `unarchive()`, `delete()`, `markSettled()` (mencatat satu pembayaran sebesar sisa pada hari ini dengan catatan "Ditandai lunas"); state `ActionStatus {idle, working, done, failure}`. Menghapus dan mengarsipkan selalu lewat `ConfirmDialog`. Hutang `archived` tidak tampil di daftar Fase 2 (lihat Task 5); `unarchive()` disediakan di cubit tetapi belum punya layar, dan itu dicatat di `TODO.md` sebagai pekerjaan Fase 6.

- [ ] **Step 1: Write failing tests**: cubit — `archive calls repository`, `delete calls repository and reports done`, `markSettled records exact remaining payment`, `markSettled on already settled debt does nothing`, `failure reports failure`; widget — `delete asks for confirmation; cancel does nothing`, `confirming delete returns to list and debt is gone`, `archive hides debt from list`, `markSettled settles and shows celebration`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** cubit dan hubungkan menu ⋮.
- [ ] **Step 4: Gerbang kualitas:** `flutter analyze`, `dart format --set-exit-if-changed lib test`, `flutter test --coverage` (target `lib/domain` 100%, bloc/cubit ≥ 90%, total ≥ 80%; baca angkanya), `cd firebase && npm test`, `flutter build apk --debug`.
- [ ] **Step 5: Docs:** `TODO.md` (semua item Fase 2 tercentang, "Sedang dikerjakan" → Fase 3), `CHANGELOG.md`, `README.md` (status), `DATABASE.md`/`DIAGRAMS.md` bila skema atau alur bergeser.
- [ ] **Step 6: Commit** `docs: close phase 2 debts and payments`; langkah manual untuk user: jalankan checklist `docs/TESTING.md` bagian 5 butir "Mode pesawat: tambah hutang & bayar, lalu online → tersinkron" pada build terakhir (setelah rules di-deploy ke `geuralunas-dev`).

---

## Self-Review

**Cakupan spec:** US-01 (T1, T2, T4, T6), US-02 (T5), US-03 (T7), US-04 (T6 ubah, T9 arsip/hapus), US-05 (T3, T4, T8), FR-02..04 (T1–T4, T6). Bagian 3 `TESTING.md` (bunga, jadwal, pembayaran) dipetakan ke test T1–T3. Jatah aman/simulasi/pengingat bukan lingkup Fase 2.

**Konsistensi tipe:** `Debt`, `Installment`, `Payment`, `DebtState`, `NewDebt`, `DebtRepository`, `parseAmount`, `AmountField`, `MoneyText` dipakai dengan nama sama di T1–T9; `generateSchedule`/`addPeriods`/`nextDueDate` dari T2 dipakai T3, T4, T6.

**Proporsi:** rencana memuat keputusan (file, signature, nilai spec, nama test) tanpa isi fungsi.

**Keputusan yang perlu dicatat saat eksekusi:** `flat_daily` memakai tenor = hari dan satu cicilan (T1/T6); hutang `archived` tidak tampil di daftar Fase 2 (T5/T9); repository memakai `WriteBatch` dan tidak meng-`await` `commit()` (T4, ADR-013).
