# DIAGRAMS — GeuraLunas

Versi 0.1 · 2026-11-09

Semua diagram memakai [Mermaid](https://mermaid.js.org/) dan tampil otomatis di GitHub dan VS Code (ekstensi Mermaid). Jika skema atau alur berubah, perbarui diagram di sini bersama dokumen terkait (`DATABASE.md`, `ARCHITECTURE.md`, `PRD.md`).

Daftar: 1 Use case · 2 ERD · 3 Arsitektur · 4 Sitemap · 5 Alur tambah hutang · 6 Sequence catat pembayaran · 7 Sequence pengingat · 8 State hutang dan cicilan · 9 Alur hitung jatah aman · 10 Alur simulasi

---

## 1. Use case

Satu aktor: Pengguna. Kode `US-xx` merujuk ke [PRD.md](PRD.md).

```mermaid
flowchart LR
    U(["Pengguna"])

    subgraph Akun
        A1["Daftar / masuk (US-00)"]
        A2["Reset password (US-00)"]
    end
    subgraph Hutang
        H1["Tambah hutang (US-01)"]
        H2["Lihat daftar (US-02)"]
        H3["Lihat detail (US-03)"]
        H4["Ubah / arsip / hapus (US-04)"]
        H5["Catat pembayaran (US-05)"]
    end
    subgraph Pengingat
        R1["Terima pengingat bayar (US-06)"]
        R2["Kirim pengingat tagih (US-07)"]
    end
    subgraph Budget
        B1["Atur budget bulanan (US-08)"]
        B2["Catat pengeluaran (US-09)"]
        B3["Lihat jatah aman (US-10)"]
        B4["Terima peringatan jatah (US-11)"]
    end
    subgraph Analisis
        S1["Simulasi pelunasan (US-12)"]
        S2["Lihat grafik (US-13)"]
        S3["Ekspor CSV (US-14)"]
    end

    U --- A1 & A2
    U --- H1 & H2 & H3 & H4 & H5
    U --- R1 & R2
    U --- B1 & B2 & B3 & B4
    U --- S1 & S2 & S3
    H5 -. "memicu" .-> R1
    B2 -. "memengaruhi" .-> B3
    H1 -. "memengaruhi" .-> B3
```

---

## 2. ERD (model data Firestore)

Firestore berbasis dokumen: relasi `USER → anak` berarti subkoleksi di bawah `users/{uid}`. Detail field di [DATABASE.md](DATABASE.md).

```mermaid
erDiagram
    USER ||--o{ DEBT : "punya"
    USER ||--o{ CATEGORY : "punya"
    USER ||--o{ EXPENSE : "mencatat"
    USER ||--o{ BUDGET : "punya per bulan"
    DEBT ||--o{ INSTALLMENT : "dijadwalkan"
    DEBT ||--o{ PAYMENT : "dibayar lewat"
    INSTALLMENT |o--o{ PAYMENT : "dilunasi oleh"
    CATEGORY ||--o{ EXPENSE : "mengelompokkan"
    CATEGORY ||--o{ BUDGET : "dibatasi di categoryLimits"

    USER {
        string uid PK
        string displayName
        string email
        string reminderTime
        int budgetCycleStartDay
        string timezone
    }
    DEBT {
        string debtId PK
        string direction "owe | lent"
        string kind "pinjol | installment | personal"
        string counterpartyName
        int principal
        string interestType
        double interestRate
        int adminFee
        int tenorCount
        string frequency
        int totalPayable
        int paidTotal
        int remaining
        timestamp nextDueDate
        string status "active | settled | archived"
    }
    INSTALLMENT {
        string seq PK
        timestamp dueDate
        int amount
        int paidAmount
        string status "pending | partial | paid"
    }
    PAYMENT {
        string paymentId PK
        int amount
        timestamp paidAt
        int installmentSeq FK
        string note
    }
    CATEGORY {
        string categoryId PK
        string name
        string icon
        string colorHex
        bool archived
    }
    EXPENSE {
        string expenseId PK
        int amount
        string categoryId FK
        timestamp spentAt
        string note
    }
    BUDGET {
        string yyyyMM PK
        int incomeTotal
        int savingsTarget
        map categoryLimits
    }
```

---

## 3. Arsitektur berlapis

Panah = "bergantung pada". Lapisan atas boleh memakai bawah, tidak sebaliknya. `domain` tidak bergantung pada apa pun. Detail di [ARCHITECTURE.md](ARCHITECTURE.md).

```mermaid
flowchart TB
    subgraph PRES["Presentation"]
        V["Halaman dan widget"]
    end
    subgraph BLOC["Business Logic"]
        B["Bloc / Cubit per fitur"]
    end
    subgraph REPO["Repository"]
        R["Auth, Debt, Budget, Reminder repository"]
    end
    subgraph DATA["Data"]
        D1["Firebase Auth"]
        D2["Cloud Firestore"]
        D3["Notifikasi lokal"]
    end
    DOM["Domain - Dart murni: Money, bunga, jadwal, jatah aman, simulator"]

    V --> B --> R
    R --> D1 & D2 & D3
    B --> DOM
    R --> DOM
```

---

## 4. Sitemap navigasi

```mermaid
flowchart TD
    SP["Splash"] --> CK{"Sudah masuk?"}
    CK -- "belum" --> OB["Onboarding"] --> LG["Masuk / Daftar"]
    LG --> SH
    CK -- "sudah" --> SH["Shell navigasi bawah"]

    SH --> T1["Beranda"]
    SH --> T2["Hutang"]
    SH --> T3["Tombol +"]
    SH --> T4["Budget"]
    SH --> T5["Lainnya"]

    T1 --> T1a["Jatah hari ini"]
    T1 --> T1b["Cicilan terdekat"]
    T1 --> T1c["Piutang untuk ditagih"]

    T2 --> L1["Daftar: Aku berutang / Piutang"]
    L1 --> L2["Detail hutang"]
    L2 --> L3["Form pembayaran"]
    L1 --> L4["Form hutang"]

    T3 --> Q1["Catat pengeluaran"]
    T3 --> Q2["Catat pembayaran"]
    T3 --> Q3["Tambah hutang"]

    T4 --> B1["Ringkasan bulan"]
    B1 --> B2["Riwayat pengeluaran"]
    B1 --> B3["Atur budget dan kategori"]

    T5 --> M1["Simulasi pelunasan"]
    T5 --> M2["Pengaturan"]
    T5 --> M3["Ekspor CSV"]
    T5 --> M4["Akun"]
```

---

## 5. Alur tambah hutang (US-01)

```mermaid
flowchart TD
    S(["Mulai"]) --> A["Pilih arah: aku berutang / piutang"]
    A --> B["Pilih jenis: pinjol / cicilan / teman"]
    B --> C["Isi nama pihak, pokok, tanggal mulai"]
    C --> D{"Jenis teman tanpa bunga dan tenor?"}
    D -- "ya" --> E["Isi jatuh tempo opsional"]
    D -- "tidak" --> F["Isi bunga, biaya admin, tenor, frekuensi"]
    E --> G["Hitung total dan jadwal"]
    F --> G
    G --> H["Pratinjau jadwal dan total"]
    H --> I{"Sesuai?"}
    I -- "ubah" --> C
    I -- "simpan" --> J["Tulis atomik: debt + semua installment"]
    J --> K["Jadwalkan ulang pengingat"]
    K --> Z(["Selesai - tampil detail"])
```

---

## 6. Sequence — catat pembayaran (US-05)

```mermaid
sequenceDiagram
    actor U as Pengguna
    participant V as Form pembayaran
    participant B as DebtDetailBloc
    participant R as DebtRepository
    participant D as Domain
    participant F as Firestore
    participant N as ReminderRepository

    U->>V: isi nominal, tanggal, simpan
    V->>B: PaymentRecorded
    B->>R: recordPayment
    R->>D: validasi tidak melebihi sisa
    alt nominal melebihi sisa
        D-->>R: ValidationFailure
        R-->>B: error
        B-->>V: tampil pesan
    else valid
        R->>F: batch atomik: payment + installment + debt
        F-->>R: berhasil, atau antre bila offline
        R-->>B: debt terbaru
        B->>N: reschedule
        B-->>V: state baru (sisa, progres)
        opt sisa = 0
            B-->>V: tampil ucapan lunas
        end
    end
```

---

## 7. Sequence — pengingat jatuh tempo (US-06)

```mermaid
sequenceDiagram
    participant App as Aplikasi
    participant R as ReminderRepository
    participant F as Firestore
    participant OS as Android AlarmManager
    actor U as Pengguna

    App->>R: rescheduleAll (login, data berubah, app dibuka)
    R->>F: baca cicilan belum lunas ke depan
    F-->>R: daftar cicilan
    R->>OS: batalkan semua jadwal lama
    loop tiap cicilan x tiap offset H-3, H-1, H-0
        R->>OS: jadwalkan notifikasi (ID dari debtId, seq, offset)
    end
    OS-->>U: notifikasi pada jam yang diatur
    U->>App: ketuk notifikasi
    App->>App: buka detail hutang
    Note over OS,App: Setelah HP restart, plugin menjadwalkan ulang dari boot receiver
```

---

## 8. State — hutang dan cicilan

```mermaid
stateDiagram-v2
    direction LR
    state "Hutang" as Debt {
        [*] --> active
        active --> settled : remaining = 0
        settled --> active : pembayaran dihapus
        active --> archived : diarsipkan
        settled --> archived : diarsipkan
        archived --> active : dipulihkan
    }
```

```mermaid
stateDiagram-v2
    direction LR
    state "Cicilan" as Inst {
        [*] --> pending
        pending --> partial : bayar sebagian
        partial --> paid : bayar sisa
        pending --> paid : bayar penuh
        paid --> partial : pembayaran dihapus sebagian
        paid --> pending : pembayaran dihapus
    }
```

"Terlambat" bukan state tersimpan: diturunkan dari `status = active` dan `nextDueDate` sebelum hari ini.

---

## 9. Alur hitung jatah aman (US-10, US-11)

Rumus lengkap di [DATABASE.md bagian 6](DATABASE.md).

```mermaid
flowchart TD
    S(["Buka Beranda"]) --> A["Ambil budget bulan siklus ini"]
    A --> B{"Pemasukan sudah diisi?"}
    B -- "belum" --> B1["Ajak isi pemasukan"]
    B -- "sudah" --> C["Jumlahkan sisa cicilan hutang owe yang jatuh tempo di siklus ini"]
    C --> D["batas = pemasukan - cicilan - target tabung"]
    D --> E{"batas negatif?"}
    E -- "ya" --> E1["Status: cicilan melebihi pemasukan, arahkan ke simulasi"]
    E -- "tidak" --> F["sisa = batas - total pengeluaran siklus ini"]
    F --> G["jatah hari ini = floor sisa / sisa hari, minimal 0"]
    G --> H{"Pengeluaran hari ini melebihi jatah?"}
    H -- "ya" --> H1["Tampilkan dampak ke jatah hari berikutnya, nada suportif"]
    H -- "tidak" --> I["Tampilkan jatah hari, minggu, dan bulan"]
    H1 --> I
```

---

## 10. Alur simulasi pelunasan (US-12)

```mermaid
flowchart TD
    S(["Mulai simulasi"]) --> A["Pilih hutang owe yang disertakan"]
    A --> B["Isi dana ekstra per bulan"]
    B --> C["Jalankan snowball dan avalanche"]
    C --> D["Bulan berikutnya"]
    D --> E["Bayar cicilan minimum semua hutang"]
    E --> F["Dana ekstra ke hutang prioritas: snowball = sisa terkecil, avalanche = bunga tertinggi"]
    F --> G{"Ada hutang lunas bulan ini?"}
    G -- "ya" --> G1["Alihkan cicilannya ke prioritas berikutnya"]
    G -- "tidak" --> H
    G1 --> H{"Semua lunas?"}
    H -- "tidak" --> I{"Melebihi batas 600 bulan atau pembayaran tidak menutup bunga?"}
    I -- "tidak" --> D
    I -- "ya" --> J["Tandai: tidak pernah lunas"]
    H -- "ya" --> K["Catat bulan lunas dan total bunga"]
    J --> L["Tampilkan hasil dan selisih kedua metode"]
    K --> L
    L --> Z(["Grafik sisa hutang per bulan"])
```
