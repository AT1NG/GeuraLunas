# DATABASE — GeuraLunas

Versi 0.1 · 2026-11-09 · Basis data: Cloud Firestore (NoSQL, dokumen/koleksi)

## 1. Prinsip

- Semua data pengguna berada di bawah `users/{uid}`.
- **Uang = `int` rupiah utuh.** Tidak ada `double` untuk nominal. Suku bunga (persen) disimpan sebagai `double`, hasil hitungan dibulatkan ke rupiah terdekat (`round half up`) di domain.
- Tanggal jatuh tempo disimpan sebagai `Timestamp` pada pukul 00:00 zona waktu pengguna (`Asia/Jakarta` default). Tanggal "hari" dibandingkan sebagai tanggal kalender.
- Field turunan yang sering dibaca (`remaining`, `nextDueDate`) disimpan terdenormalisasi dan diperbarui atomik bersama penulisan sumbernya.
- ID dokumen dibuat klien (auto-id) agar penulisan offline tidak menunggu server.

## 2. Peta koleksi

```
users/{uid}
  ├─ debts/{debtId}
  │    ├─ installments/{seq}
  │    └─ payments/{paymentId}
  ├─ categories/{categoryId}
  ├─ expenses/{expenseId}
  └─ budgets/{yyyy-MM}
```

## 3. Skema

### 3.1 `users/{uid}`

| Field | Tipe | Keterangan |
|---|---|---|
| displayName | string | |
| email | string | |
| createdAt | timestamp | |
| settings.reminderTime | string `HH:mm` | default `09:00` |
| settings.reminderDaysBefore | array<int> | default `[3,1,0]` |
| settings.budgetCycleStartDay | int 1–28 | default `1` |
| settings.timezone | string | default `Asia/Jakarta` |

### 3.2 `users/{uid}/debts/{debtId}`

| Field | Tipe | Keterangan |
|---|---|---|
| direction | string | `owe` (aku berutang) / `lent` (dia berutang ke aku) |
| kind | string | `pinjol` / `installment` / `personal` |
| counterpartyName | string | nama platform atau orang |
| note | string? | |
| principal | int | pokok pinjaman |
| interestType | string | `none` / `flat_monthly` / `flat_daily` / `reducing_monthly` |
| interestRate | double | persen per periode (0 jika `none`) |
| adminFee | int | biaya admin sekali bayar, default 0 |
| tenorCount | int? | jumlah cicilan; null untuk bayar sekali/tanpa jadwal |
| frequency | string | `monthly` / `weekly` / `once` |
| startDate | timestamp | |
| totalPayable | int | total yang harus dibayar (pokok + bunga + biaya), dihitung saat dibuat |
| paidTotal | int | akumulasi pembayaran |
| remaining | int | `totalPayable - paidTotal`, tidak pernah negatif |
| nextDueDate | timestamp? | jatuh tempo cicilan belum lunas terdekat; null jika lunas/tanpa jatuh tempo |
| status | string | `active` / `settled` / `archived` |
| createdAt, updatedAt | timestamp | |
| settledAt | timestamp? | |

"Terlambat" tidak disimpan; diturunkan: `status == active && nextDueDate < hari ini`.

### 3.3 `debts/{debtId}/installments/{seq}`

`seq` = nomor urut 1..n sebagai ID dokumen (string `"1"`, `"2"`, …; gunakan zero-pad `"001"` agar urut leksikografis).

| Field | Tipe | Keterangan |
|---|---|---|
| seq | int | |
| dueDate | timestamp | |
| amount | int | nominal cicilan |
| paidAmount | int | default 0 |
| status | string | `pending` / `partial` / `paid` |
| paidAt | timestamp? | |

Hutang tanpa tenor (mis. pinjam ke teman, bayar kapan saja) memiliki 0 atau 1 installment; jika tanpa jatuh tempo, tidak ada installment dan pengingat tidak dibuat.

### 3.4 `debts/{debtId}/payments/{paymentId}`

| Field | Tipe | Keterangan |
|---|---|---|
| amount | int > 0 | |
| paidAt | timestamp | tanggal bayar |
| installmentSeq | int? | cicilan yang dilunasi (opsional) |
| note | string? | |
| createdAt | timestamp | |

Untuk `direction = lent`, payment berarti "diterima dari peminjam".

### 3.5 `users/{uid}/categories/{categoryId}`

| Field | Tipe | Keterangan |
|---|---|---|
| name | string | |
| icon | string | nama ikon |
| colorHex | string | |
| sortOrder | int | |
| isDefault | bool | |
| archived | bool | kategori terpakai tidak dihapus, hanya diarsipkan |

Default awal: Makan, Transport, Belanja, Tagihan, Hiburan, Kesehatan, Lainnya.

### 3.6 `users/{uid}/expenses/{expenseId}`

| Field | Tipe | Keterangan |
|---|---|---|
| amount | int > 0 | |
| categoryId | string | |
| spentAt | timestamp | |
| note | string? | |
| createdAt | timestamp | |

Pembayaran hutang **bukan** expense; pembayaran cicilan sudah dikurangkan lewat rumus jatah aman.

### 3.7 `users/{uid}/budgets/{yyyy-MM}`

ID = bulan siklus (`2026-11`), mengikuti `budgetCycleStartDay`.

| Field | Tipe | Keterangan |
|---|---|---|
| incomeTotal | int | pemasukan bulan ini |
| savingsTarget | int | target sisihkan, default 0 |
| categoryLimits | map<string,int> | batas opsional per `categoryId` |
| updatedAt | timestamp | |

## 4. Index

`firestore.indexes.json` (komposit):

| Koleksi | Field | Untuk |
|---|---|---|
| debts | `status` ASC, `nextDueDate` ASC | daftar aktif urut jatuh tempo |
| debts | `direction` ASC, `status` ASC | filter dua kelompok |
| expenses | `spentAt` DESC | riwayat |
| expenses | `categoryId` ASC, `spentAt` DESC | per kategori |
| collectionGroup installments | `status` ASC, `dueDate` ASC | cicilan bulan ini |

## 5. Security rules (draf)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

Penguatan di Fase 1 (diuji dengan emulator): validasi tipe field, `amount > 0`, `direction`/`kind`/`status` hanya nilai yang diizinkan, `remaining >= 0`, batas panjang string.

## 6. Rumus turunan

Semua rumus berada di `lib/domain` dan wajib punya unit test (TESTING.md).

**Total hutang**
- `none`: `principal + adminFee`
- `flat_monthly`: `principal + round(principal × rate% × tenorBulan) + adminFee`
- `flat_daily`: `principal + round(principal × rate% × hariTenor) + adminFee`
- `reducing_monthly` (anuitas): cicilan `A = P·r / (1 − (1+r)^−n)`, `totalPayable = A × n + adminFee`; selisih pembulatan masuk cicilan terakhir.

**Jadwal cicilan:** `totalPayable` dibagi rata ke `tenorCount`; sisa pembulatan ditambahkan ke cicilan terakhir. Jatuh tempo mengikuti `frequency` dari `startDate` (akhir bulan dipangkas ke hari terakhir bulan itu).

**Sisa:** `remaining = max(0, totalPayable − paidTotal)`.

**Jatah aman** (hanya hutang `owe` aktif; `lent` tidak dihitung sebagai pemasukan):

```
cicilanBulanIni  = Σ (installment.amount − installment.paidAmount)
                   untuk hutang owe dengan dueDate dalam siklus bulan ini
batasBulanan     = incomeTotal − cicilanBulanIni − savingsTarget
sisaBulanan      = batasBulanan − Σ expenses bulan ini
jatahHariIni     = floor(sisaBulanan / sisaHariTermasukHariIni)   (min 0)
jatahMingguIni   = jatahHariIni × sisaHariDalamMinggu (dibatasi sisaBulanan)
```

Jika `batasBulanan < 0`, tampilkan status "cicilan melebihi pemasukan" alih-alih angka negatif.

**Simulasi:** setiap bulan, bayar minimum (cicilan terjadwal) ke semua hutang, dana ekstra ke hutang prioritas (snowball: sisa terkecil; avalanche: bunga efektif tertinggi), hutang lunas membebaskan cicilannya ke prioritas berikutnya. Output: bulan lunas, total bunga, serial sisa per bulan.

## 7. Operasi atomik

| Operasi | Dokumen yang ditulis dalam satu batch |
|---|---|
| Tambah hutang | debts + semua installments |
| Catat pembayaran | payments + installments/{seq} + debts |
| Hapus pembayaran | hapus payments + kembalikan installments + debts |
| Ubah hutang yang sudah ada pembayaran | hitung ulang jadwal; cicilan yang sudah dibayar tidak berubah |
| Hapus hutang | hapus debts + semua subkoleksi (batch bertahap) |
