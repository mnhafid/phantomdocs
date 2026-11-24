# FSD: Contract Depletion Warning — Trigger Threshold & Reminder Frequency

| | |
|---|---|
| **Status** | Draft |
| **Related PRD** | [2026-08-15-contract-depletion-warning-triggers-PRD.md](2026-08-15-contract-depletion-warning-triggers-PRD.md) |
| **Date** | 2026-08-15 |
| **Version** | 0.2 |

## 1. System Overview

```
POST /contracts/warning-config  ──▶  custom_configurations                      ◀── FR-002..FR-005
   (time_remaining_days, remaining_available_value_percent, reminder_frequency)
        │                             contracts.warning_time_remaining
        │                             contracts.warning_remaining_available_value
        │                             contracts.warning_reminder_frequency
        │                                    │
        │                                    └──▶ Contract Critical / Monitoring  ◀── FR-016
        │                                         (menggantikan contracts.time_threshold
        │                                          dan contracts.budget_threshold)
        │
POST /contracts/contract-value-depletion-warning-notif   (SUDAH ADA)
        │  frequency + recipients ──▶ contract_value_depletion_warning_notifications
        └──▶ ContractDepletionNotifySchedule.ApplyAsync                          ◀── FR-013, FR-014
                 daily   → cron 0 0 8 * * ?
                 weekly  → cron 0 0 8 ? * MON
                 one_time→ unschedule + kirim sekali sekarang        (BARU)

ContractDepletionNotifyJob  (Quartz, durable)
        └──▶ IDataScienceService.TriggerDepletionNotificationsAsync
                 │
                 ├─ A. forecast: ds_contract_warning_dates                        (TIDAK BERUBAH)
                 │       start_notif_date <= today < contract_end_date
                 │       └──▶ 1 email per PIC, banyak kontrak, lampiran .xlsx
                 │
                 ├─ B. sisa waktu : 0 <= (contract_end_date − today) <= X          ◀── FR-006
                 │       └──▶ 1 email per kontrak, subject "…Remaining Time…"      ◀── FR-009
                 │
                 └─ C. sisa nilai : sisa % <= Y                                    ◀── FR-007
                         └──▶ 1 email per kontrak, subject "…Remaining Value…"     ◀── FR-010
                              penerima B & C = semua PIC kontrak itu di To         ◀── FR-015
```

## 2. Scope

**In scope:** tiga baris custom configuration baru berikut seed-nya; endpoint baca/tulis config dengan validasi; dua kondisi trigger baru; dua template email + notifikasi in-app baru; pengalihan Contract Critical ke baris config baru; semantik frekuensi `one_time` termasuk perilaku saat startup; logging kontrak jatuh tempo tanpa penerima.

**Out of scope** (dicerminkan dari Non-Goals PRD): algoritma forecast dan tabel-tabelnya beserta email + lampirannya; grafik depletion; rumus & tampilan Contract Critical; mengganti penerima dari PIC ke `recipients`; konfigurasi per-kontrak/per-department; UI; penghapusan baris config lama; backfill riwayat.

## 3. Konsep & Rumus

| Istilah | Definisi | Sumber |
|---|---|---|
| **approved_active** | `status = 'approved'` (case-insensitive, trimmed) **dan** `start_date ≤ today ≤ contract_end_date` | `DataScienceService.IsApprovedActive` |
| **Sisa hari** | `contract_end_date − today` dalam hari kalender. 0 berarti kontrak berakhir hari ini. | baru |
| **Sisa nilai %** | `(contract_value − spk_value) / contract_value × 100`, dibulatkan 2 desimal | `ContractsService` baris ~3701 (Contract Critical) |
| **PIC** | baris `contract_pics` yang belum dihapus, user-nya belum dihapus, `status` null atau `active`, dan `email` tidak kosong | `SendContractValueDepletionWarningNotificationAsync` |

## 4. Data & Konfigurasi

### 4.1 Baris custom_configurations (baru)

Ketiganya memakai bentuk detail array — bentuk yang ditulis admin UI — supaya nilainya tetap terbaca setelah admin menyunting baris tersebut. Pembacaan lewat `CustomConfigurationDetailExtensions.DetailValue/DetailDouble`, yang menerima bentuk array maupun objek.

| Name | Detail (seed) | Tipe | Dipakai oleh |
|---|---|---|---|
| `contracts.warning_time_remaining` | `[{"key":"value","value":"90","note":"hari sisa durasi kontrak"}]` | integer, hari | Warning (FR-006) + Contract Critical (FR-016) |
| `contracts.warning_remaining_available_value` | `[{"key":"value","value":"20.00","note":"persen sisa nilai kontrak"}]` | float, 2 desimal, persen | Warning (FR-007) + Contract Critical (FR-016) |
| `contracts.warning_reminder_frequency` | `[{"key":"value","value":"one_time","note":"daily / weekly / one_time"}]` | enum string | Default frekuensi (FR-005) |

Nilai seed 90 hari dan 20.00% sengaja disamakan dengan seed `contracts.time_threshold` / `contracts.budget_threshold` yang lama, supaya pengalihan Contract Critical (FR-016) tidak menggeser klasifikasi di environment yang masih memakai nilai default. Environment yang nilainya sudah diubah admin tetap harus dicek sebelum rilis (PRD R5). Baris lama berhenti dibaca tetapi tidak dihapus.

### 4.2 Tabel yang tidak berubah

`contract_value_depletion_warning_notifications` tetap satu baris dan tetap menjadi sumber kebenaran frekuensi aktif (`frequency`) beserta `recipients`. Tidak ada kolom baru, tidak ada migrasi skema pada rilis ini.

## 5. User Flows

### 5.1 Admin menyetel ambang (US-04, US-05, US-08)
1. `GET /contracts/warning-config` — nilai saat ini, `null` untuk yang belum di-set.
2. `POST /contracts/warning-config` dengan tiga nilai.
3. Sistem memvalidasi, menulis ketiga baris, mengembalikan nilai tersimpan.
4. Job run berikutnya dan halaman Contract Critical berikutnya memakai nilai baru. Tanpa restart.

### 5.2 Admin menyetel frekuensi & penerima (US-06, US-07)
1. `POST /contracts/contract-value-depletion-warning-notif` (endpoint yang sudah ada) dengan `frequency`.
2. `daily` / `weekly` → cron di-apply seperti sekarang.
3. `one_time` → trigger berulang di-unschedule, lalu job dijalankan **satu kali saat itu juga**. Menyimpan ulang berarti mengirim ulang (PRD R4).
4. Saat startup, reconciler memulihkan jadwal dari kolom `frequency`; `one_time` berarti tidak ada trigger dan **tidak ada** pengiriman ulang.

### 5.3 Warning terkirim (US-01, US-02, US-03)
1. Job berjalan sesuai jadwal.
2. Jalur forecast berjalan seperti sekarang: satu email agregat per PIC dengan lampiran `.xlsx`.
3. Jalur ambang: tiap kontrak yang melewati ambang menghasilkan satu email per jenis trigger, dikirim ke semua PIC kontrak tersebut sekaligus, tanpa lampiran.
4. Tiap email ambang juga menghasilkan notifikasi in-app untuk tiap PIC penerima.

## 6. Functional Requirements

### Konfigurasi

**FR-001** *(G3, US-04, US-05, US-06)* — Sistem menyediakan tiga baris `custom_configurations` sesuai §4.1. Skrip seed harus idempoten: menjalankannya dua kali tidak boleh menghasilkan baris duplikat bernama sama.

**FR-002** *(G3)* — `GET /contracts/warning-config` mengembalikan ketiga nilai tersimpan. Nilai yang barisnya tidak ada atau tidak valid dikembalikan `null`, kecuali `reminder_frequency` yang dikembalikan `"one_time"` (FR-005).

**FR-003** *(G3)* — `POST /contracts/warning-config` menyimpan ketiga nilai dalam satu operasi. Baris yang belum ada dibuat; yang sudah ada diperbarui beserta `updated_at`/`updated_by`. Kolom `name` tidak pernah berubah.

**FR-004** *(G3, R3)* — Validasi permintaan, semuanya wajib ada:
| Field | Aturan | Pesan galat (400) |
|---|---|---|
| `time_remaining_days` | bilangan bulat, `1 ≤ n ≤ 365` | `time_remaining_days must be an integer between 1 and 365.` |
| `remaining_available_value_percent` | angka, `0 ≤ n ≤ 100`, dibulatkan 2 desimal sebelum disimpan | `remaining_available_value_percent must be between 0 and 100.` |
| `reminder_frequency` | salah satu dari `daily`, `weekly`, `one_time` (case-insensitive, disimpan lowercase) | `Invalid frequency '<x>'. Allowed: daily, weekly, one_time.` |

Permintaan yang gagal validasi tidak menulis satu baris pun (semua-atau-tidak sama sekali).

**FR-005** *(G4, US-07, A4)* — Frekuensi efektif ditentukan berurutan: `contract_value_depletion_warning_notifications.frequency` bila terisi dan dikenal → `contracts.warning_reminder_frequency` → `one_time`. `every_minute` tetap dikenali sebagai frekuensi khusus pengujian dan tidak boleh diterima endpoint config (FR-004).

### Evaluasi trigger

**FR-006** *(G1, US-01, A6)* — Sebuah kontrak jatuh tempo warning **sisa waktu** bila: kontrak `approved_active`, `contracts.warning_time_remaining` ter-set dan valid, dan `0 ≤ (contract_end_date − today) ≤ nilai config`.

**FR-007** *(G2, US-02)* — Sebuah kontrak jatuh tempo warning **sisa nilai** bila: kontrak `approved_active`, `contracts.warning_remaining_available_value` ter-set dan valid, `contract_value > 0`, dan `round((contract_value − spk_value) / contract_value × 100, 2) ≤ nilai config`. Kontrak dengan `contract_value ≤ 0` dilewati (pembagian nol) dan dicatat di log level debug.

**FR-008** *(A1)* — Jalur ambang dan jalur forecast berjalan berdampingan dalam satu job run dan tidak saling meniadakan. Satu kontrak menghasilkan paling banyak: 1 email jalur forecast (teragregasi per PIC), 1 email sisa waktu, dan 1 email sisa nilai. Dalam satu job run, satu kontrak tidak boleh menghasilkan lebih dari satu email untuk jenis trigger yang sama.

### Pesan

**FR-009** *(G5, US-01, US-03)* — Email trigger sisa waktu:

- **Subject:** `Contract Remaining Time Below Threshold`
- **Body:**
  ```
  Hello, [fullname]

  This Contract, [contract_name] is about to end at [contract_expired_date]

  [ View Contract Detail ]   ← tombol menuju [contract_url]

  Please do not reply to this email with your password.
  We will never ask for your password, and we strongly discourage you from sharing it to anyone.

  Thanks,
  The Phantom Team
  ```

**FR-010** *(G5, US-02, US-03)* — Email trigger sisa nilai:

- **Subject:** `Contract Remaining Value Below Threshold`
- **Body:** sama dengan FR-009 kecuali kalimat inti:
  ```
  This Contract, [contract_name] has [threshold_percent]% or less remaining value.
  ```
  `[threshold_percent]` adalah nilai `contracts.warning_remaining_available_value` yang berlaku, bukan sisa nilai aktual kontrak.

**FR-011** *(G5)* — Pemetaan placeholder:
Placeholder memakai sintaks `[key]` — konvensi `PhantomEmailTemplates.Render` dan `INotificationDispatcher`, bukan bentuk `{…}` yang dipakai untuk menulis spesifikasi ini.

| Placeholder | Sumber |
|---|---|
| `[fullname]` | nama seluruh PIC penerima, dipisah koma. Untuk notifikasi in-app, dispatcher menimpanya dengan nama tiap penerima. |
| `[contract_name]` | `contracts.contract_title`; bila kosong, `contracts.contract_no` |
| `[contract_expired_date]` | `contracts.contract_end_date`, format `dd/MM/yyyy` |
| `[contract_url]` | `{web_base_url}/contracts/{contract_id}/detail`, tujuan tombol CTA |
| `[threshold_percent]` | nilai config, 2 desimal |

**FR-012** *(G5, A7)* — Kedua email ambang dikirim tanpa lampiran, memakai template dan baris `notification_templates` sendiri, terpisah dari template warning forecast. Warning forecast tetap memakai template dan lampiran `.xlsx` yang lama, tanpa perubahan. Setiap email ambang juga menghasilkan notifikasi in-app untuk tiap PIC penerima, dengan tautan yang sama dengan tombol CTA.

### Penjadwalan

**FR-013** *(G4, A5)* — `ContractDepletionNotifySchedule` menerima frekuensi `one_time`. Meng-apply `one_time` berarti: hapus trigger berulang bila ada, dan jangan pasang trigger baru. Saat `SetContractValueDepletionWarningNotificationAsync` menyimpan `frequency = one_time`, job pengiriman dijalankan satu kali segera setelah setting tersimpan. Kegagalan pengiriman tidak menggagalkan penyimpanan setting; galat dicatat di log.

**FR-014** *(G4)* — `ContractDepletionNotifyReconciler` saat startup: untuk `daily`/`weekly` berperilaku seperti sekarang; untuk `one_time` memastikan tidak ada trigger terpasang dan **tidak** memicu pengiriman. Restart aplikasi tidak menghasilkan email tambahan.

### Pengiriman & Contract Critical

**FR-015** *(A3, A8, R2)* — Penerima email ambang adalah seluruh PIC kontrak tersebut yang memenuhi syarat, dalam satu email (semua alamat di kolom To). Kontrak jatuh tempo yang tidak punya PIC memenuhi syarat tidak dikirimi email dan dicatat di log level warning berisi jumlah serta daftar `contract_id`-nya. Aturan penerima jalur forecast tidak berubah.

**FR-016** *(G6, US-08)* — `ContractsService.ApplyCriticalThresholdsAsync` membaca `contracts.warning_time_remaining` dan `contracts.warning_remaining_available_value` menggantikan `contracts.time_threshold` dan `contracts.budget_threshold`. Bila baris baru tidak ada atau tidak valid, `ContractMonitoringSettings` memakai default kode yang berlaku sekarang — persis seperti perilaku hari ini saat baris lama tidak ada. Rumus `ContractCriticalRule.ResolveAction` dan pembulatan persentasenya tidak berubah.

## 7. Non-Functional Requirements

**NFR-001** — Ketiga config dibaca ulang pada tiap job run, tiap panggilan endpoint, dan tiap perhitungan Contract Critical; perubahan berlaku tanpa restart.

**NFR-002** — Evaluasi trigger baru menambahkan paling banyak satu query terhadap `contracts`, satu terhadap `contract_pics`+`users`, dan satu terhadap `custom_configurations` per job run. Tidak ada query per-kontrak di dalam loop.

**NFR-003** — Semua metode baru/berubah harus punya cognitive complexity ≤ 15 (CLAUDE.md). Evaluasi trigger dipisahkan dari komposisi email dan dari orkestrasi pengiriman.

**NFR-004** — Endpoint `/contracts/warning-config` mengikuti autentikasi grup `contracts` yang ada; tidak `AllowAnonymous`.

**NFR-005** — Endpoint mengembalikan amplop `ApiResponse` standar (`data`, `process_time`, `status`, `code`, `message`), 400 untuk galat validasi, 500 untuk galat tak terduga.

## 8. Error & Edge Cases

| Kondisi | Perilaku |
|---|---|
| Baris config tidak ada / detail bukan JSON / nilai bukan angka | Trigger terkait mati (A11); Contract Critical jatuh ke default kode. Job tetap jalan dengan trigger yang lain. Dicatat sekali per job run di log information. |
| `contracts.warning_time_remaining` = 0 lewat edit DB langsung | Diperlakukan valid: hanya kontrak yang berakhir hari ini yang kena. Endpoint menolaknya (FR-004). |
| `contract_value = 0` atau negatif | Trigger sisa nilai dilewati untuk kontrak itu (FR-007). Trigger sisa waktu tetap berlaku. |
| `spk_value > contract_value` (sisa nilai negatif) | Tetap ≤ ambang, kontrak dikirimi email. Subject & body tidak menampilkan angka aktual, jadi tidak ada persentase negatif yang bocor ke penerima. |
| Kontrak melewati kedua ambang sekaligus | Dua email dengan subject berbeda ke PIC yang sama. Disengaja: satu email menjawab satu pertanyaan. |
| Kontrak juga jatuh tempo lewat forecast | Menerima email jalur forecast juga (FR-008). Maksimum 3 email per kontrak per job run. |
| Kontrak jatuh tempo tanpa PIC aktif | Tidak ada email; dicatat di log warning (FR-015). |
| Kontrak punya beberapa PIC | Satu email, semua alamat di To, sapaan berisi seluruh nama dipisah koma (FR-011). |
| Ambang longgar + frekuensi `daily` | Volume email = jumlah kontrak yang melewati ambang, per hari. Dibatasi lewat validasi range dan default `one_time` (R3). |
| Frekuensi tersimpan tidak dikenal (mis. peninggalan `monthly`) | Diperlakukan sebagai belum di-set → default FR-005. Reconciler mencatatnya di log. |
| Menyimpan `one_time` berkali-kali | Mengirim berkali-kali. Perilaku yang diketahui (PRD R4). |
| Job berjalan saat job sebelumnya belum selesai | Dicegah `[DisallowConcurrentExecution]` yang sudah ada. |

## 9. Interfaces

Base group: `/api/v1`. Auth: bearer, seperti endpoint kontrak lain.

### 9.1 `GET /api/v1/contracts/warning-config`

Respons 200:
```json
{
  "data": {
    "time_remaining_days": 30,
    "remaining_available_value_percent": 20.00,
    "reminder_frequency": "one_time"
  },
  "process_time": "12.4021ms",
  "status": "success",
  "code": "00",
  "message": "Get contract warning config succeed"
}
```
Nilai yang belum di-set dikembalikan `null` (kecuali `reminder_frequency`, FR-002).

### 9.2 `POST /api/v1/contracts/warning-config`

Permintaan:
```json
{
  "time_remaining_days": 30,
  "remaining_available_value_percent": 20.00,
  "reminder_frequency": "one_time"
}
```

Respons 200: sama dengan §9.1 dengan `message` `Set contract warning config succeed`.

Respons 400:
```json
{
  "data": null,
  "process_time": "3.1102ms",
  "status": "error",
  "code": "01",
  "message": "time_remaining_days must be an integer between 1 and 365."
}
```

### 9.3 Endpoint yang sudah ada dan berubah perilakunya

`POST /api/v1/contracts/contract-value-depletion-warning-notif` — kini menerima `frequency = "one_time"` selain `daily` / `weekly` (FR-013). Bentuk permintaan/respons tidak berubah.

## 10. Traceability

| Goal / Story | FR |
|---|---|
| G1, US-01 | FR-006, FR-008, FR-009, FR-011, FR-012 |
| G2, US-02 | FR-007, FR-008, FR-010, FR-011, FR-012 |
| G3, US-04, US-05 | FR-001, FR-002, FR-003, FR-004, NFR-001 |
| G4, US-06, US-07 | FR-005, FR-013, FR-014 |
| G5, US-03 | FR-009, FR-010, FR-011, FR-012, FR-015 |
| G6, US-08 | FR-016 |
| A3 / R2 | FR-015 |
