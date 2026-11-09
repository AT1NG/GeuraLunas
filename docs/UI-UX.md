# UI-UX — Lunasin

Versi 0.1 · 2026-11-09

## 1. Prinsip

1. **Tidak menghakimi.** Orang berhutang sering sudah merasa bersalah. Teks suportif, fokus ke langkah berikutnya.
2. **Cepat dicatat.** Tambah pengeluaran ≤ 3 ketukan; tambah pembayaran dari daftar tanpa membuka form panjang.
3. **Satu angka penting per layar.** Beranda: jatah hari ini. Daftar hutang: total sisa.
4. **Uang selalu jelas.** Format `Rp1.250.000`, warna + ikon + teks (jangan hanya warna) untuk status.
5. **Aman dari salah ketuk.** Aksi yang menghapus butuh konfirmasi dan opsi batal (snackbar undo bila memungkinkan).

## 2. Peta layar

```
Splash → (belum masuk) Onboarding → Masuk / Daftar
       → (sudah masuk) Shell dengan navigasi bawah:

 [Beranda]   [Hutang]   [ + ]   [Budget]   [Lainnya]
```

| Tab | Layar |
|---|---|
| Beranda | Jatah hari ini, sisa minggu/bulan, cicilan terdekat, pintasan "catat pengeluaran" |
| Hutang | Daftar (tab: Aku berutang / Piutang) → Detail hutang → Form hutang → Form pembayaran |
| + | Menu cepat: Catat pengeluaran, Catat pembayaran, Tambah hutang |
| Budget | Ringkasan bulan, kategori, riwayat pengeluaran, atur budget |
| Lainnya | Simulasi pelunasan, Pengaturan (pengingat, siklus budget, kategori), Akun, Tentang |

## 3. Alur utama

**Pertama kali:** Onboarding 3 slide → daftar/masuk → atur pemasukan bulan ini (boleh dilewati) → tambah hutang pertama (boleh dilewati) → Beranda.

**Tambah hutang:** pilih arah → pilih jenis → isi nama pihak, pokok → (pinjol/cicilan) bunga, tenor, tanggal mulai → pratinjau jadwal dan total → simpan.

**Catat pembayaran:** dari kartu hutang ketuk "Bayar" → nominal terisi cicilan terdekat (bisa diubah) → konfirmasi → tampil sisa baru; bila lunas tampil layar/animasi selamat.

**Catat pengeluaran:** tombol + → nominal (keypad angka) → kategori (chip) → simpan; tanggal default hari ini.

**Simulasi:** pilih hutang yang disertakan → isi dana ekstra per bulan → bandingkan snowball vs avalanche → grafik.

## 4. Wireframe teks

**Beranda**
```
Halo, Rani
┌───────────────────────────────┐
│ Jatah aman hari ini           │
│ Rp 45.000                     │
│ Sisa minggu ini  Rp 210.000   │
│ Sisa bulan ini   Rp 880.000   │
└───────────────────────────────┘
Cicilan terdekat
 • Paylater A   3 hari lagi   Rp350.000   [Bayar]
 • Pinjol B     9 hari lagi   Rp500.000
Piutang untuk ditagih
 • Budi          telat 5 hari  Rp100.000  [Tagih]
[ Catat pengeluaran ]
```

**Daftar hutang**
```
[ Aku berutang ] [ Piutang ]      Total sisa: Rp2.400.000
┌ Pinjol B ───────── Rp1.500.000 ┐
│ ███████░░░░ 40% · jatuh tempo 18 Nov │
└─────────────────────────────────┘
```

## 5. Status dan warna

| Status | Tampilan |
|---|---|
| Aktif | netral |
| Jatuh tempo ≤ 3 hari | kuning + ikon jam + teks "3 hari lagi" |
| Terlambat | merah + ikon peringatan + teks "telat N hari" |
| Lunas | hijau + ikon centang |

## 6. Nada teks (contoh)

| Situasi | Teks |
|---|---|
| Jatah habis | "Jatah hari ini sudah terpakai. Besok mulai lagi dengan Rp38.000." |
| Cicilan > pemasukan | "Cicilan bulan ini lebih besar dari pemasukan. Yuk lihat simulasi untuk cari jalan keluar." |
| Lunas | "Lunas! Satu beban berkurang." |
| Pengingat bayar | "Cicilan Paylater A Rp350.000 jatuh tempo besok." |
| Pengingat tagih | "Sudah lewat jatuh tempo: Budi, Rp100.000. Mau kirim pengingat sopan?" |
| Template tagih | "Halo Budi, mau mengingatkan pinjaman Rp100.000 yang jatuh tempo tanggal 12 Nov. Kapan kira-kira bisa dibayar? Terima kasih ya." |

## 7. Komponen dan tema

- Material 3, `ColorScheme.fromSeed`, tema light dan dark, semua nilai dari `ThemeData` (tanpa warna/ukuran hardcoded di widget).
- Komponen bersama: `MoneyText`, `DebtCard`, `ProgressBar`, `StatusChip`, `AmountField` (keypad angka, pemisah ribuan otomatis), `EmptyState`, `ConfirmDialog`.
- Grafik: pustaka grafik ringan (dipilih di Fase 5).

## 8. Aksesibilitas

Label semantik di setiap kartu hutang ("Pinjol B, sisa satu juta lima ratus ribu rupiah, jatuh tempo 18 November"), target sentuh ≥ 48 dp, kontras AA, mendukung teks besar, status tidak hanya lewat warna.

## 9. State kosong, loading, error

- Kosong: ilustrasi sederhana + satu tombol aksi ("Tambah hutang pertamamu").
- Loading: skeleton, bukan spinner layar penuh.
- Error: pesan singkat + tombol "Coba lagi"; saat offline tampilkan penanda kecil "Offline — perubahan akan tersinkron".
