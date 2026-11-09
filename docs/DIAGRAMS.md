# DIAGRAMS — GeuraLunas

Versi 0.1 · 2026-11-09

Diagram disimpan sebagai gambar PNG (`docs/diagrams/*.png`) supaya tampil di semua penampil Markdown: GitHub, VS Code, Antigravity, dan Android Studio, tanpa ekstensi. Sumbernya berupa file [Mermaid](https://mermaid.js.org/) (`docs/diagrams/*.mmd`) dan merupakan sumber kebenaran.

**Mengubah diagram:** edit file `.mmd`, lalu jalankan `bash docs/diagrams/render.sh` (butuh Node.js dan Chrome) untuk membuat ulang PNG. Commit `.mmd` dan `.png` bersama. Jika skema atau alur berubah, perbarui juga dokumen terkait (`DATABASE.md`, `ARCHITECTURE.md`, `PRD.md`).

Daftar: 1 Use case · 2 ERD · 3 Arsitektur · 4 Sitemap · 5 Alur tambah hutang · 6 Sequence catat pembayaran · 7 Sequence pengingat · 8 State hutang dan cicilan · 9 Alur hitung jatah aman · 10 Alur simulasi

---

## 1. Use case

Satu aktor: Pengguna. Kode `US-xx` merujuk ke [PRD.md](PRD.md).

![Use case](diagrams/01-use-case.png)

<sub>Sumber: [`01-use-case.mmd`](diagrams/01-use-case.mmd)</sub>

---

## 2. ERD (model data Firestore)

Firestore berbasis dokumen: relasi `USER → anak` berarti subkoleksi di bawah `users/{uid}`. Detail field di [DATABASE.md](DATABASE.md).

![ERD model data](diagrams/02-erd.png)

<sub>Sumber: [`02-erd.mmd`](diagrams/02-erd.mmd)</sub>

---

## 3. Arsitektur berlapis

Panah = "bergantung pada". Lapisan atas boleh memakai bawah, tidak sebaliknya. `domain` tidak bergantung pada apa pun. Detail di [ARCHITECTURE.md](ARCHITECTURE.md).

![Arsitektur berlapis](diagrams/03-arsitektur.png)

<sub>Sumber: [`03-arsitektur.mmd`](diagrams/03-arsitektur.mmd)</sub>

---

## 4. Sitemap navigasi

![Sitemap navigasi](diagrams/04-sitemap.png)

<sub>Sumber: [`04-sitemap.mmd`](diagrams/04-sitemap.mmd)</sub>

---

## 5. Alur tambah hutang (US-01)

![Alur tambah hutang](diagrams/05-alur-tambah-hutang.png)

<sub>Sumber: [`05-alur-tambah-hutang.mmd`](diagrams/05-alur-tambah-hutang.mmd)</sub>

---

## 6. Sequence — catat pembayaran (US-05)

![Sequence catat pembayaran](diagrams/06-seq-catat-pembayaran.png)

<sub>Sumber: [`06-seq-catat-pembayaran.mmd`](diagrams/06-seq-catat-pembayaran.mmd)</sub>

---

## 7. Sequence — pengingat jatuh tempo (US-06)

![Sequence pengingat jatuh tempo](diagrams/07-seq-pengingat.png)

<sub>Sumber: [`07-seq-pengingat.mmd`](diagrams/07-seq-pengingat.mmd)</sub>

---

## 8. State — hutang dan cicilan

![State hutang](diagrams/08a-state-hutang.png)

<sub>Sumber: [`08a-state-hutang.mmd`](diagrams/08a-state-hutang.mmd)</sub>

![State cicilan](diagrams/08b-state-cicilan.png)

<sub>Sumber: [`08b-state-cicilan.mmd`](diagrams/08b-state-cicilan.mmd)</sub>

"Terlambat" bukan state tersimpan: diturunkan dari `status = active` dan `nextDueDate` sebelum hari ini.

---

## 9. Alur hitung jatah aman (US-10, US-11)

Rumus lengkap di [DATABASE.md bagian 6](DATABASE.md).

![Alur hitung jatah aman](diagrams/09-alur-jatah-aman.png)

<sub>Sumber: [`09-alur-jatah-aman.mmd`](diagrams/09-alur-jatah-aman.mmd)</sub>

---

## 10. Alur simulasi pelunasan (US-12)

![Alur simulasi pelunasan](diagrams/10-alur-simulasi.png)

<sub>Sumber: [`10-alur-simulasi.mmd`](diagrams/10-alur-simulasi.mmd)</sub>
