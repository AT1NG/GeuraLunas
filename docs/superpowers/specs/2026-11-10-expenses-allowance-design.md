# Fase 4a — Kategori, Pengeluaran, dan Kalkulasi Jatah Aman: Spesifikasi Desain

Tanggal: 2026-11-10 · Status: menunggu review user

Mencakup bagian pertama dari Fase 4: US-09 (catat pengeluaran) lengkap, dan fondasi domain untuk US-10 dan US-11 (kalkulasi jatah aman). Budget bulanan, Beranda jatah, dan peringatan menyusul di Fase 4b dalam spesifikasi terpisah. Skema data dan rumus dasar ada di [DATABASE.md](../../DATABASE.md) bagian 3.5, 3.6, 3.7 dan 6; spesifikasi ini tidak mengulangnya kecuali ada keputusan baru.

## 1. Keputusan hasil brainstorming

1. **Fase 4 dipecah dua.** 4a: domain jatah aman (test dulu), kategori, catat pengeluaran. 4b: budget bulanan, Beranda jatah, peringatan, dampak ke pelunasan. Tiap tahap satu PR.
2. **Rumus jatah aman dipakai apa adanya.** `jatahHariIni = floor(sisaBulanan / sisaHariTermasukHariIni)`, dengan `sisaBulanan` sudah dikurangi pengeluaran hari ini. Konsekuensinya angka turun setiap kali pengguna mencatat pengeluaran. Tidak ada angka "terpakai hari ini" terpisah. Teks di 4b yang menjaga nada tetap suportif (US-11), bukan rumusnya.
3. **Minggu berjalan dari Senin sampai Minggu.** DATABASE.md belum mendefinisikan `sisaHariDalamMinggu`; keputusan ini menutup celah itu (lihat 2.3).
4. **Siklus bulan dinamai bulan awalnya.** Siklus yang mulai 25 Nov dan berakhir 24 Des punya ID `2026-11`. Ini mengisi celah "mengikuti `budgetCycleStartDay`" di DATABASE.md 3.7.
5. **4a tidak punya UI jatah.** Kalkulasi jatah aman hanya domain dan test di 4a. Dengan begitu rumus uang bisa ditinjau dan diuji sebelum ada layar yang memakainya (aturan CLAUDE.md nomor 4).

## 2. Domain (Dart murni, `lib/domain/budget/`)

Semua nominal `Money` (`int` rupiah). Tidak ada import Flutter atau Firebase.

### 2.1 Siklus

- `BudgetCycle({required DateTime start, required DateTime endInclusive})` dengan `String get id` (`yyyy-MM` dari bulan `start`) dan `bool contains(DateTime day)`.
- `BudgetCycle.of(DateTime day, {required int startDay})` (`startDay` 1 sampai 28). Bila `day.day >= startDay` siklus mulai pada `startDay` bulan itu, bila tidak mulai pada `startDay` bulan sebelumnya. Akhir siklus adalah sehari sebelum `startDay` bulan berikutnya. Semua tanggal dinormalisasi ke tengah malam waktu perangkat.
- `int remainingDays(DateTime today)`: jumlah hari dari `today` sampai akhir siklus, termasuk hari ini (minimal 1).

### 2.2 Jatah aman

```dart
SafeAllowance computeSafeAllowance({
  required BudgetCycle cycle,
  required DateTime today,
  required Money incomeTotal,
  required Money savingsTarget,
  required List<DebtState> debts,     // dipakai ulang dari domain/debt
  required List<Expense> expenses,    // pengeluaran milik siklus ini
});
```

`SafeAllowance` menyimpan: `status` (`ok` atau `installmentsExceedIncome`), `installmentsThisCycle`, `monthlyLimit`, `monthlyRemaining`, `todayAllowance`, `weekAllowance`, `remainingDays`.

- `installmentsThisCycle` = jumlah `amount − paidAmount` semua cicilan yang belum `paid`, milik hutang `owe` aktif, dengan `dueDate` di dalam siklus. Hutang `lent` dan yang tidak aktif tidak dihitung.
- `monthlyLimit = incomeTotal − installmentsThisCycle − savingsTarget`. Bila negatif, `status = installmentsExceedIncome` dan semua jatah 0 (tidak ada angka negatif).
- `monthlyRemaining = max(0, monthlyLimit − Σ expenses siklus)`. Pengeluaran di luar siklus diabaikan.
- `todayAllowance = floor(monthlyRemaining / remainingDays)`.
- `weekAllowance = min(monthlyRemaining, todayAllowance × daysLeftInWeek)`.
- Pembayaran hutang bukan pengeluaran. Cicilan yang sudah dibayar tidak lagi memotong jatah; cicilan yang jatuh tempo tetapi belum dibayar tetap memotong (DATABASE.md 3.6).

### 2.3 Minggu

`daysLeftInWeek` = jumlah hari dari `today` sampai Minggu terdekat (termasuk hari ini), dibatasi `remainingDays`. Hari Minggu memberi 1, hari Senin memberi 7. Pada hari terakhir siklus nilainya 1.

### 2.4 Entitas

- `Category({id, name, icon, colorHex, sortOrder, isDefault, archived})` dan `defaultCategories` (7 kategori DATABASE.md 3.5, dengan ID tetap: `makan`, `transport`, `belanja`, `tagihan`, `hiburan`, `kesehatan`, `lainnya`).
- `Expense({id, amount: Money, categoryId, spentAt, note?, createdAt})`. `amount` harus lebih dari 0; konstruktor menolak sebaliknya.

## 3. Data dan repository

### 3.1 Path dan DTO

`FirestorePaths` bertambah `categories(uid)`, `category(uid, id)`, `expenses(uid)`, `expense(uid, id)`. DTO baru `category_dto.dart` dan `expense_dto.dart` mengikuti `debt_dto.dart` (konversi `Timestamp`, tanpa logika bisnis).

### 3.2 `CategoryRepository`

`watchCategories()` (urut `sortOrder`, termasuk yang diarsipkan; filter dilakukan UI), `ensureDefaults()`, `add(name, icon, colorHex)`, `rename(id, name)`, `setArchived(id, bool)`.

- **`ensureDefaults()` idempoten dan diserialkan** lewat antrean `Future` seperti `ReminderRepositoryImpl` (pelajaran bug profil ganda di PR #4). Ia membaca koleksi; bila kosong menulis 7 default dalam satu `WriteBatch` dengan ID tetap. Dua pemanggilan bersamaan menulis dokumen yang sama sehingga tidak ada duplikat.
- Dipanggil sekali setelah masuk (dari pemilik state kategori), bukan saat membuka tiap layar.
- Kategori tidak pernah dihapus, hanya diarsipkan, sehingga pengeluaran lama selalu punya nama kategori.
- ID kategori buatan pengguna dari `collection().doc().id`. `sortOrder` = maksimum yang ada + 1.

### 3.3 `ExpenseRepository`

`watchExpenses(BudgetCycle cycle)` (kueri `spentAt` dalam rentang siklus, terbaru dulu), `add(...)`, `delete(id)`.

- Penulisan lewat `WriteBatch` dan UI tidak menunggu commit (ADR-013), sama seperti hutang.
- Edit pengeluaran tidak termasuk 4a (YAGNI): salah catat dihapus lalu dicatat ulang.

## 4. UI

Teks Indonesia, nada suportif, semua dari `app_id.arb`.

### 4.1 Catat pengeluaran (US-09)

- Menu tambah → "Catat pengeluaran" membuka sheet (sekarang hanya menutup). Isi: kolom nominal (fokus otomatis, format rupiah seperti form hutang), chip kategori (yang aktif, urut `sortOrder`), tombol Simpan. Tanggal bawaan hari ini dan catatan opsional ada di bagian "Lainnya" yang tertutup. Alur normal: nominal, kategori, Simpan (3 ketukan).
- Validasi: nominal wajib dan lebih dari 0; kategori wajib. Setelah simpan sheet menutup dan muncul snackbar singkat.
- Cubit `AddExpenseCubit` memegang nominal, kategori, tanggal, dan catatan.

### 4.2 Tab Budget (sementara)

Tab Budget sekarang placeholder. Di 4a ia menampilkan daftar pengeluaran siklus berjalan (terbaru dulu, dikelompokkan per hari), tombol hapus per baris dengan konfirmasi, state kosong yang ramah, dan tautan "Kelola kategori". 4b menambah ringkasan budget di atasnya.

### 4.3 Kelola kategori

Daftar kategori (aktif lalu diarsipkan), tambah (nama + ikon dari daftar kecil + warna dari daftar kecil), ubah nama, arsipkan dan pulihkan. Kategori default boleh diubah nama dan diarsipkan, tidak dihapus.

## 5. Security rules dan index

- `firestore.rules` mendapat `validCategory` dan `validExpense` (kunci yang diizinkan, tipe, `amount` int lebih dari 0, `name` 1 sampai 50 karakter, `note` paling banyak 500) dan blok `match` sendiri untuk `categories` dan `expenses`. Aturan catch-all `match /{sub}/{docId=**}` harus diubah menjadi `sub != 'debts' && sub != 'categories' && sub != 'expenses'`. Aturan Firestore digabung dengan OR, jadi tanpa pengecualian ini catch-all akan meloloskan tulis tak tervalidasi ke dua koleksi baru (tes rules menjaga hal ini). `budgets` tetap di aturan longgar sampai 4b.
- Index: kueri tunggal `spentAt` memakai index otomatis; tidak ada composite baru.
- Tes emulator rules ditambah untuk kategori dan pengeluaran valid dan tidak valid.

## 6. Tes

Test dulu untuk semua logika uang (domain), repository dengan `fake_cloud_firestore`, cubit dengan `bloc_test`, widget test untuk sheet dan layar.

- `BudgetCycle`: `startDay` 1 dan 28, awal dan akhir bulan, pergantian tahun, hari tepat di `startDay`, hari sebelumnya.
- `computeSafeAllowance`: tanpa cicilan, cicilan penuh vs sebagian dibayar, cicilan di luar siklus diabaikan, `lent` dan hutang tidak aktif diabaikan, `savingsTarget`, `monthlyLimit` negatif memberi status khusus dan jatah 0, pengeluaran melebihi sisa memberi 0 bukan negatif, pembulatan `floor`, hari terakhir siklus, hari Minggu dan Senin untuk `weekAllowance`, batas `weekAllowance` pada `monthlyRemaining`.
- `Expense`: menolak `amount <= 0`.
- Repository kategori: seeding sekali, dua `ensureDefaults()` bersamaan tidak menggandakan, arsip tidak menghapus, urutan `sortOrder`.
- Repository pengeluaran: kueri rentang siklus, hapus, `amount` tersimpan sebagai `int`.
- Cubit dan UI: validasi nominal dan kategori, tiga ketukan cukup, snackbar setelah simpan, daftar kosong, hapus dengan konfirmasi.
- Rules emulator: dokumen valid lolos; `amount` nol, tipe salah, kunci asing, dan pengguna lain ditolak.

## 7. Dokumen yang ikut berubah

- `DATABASE.md`: definisi minggu (Senin sampai Minggu), nama siklus menurut bulan awal, ID kategori default tetap, dan catatan bahwa jatah harian memakai sisa setelah pengeluaran hari ini.
- `DECISIONS.md`: ADR-016 (rumus jatah apa adanya dan definisi minggu dan siklus), ADR-017 (kategori default dengan ID tetap, seeding idempoten dan diserialkan).
- `ARCHITECTURE.md`: paket `domain/budget`, `CategoryRepository`, `ExpenseRepository`.
- `TESTING.md`: daftar uji manual 4a. `TODO.md`, `CHANGELOG.md`, `DIAGRAMS.md` (ERD bila field berubah; tidak ada field baru).

## 8. Di luar cakupan 4a

Budget bulanan dan batas per kategori (US-08), Beranda jatah dan peringatan (US-10, US-11), dampak ke pelunasan, edit pengeluaran, pengeluaran berulang, ekspor (Fase 6).

## 9. Risiko dan hal yang perlu diuji di perangkat

- Tulis kategori default saat offline pertama kali: batch masuk antrean lokal; pastikan layar tidak menunggu.
- Zona waktu: `spentAt` dan batas siklus memakai jam dinding perangkat, konsisten dengan ADR-015. Pengguna yang bepergian lintas zona bisa melihat pengeluaran pindah siklus pada tengah malam lokal.
- Siklus dengan `startDay` 29 sampai 31 tidak didukung (rules dan UI membatasi 1 sampai 28).
