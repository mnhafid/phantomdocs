# Tickets: Contract Depletion Warning — Trigger Threshold & Reminder Frequency

Source: [FSD-contract-depletion-warning-triggers](2026-08-15-contract-depletion-warning-triggers-FSD.md) (v0.2) · Coverage: 16 FR / 5 NFR → 9 tiket, semua tercakup

## Summary

| ID | Title | Epic | Size | Blocked by | Covers |
|---|---|---|---|---|---|
| T-01 | Seed tiga baris custom configuration warning `[infra]` | E1 | S | — | FR-001 |
| T-02 | Baca config warning + resolusi frekuensi efektif | E1 | S | T-01 | FR-005, NFR-001 |
| T-03 | Endpoint GET/POST `/contracts/warning-config` dengan validasi | E1 | M | T-02 | FR-002, FR-003, FR-004, NFR-004, NFR-005 |
| T-04 | Alihkan Contract Critical ke baris config baru | E1 | S | T-02 | FR-016 |
| T-05 | Evaluasi trigger sisa waktu & sisa nilai | E2 | M | T-02 | FR-006, FR-007, FR-008, NFR-002, NFR-003 |
| T-06 | Dua template email ambang + notifikasi in-app | E2 | M | — | FR-009, FR-010, FR-011, FR-012 |
| T-07 | Kirim email ambang per kontrak ke seluruh PIC | E2 | M | T-05, T-06 | FR-012, FR-015 |
| T-08 | Frekuensi `one_time`: unschedule, kirim sekali, reconciler | E3 | M | T-02 | FR-013, FR-014 |
| T-09 | Test suite + Bruno collection | E4 | M | T-03, T-05, T-07, T-08 | verifikasi FR-004..FR-016 |

**Urutan build:** T-01 → T-02 → {T-03, T-04, T-05, T-08 paralel}; T-06 bisa jalan sejak awal (tidak bergantung apa pun); T-07 setelah T-05 + T-06; T-09 terakhir.

**Catatan rilis:**
1. T-01 harus dijalankan di tiap environment **sebelum** T-04 dan T-05 aktif. Kalau tidak: trigger baru diam (aman, A11) dan Contract Critical jatuh ke default kode — yang bisa berbeda dari nilai lama.
2. Sebelum seed, catat nilai `contracts.time_threshold` dan `contracts.budget_threshold` di tiap environment. Kalau berbeda dari default seed (30 / 20.00), salin nilai lamanya supaya klasifikasi Contract Critical tidak berubah pada hari rilis (PRD R5).
3. T-06 memerlukan dua baris `notification_templates` baru di tiap environment — masukkan ke skrip seed yang sama dengan T-01.

## Epics

- **E1 — Konfigurasi:** tiga baris config, pembacaannya, endpoint pengaturannya, dan pengalihan Contract Critical.
- **E2 — Trigger & pesan:** dua kondisi jatuh tempo baru, dua template email, dan pengirimannya.
- **E3 — Penjadwalan:** semantik `one_time` saat penyimpanan dan saat startup.
- **E4 — Verifikasi:** test dan koleksi API.

---

## T-01: Seed tiga baris custom configuration warning `[infra]`

- **Epic:** E1 · **Size:** S · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-001

**Context**

Ambang dibaca lewat `CustomConfigurationDetailExtensions.DetailValue`, yang menerima bentuk array maupun objek. Seed memakai **bentuk array** (`[{"key":"value","value":…}]`) — bentuk yang ditulis admin UI — supaya nilai tetap terbaca setelah admin menyunting baris itu. Lihat [FSD §4.1](2026-08-15-contract-depletion-warning-triggers-FSD.md).

**Scope of work**
- Skrip SQL seed untuk `contracts.warning_time_remaining` (30), `contracts.warning_remaining_available_value` (20.00), `contracts.warning_reminder_frequency` (`one_time`).
- Dua baris `notification_templates` untuk email ambang (dipakai T-06).
- Idempoten: `IF NOT EXISTS (SELECT 1 FROM custom_configurations WHERE name = … AND deleted_at IS NULL)`.
- GUID literal di dalam skrip, tanpa `DECLARE`/`GO` — klien JDBC yang dipakai tim memecah skrip pada `;`.
- Sertakan query pembanding nilai lama (`contracts.time_threshold`, `contracts.budget_threshold`) sebagai langkah pra-rilis, sesuai Catatan rilis 2.

**Acceptance criteria**
- **Given** database tanpa baris-baris tersebut, **when** skrip dijalankan, **then** tiga baris config + dua baris template tercipta sesuai FSD §4.1.
- **Given** skrip sudah pernah dijalankan, **when** dijalankan lagi, **then** tidak ada baris duplikat dan nilai yang sudah diubah admin tidak tertimpa.

---

## T-02: Baca config warning + resolusi frekuensi efektif

- **Epic:** E1 · **Size:** S · **Priority:** Must · **Blocked by:** T-01
- **Covers:** FR-005, NFR-001

**Context**

Satu tempat pembacaan yang dipakai bersama endpoint (T-03), Contract Critical (T-04), evaluasi trigger (T-05), dan penjadwalan (T-08). Pakai `PhantomDbContext.CustomConfigsByNamesAsync` yang sudah ada — satu query untuk ketiga nama.

**Scope of work**
- Helper baca: `int?` hari, `double?` persen, `string` frekuensi.
- Nilai tidak ada / tidak bisa di-parse → `null` untuk dua yang pertama, `one_time` untuk frekuensi.
- Resolusi frekuensi efektif: kolom `frequency` → config → `one_time`; frekuensi tak dikenal diperlakukan sebagai belum di-set.
- Tanpa cache: dibaca ulang tiap panggilan (NFR-001).

**Acceptance criteria**
- **Given** detail berbentuk objek `{"value":30}`, **when** helper dipanggil, **then** mengembalikan 30.
- **Given** detail berbentuk array `[{"key":"value","value":"30"}]`, **when** helper dipanggil, **then** mengembalikan 30.
- **Given** baris hilang atau detail rusak, **when** helper dipanggil, **then** mengembalikan null tanpa exception.
- **Given** kolom `frequency` berisi `monthly`, **when** frekuensi efektif dihitung, **then** hasilnya diambil dari config.

---

## T-03: Endpoint GET/POST `/contracts/warning-config` dengan validasi

- **Epic:** E1 · **Size:** M · **Priority:** Must · **Blocked by:** T-02
- **Covers:** FR-002, FR-003, FR-004, NFR-004, NFR-005

**Context**

Ikuti pola `Set/GetContractValueDepletionWarningNotificationAsync` di `ContractsEndpoint.cs` + `ContractsService.cs`: handler statis, `Stopwatch`, amplop `ApiResponseHelper`, `InvalidOperationException` → 400.

**Scope of work**
- DTO request/response dengan `JsonPropertyName` snake_case.
- Validasi lengkap sesuai tabel FR-004, dijalankan sebelum penulisan apa pun.
- Tulis/perbarui ketiga baris dalam satu `SaveChangesAsync`; isi `updated_at` / `updated_by` dari `GetCurrentUserIdAsync`.
- Persen dibulatkan 2 desimal sebelum disimpan; frekuensi disimpan lowercase.

**Acceptance criteria**
- **Given** ketiga baris ada, **when** `GET /contracts/warning-config`, **then** 200 dengan ketiga nilainya.
- **Given** baris ambang belum ada, **when** GET, **then** kedua ambang bernilai null dan `reminder_frequency` bernilai `one_time`.
- **Given** `time_remaining_days = 0`, **when** POST, **then** 400 dengan pesan FR-004 dan **tidak ada** baris yang berubah.
- **Given** `remaining_available_value_percent = 12.256`, **when** POST valid, **then** tersimpan sebagai 12.26.
- **Given** `reminder_frequency = "every_minute"`, **when** POST, **then** 400.
- **Given** permintaan tanpa bearer token, **when** POST, **then** 401.

---

## T-04: Alihkan Contract Critical ke baris config baru

- **Epic:** E1 · **Size:** S · **Priority:** Must · **Blocked by:** T-02
- **Covers:** FR-016

**Context**

`ContractsService.ApplyCriticalThresholdsAsync` sekarang membaca `contracts.budget_threshold` dan `contracts.time_threshold`. Kedua parameter itu bermakna sama dengan ambang warning yang baru, dan AC meminta satu pasang angka dipakai bersama.

**Scope of work**
- Ganti kedua nama konstanta ke `contracts.warning_remaining_available_value` dan `contracts.warning_time_remaining`, membaca lewat helper T-02.
- `ContractCriticalRule` dan pembulatan persentase tidak disentuh.
- Baris config lama tidak dihapus; buka tiket bersih-bersih terpisah.

**Acceptance criteria**
- **Given** `contracts.warning_time_remaining` = 45 dan `contracts.warning_remaining_available_value` = 15, **when** Contract Critical dihitung, **then** `TimeThreshold` = 45 dan `BudgetThreshold` = 15.
- **Given** kedua baris baru tidak ada, **when** Contract Critical dihitung, **then** dipakai default kode yang berlaku sekarang, tanpa exception.
- **Given** baris lama masih ada dengan nilai berbeda, **when** Contract Critical dihitung, **then** nilai baris lama diabaikan.

---

## T-05: Evaluasi trigger sisa waktu & sisa nilai

- **Epic:** E2 · **Size:** M · **Priority:** Must · **Blocked by:** T-02
- **Covers:** FR-006, FR-007, FR-008, NFR-002, NFR-003

**Context**

Titik ubah: `DataScienceService.TriggerDepletionNotificationsAsync`, yang hari ini hanya membaca `ds_contract_warning_dates`. Tambahkan satu query `contracts` dan jalankan jalur ambang berdampingan dengan jalur forecast. Rumus sisa nilai identik dengan Contract Critical — samakan persis, jangan bikin varian.

**Scope of work**
- Helper terpisah untuk seleksi kontrak berbasis ambang (CC ≤ 15, NFR-003): filter `approved_active` di memori seperti `RecalculateDepletionAsync` (kolom `status` di dev bertipe legacy `text`).
- Trigger waktu: `0 ≤ sisa hari ≤ X`. Trigger nilai: sisa % ≤ Y, lewati `contract_value ≤ 0`.
- Hasilnya dua daftar terpisah (per jenis trigger), masing-masing unik per `contract_id`.
- Jalur forecast tidak disentuh.

**Acceptance criteria**
- **Given** kontrak approved_active berakhir 10 hari lagi dan ambang waktu 30, **when** job berjalan, **then** kontrak masuk daftar trigger waktu.
- **Given** kontrak berakhir 40 hari lagi dan ambang waktu 30, **when** job berjalan, **then** kontrak tidak masuk daftar mana pun.
- **Given** kontrak berakhir hari ini, **when** job berjalan, **then** kontrak masuk daftar trigger waktu.
- **Given** kontrak `contract_value` 100 dan `spk_value` 88 serta ambang nilai 12.25, **when** job berjalan, **then** kontrak masuk daftar trigger nilai.
- **Given** kontrak berstatus `draft` yang melewati kedua ambang, **when** job berjalan, **then** kontrak tidak masuk daftar mana pun.
- **Given** kontrak `contract_value = 0`, **when** job berjalan, **then** kontrak dilewati tanpa exception.
- **Given** kedua baris ambang tidak ada, **when** job berjalan, **then** perilaku identik dengan sebelum perubahan (hanya forecast).

---

## T-06: Dua template email ambang + notifikasi in-app

- **Epic:** E2 · **Size:** M · **Priority:** Must · **Blocked by:** —
- **Covers:** FR-009, FR-010, FR-011, FR-012

**Context**

`PhantomEmailTemplates` sudah memuat pola subject + `Load(<nama>)` + `Render(html, values)`. Email ambang tidak memakai lampiran dan punya tombol CTA menuju detail kontrak.

**Scope of work**
- Dua berkas HTML template + konstanta subject/nama:
  - `Contract Remaining Time Below Threshold`
  - `Contract Remaining Value Below Threshold`
- Placeholder sesuai FR-011; tombol CTA menuju `{web_base_url}/contracts/{contract_id}/detail`.
- Footer keamanan (kalimat "do not reply … with your password") persis seperti FSD §6 FR-009.
- Dua nama template notifikasi in-app, sejalan dengan baris `notification_templates` dari T-01.

**Acceptance criteria**
- **Given** nilai placeholder lengkap, **when** template waktu dirender, **then** tidak ada `{…}` tersisa dan tombol menunjuk URL detail kontrak yang benar.
- **Given** kontrak tanpa `contract_title`, **when** template dirender, **then** `{contract_name}` terisi `contract_no`.
- **Given** ambang nilai 12.25, **when** template nilai dirender, **then** kalimatnya berbunyi `has 12.25% or less remaining value.`

---

## T-07: Kirim email ambang per kontrak ke seluruh PIC

- **Epic:** E2 · **Size:** M · **Priority:** Must · **Blocked by:** T-05, T-06
- **Covers:** FR-012, FR-015

**Context**

Jalur pengiriman yang ada mengelompokkan per PIC dan melampirkan `.xlsx`. Jalur ambang kebalikannya: satu email per kontrak per jenis trigger, semua PIC kontrak itu di kolom To, tanpa lampiran. Tulis sebagai jalur baru; jangan tekuk `SendContractValueDepletionWarningNotificationAsync` yang lama supaya jalur forecast tidak ikut berubah.

**Scope of work**
- Query PIC untuk semua kontrak jatuh tempo sekali saja (NFR-002), aturan seleksi PIC sama dengan yang lama.
- Satu `MailerMessage` per (kontrak, jenis trigger), `To` berisi seluruh email PIC.
- Notifikasi in-app di-stage untuk tiap PIC penerima.
- Kontrak tanpa PIC memenuhi syarat: tidak dikirim, dicatat di log warning dengan jumlah + daftar id.

**Acceptance criteria**
- **Given** kontrak dengan 3 PIC melewati ambang waktu, **when** notifikasi dikirim, **then** terkirim 1 email dengan 3 alamat di To dan 3 notifikasi in-app.
- **Given** kontrak melewati kedua ambang, **when** notifikasi dikirim, **then** terkirim 2 email dengan subject berbeda.
- **Given** 3 kontrak jatuh tempo dan 1 tanpa PIC aktif, **when** notifikasi dikirim, **then** 2 email terkirim dan log warning menyebut 1 kontrak beserta id-nya.
- **Given** kontrak jatuh tempo lewat forecast, **when** notifikasi dikirim, **then** email forecast beserta lampirannya tetap seperti sebelum perubahan.

---

## T-08: Frekuensi `one_time` — unschedule, kirim sekali, reconciler

- **Epic:** E3 · **Size:** M · **Priority:** Must · **Blocked by:** T-02
- **Covers:** FR-013, FR-014

**Context**

`ContractDepletionNotifySchedule` memetakan frekuensi → cron Quartz. `one_time` tidak bisa dinyatakan sebagai cron; perlakukan sebagai "tidak ada trigger" plus satu eksekusi langsung. Reconciler startup harus tahu bedanya, kalau tidak tiap restart bisa mengirim ulang.

**Scope of work**
- `IsKnownFrequency` menerima `one_time`; `ApplyAsync` menghapus trigger yang ada dan tidak memasang yang baru.
- `SetContractValueDepletionWarningNotificationAsync`: setelah setting tersimpan dengan `one_time`, jalankan pengiriman satu kali lewat `IBackgroundTaskQueue` yang sudah di-inject.
- Kegagalan pengiriman dicatat di log, tidak dilempar ke pemanggil.
- Reconciler: `one_time` → pastikan tidak ada trigger, jangan kirim apa pun, catat di log.

**Acceptance criteria**
- **Given** trigger `weekly` sedang aktif, **when** setting disimpan dengan `one_time`, **then** trigger terhapus dari scheduler.
- **Given** setting disimpan dengan `one_time`, **when** penyimpanan selesai, **then** pengiriman berjalan tepat satu kali.
- **Given** pengiriman melempar exception, **when** setting disimpan dengan `one_time`, **then** endpoint tetap 200 dan galat tercatat di log.
- **Given** `frequency = one_time` tersimpan, **when** aplikasi start, **then** tidak ada trigger terpasang dan tidak ada email terkirim.
- **Given** `frequency = weekly` dan trigger sudah pada cron yang benar, **when** aplikasi start, **then** trigger dibiarkan apa adanya.

---

## T-09: Test suite + Bruno collection

- **Epic:** E4 · **Size:** M · **Priority:** Must · **Blocked by:** T-03, T-05, T-07, T-08
- **Covers:** verifikasi FR-004..FR-016

**Context**

Pola yang sudah ada: `DataScienceScenarioTests` (in-memory DB + seed kontrak) dan `ContractDepletionSchedulerTests` (scheduler). Ingat catatan yang sudah diketahui: seed baris `Contract` di test in-memory, kalau tidak barisnya hilang.

**Scope of work**
- Test evaluasi trigger: batas ambang waktu (X, X+1, 0 hari), ambang nilai, `contract_value = 0`, kontrak non-approved, kedua config kosong (regresi "perilaku lama").
- Test parsing config: bentuk array vs objek, detail rusak, frekuensi tak dikenal.
- Test validasi endpoint: batas 0/366, persen 100.01, pembulatan 12.256, frekuensi `every_minute`.
- Test Contract Critical membaca baris baru dan mengabaikan baris lama.
- Test komposisi email: 1 email 3 penerima, dua email untuk dua trigger, fallback `contract_no`.
- Test scheduler: `one_time` menghapus trigger; `daily`/`weekly` tidak berubah.
- Bruno: dua berkas `.yml` di `phi/bruno/collections/phi-phantom/Contract/` untuk endpoint baru; perbarui contoh pada `Set Contract Value Depletion Warning Notification.yml` menjadi `"frequency": "one_time"`.

**Acceptance criteria**
- **Given** suite dijalankan, **when** `dotnet test`, **then** semua test baru lulus dan tidak ada test lama yang gagal.
- **Given** koleksi Bruno dibuka, **when** request `Get Contract Warning Config` dijalankan terhadap dev, **then** menghasilkan 200 dengan bentuk respons FSD §9.1.
