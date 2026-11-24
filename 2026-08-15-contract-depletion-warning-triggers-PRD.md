# PRD: Contract Depletion Warning — Trigger Threshold & Reminder Frequency

| | |
|---|---|
| **Status** | Draft |
| **Date** | 2026-08-15 |
| **Version** | 0.2 |
| **Related FSD** | [2026-08-15-contract-depletion-warning-triggers-FSD.md](2026-08-15-contract-depletion-warning-triggers-FSD.md) |

## 1. Latar Belakang

Warning depletion kontrak **sudah berjalan** di phiDev: `ContractDepletionNotifyJob` (Quartz) memanggil `IDataScienceService.TriggerDepletionNotificationsAsync`, yang mengambil baris `ds_contract_warning_dates` yang jatuh tempo lalu meneruskannya ke `ContractsService.SendContractValueDepletionWarningNotificationAsync` (email + notifikasi in-app + lampiran `.xlsx`).

Satu-satunya trigger hari ini adalah hasil **forecast**: sistem meramal kurva serapan SPK, menghitung `warning_date`, lalu mulai mengirim 14 hari sebelumnya (`start_notif_date = warning_date − 14 hari`, angka hardcoded) sampai `contract_end_date`. Konsekuensinya:

- Kontrak yang **waktunya hampir habis** hanya tertangkap kalau forecast kebetulan menandainya; tidak ada ambang waktu eksplisit yang bisa diatur user.
- Kontrak yang **nilainya hampir habis** tidak punya ambang persentase yang bisa diatur user.
- Emailnya satu per penerima berisi banyak kontrak sekaligus dalam lampiran `.xlsx` — sulit dibaca dan tidak menyebut alasan spesifik per kontrak.
- Frekuensi pengiriman hanya `daily` / `weekly`; tidak ada opsi "sekali saja".
- Ambang forecast (14 hari) hanya bisa diubah lewat deploy.

Di sisi lain, modul **Contract Monitoring — Contract Critical** sudah punya sepasang ambang sendiri (`contracts.budget_threshold`, `contracts.time_threshold`) dengan makna yang identik. Dua pasang angka untuk konsep yang sama adalah sumber kebingungan; rilis ini menyatukannya ke satu pasang.

## 2. Tujuan

| ID | Tujuan | Metrik |
|---|---|---|
| **G1** | Warning bisa dipicu oleh sisa waktu kontrak, dengan ambang yang diatur user | 100% kontrak `approved_active` dengan sisa hari ≤ ambang menerima email pada job run berikutnya |
| **G2** | Warning bisa dipicu oleh sisa nilai kontrak, dengan ambang persentase yang diatur user | 100% kontrak `approved_active` dengan sisa nilai % ≤ ambang menerima email pada job run berikutnya |
| **G3** | Ambang & frekuensi bisa diubah tanpa deploy | Perubahan berlaku pada job run berikutnya (≤ 24 jam untuk `daily`), tanpa restart aplikasi |
| **G4** | User bisa memilih diingatkan sekali saja | Frequency `one_time` mengirim tepat 1 kali saat disimpan, dan 0 kali setelahnya — termasuk sesudah restart aplikasi |
| **G5** | Email warning bisa langsung ditindaklanjuti | 1 email per kontrak per jenis trigger, dengan subject yang menyebut jenis pelanggarannya dan tombol menuju detail kontrak |
| **G6** | Satu pasang ambang dipakai bersama oleh Warning dan Contract Critical | Contract Critical membaca ambang yang sama; tidak ada pasangan angka kedua yang perlu disetel admin |

## 3. Persona

| Persona | Deskripsi |
|---|---|
| **Contract PIC** | User yang terdaftar di `contract_pics` untuk sebuah kontrak. Penerima warning. Perlu tahu lebih awal bahwa nilai/waktu kontraknya menipis supaya sempat mengajukan amandemen atau tender baru. |
| **Contract Admin** | User yang menyetel ambang & frekuensi untuk seluruh organisasi. Ingin mengatur seberapa dini dan seberapa sering peringatan dikirim tanpa minta bantuan developer. |

## 4. User Stories

| ID | Story |
|---|---|
| **US-01** | Sebagai **Contract PIC**, saya ingin menerima peringatan saat kontrak saya tinggal X hari lagi, supaya saya punya waktu memproses perpanjangan atau tender baru. |
| **US-02** | Sebagai **Contract PIC**, saya ingin menerima peringatan saat sisa nilai kontrak saya tinggal X persen atau kurang, supaya pekerjaan tidak terhenti karena nilai kontrak habis. |
| **US-03** | Sebagai **Contract PIC**, saya ingin satu email untuk satu kontrak dengan subject yang jelas dan tombol menuju detail kontrak, supaya saya tahu kontrak mana yang bermasalah tanpa membuka lampiran. |
| **US-04** | Sebagai **Contract Admin**, saya ingin mengatur ambang sisa waktu (hari) lewat Custom Configuration, supaya dini-nya peringatan bisa disesuaikan tanpa deploy. |
| **US-05** | Sebagai **Contract Admin**, saya ingin mengatur ambang sisa nilai (persen, 2 desimal) lewat Custom Configuration, dengan alasan yang sama. |
| **US-06** | Sebagai **Contract Admin**, saya ingin memilih frekuensi pengingat (Daily / Weekly / One Time), supaya penerima tidak kebanjiran email untuk kontrak yang sama. |
| **US-07** | Sebagai **Contract Admin**, saya ingin nilai default yang aman saat frekuensi belum pernah disetel (One Time), supaya sistem tidak diam-diam mengirim tiap hari. |
| **US-08** | Sebagai **Contract Admin**, saya ingin ambang yang saya setel juga dipakai Contract Critical, supaya tidak ada dua angka yang harus dijaga tetap sinkron. |

## 5. Non-Goals

- **Tidak** mengganti atau mematikan trigger forecast yang ada. Trigger baru berjalan berdampingan — keputusan eksplisit, lihat A1.
- **Tidak** mengubah penerima warning. Penerima tetap `contract_pics`; daftar `recipients` di `contract_value_depletion_warning_notifications` tetap tersimpan-tapi-tidak-dipakai seperti sekarang (lihat R1).
- **Tidak** mengubah rumus atau tampilan Contract Critical. Yang berubah hanya dari baris config mana angkanya dibaca (G6).
- **Tidak** mengubah algoritma forecast (`DataScienceSeries.GetWarningAndEndIx`), tabel `ds_contract_depletion_weekly_data`, maupun grafik depletion.
- **Tidak** membuat konfigurasi per-kontrak atau per-department. Ketiga config bersifat global.
- **Tidak** membangun UI. Cakupan dokumen ini backend: seed config, endpoint, evaluasi trigger, penjadwalan, email.
- **Tidak** menghapus baris `contracts.budget_threshold` / `contracts.time_threshold` yang lama. Baris itu berhenti dibaca; pembersihannya tiket terpisah.
- **Tidak** melakukan backfill riwayat pengiriman warning.

## 6. Assumptions

Diputuskan bersama user saat grilling, 2026-08-15:

| ID | Asumsi |
|---|---|
| **A1** | Trigger baru **menambah**, bukan mengganti, trigger forecast. Kontrak yang kena forecast dan ambang sekaligus menerima email dari keduanya. |
| **A2** | Nama key config memakai prefix `contracts.`: `contracts.warning_time_remaining`, `contracts.warning_remaining_available_value`, `contracts.warning_reminder_frequency`. Berbeda dari tulisan literal di tiket (`warning.*`). |
| **A3** | Penerima tidak berubah: `contract_pics` yang aktif dan punya email. |
| **A4** | Sumber kebenaran frekuensi tetap kolom `contract_value_depletion_warning_notifications.frequency`. Custom config hanya dipakai sebagai **default** saat kolom tersebut kosong/tidak dikenal. |
| **A5** | `one_time` berarti **kirim sekali saat setting disimpan**, tanpa jadwal berulang. Bukan "sekali per kontrak". |
| **A6** | Trigger sisa waktu memakai **jendela** `sisa hari ≤ X`, bukan tepat di H-X. Menyimpang dari contoh di AC (X=2 → hanya 8 Juni): dengan jendela, kontrak juga diingatkan di H-1 dan H-0. Dipilih supaya tanggal warning tidak hilang saat frekuensi `weekly`/`one_time` atau saat satu job run gagal. |
| **A7** | Warning berbasis ambang memakai **dua template email terpisah** — satu per jenis trigger — dan tidak memakai lampiran `.xlsx`. Warning forecast tetap memakai template dan lampirannya yang lama. |
| **A8** | Satu email per kontrak per jenis trigger, dikirim ke **semua PIC kontrak itu sekaligus** di kolom To. Kontrak dengan 3 PIC menghasilkan 1 email, bukan 3. |
| **A9** | Sisa nilai persen memakai rumus yang sudah dipakai Contract Critical: `(contract_value − spk_value) / contract_value × 100`, dibulatkan 2 desimal. |
| **A10** | Hanya kontrak `approved_active` (status `approved`, `start_date ≤ hari ini ≤ contract_end_date`) yang dievaluasi — sama dengan `RecalculateDepletionAsync`. |
| **A11** | Config yang belum di-seed / nilainya tidak valid **mematikan trigger terkait**, bukan jatuh ke angka tebakan. Untuk Contract Critical, config yang hilang berarti tetap memakai default kode yang berlaku sekarang. |
| **A12** | Baris config **dibuat baru** dengan nilai default rilis ini; nilai baris lama tidak otomatis disalin. Kalau perilaku Contract Critical harus persis sama seperti sebelum rilis, nilai lama disalin manual saat deploy (lihat R5). |
| **A13** | Ketiga config disetel lewat endpoint khusus dengan validasi tipe, bukan lewat CRUD custom-configuration generik. |

## 7. Risiko

| ID | Risiko | Mitigasi |
|---|---|---|
| **R1** | User story aslinya berbunyi "Recipient dari warning dapat menerima notifikasi", padahal kode mengirim ke PIC dan mengabaikan `recipients` yang tersimpan. User memilih mempertahankan perilaku ini (A3). | Dicatat sebagai perilaku yang diketahui. Kalau yang dimaksud daftar `recipients`, itu perubahan satu query — tiket terpisah. |
| **R2** | Kontrak tanpa PIC aktif tidak menghasilkan email apa pun dan tidak ada jejaknya. Trigger baru memperbesar jumlah kontrak yang terdampak. | FR-016: catat log peringatan berisi jumlah dan daftar `contract_id` yang jatuh tempo tanpa penerima. |
| **R3** | Ambang longgar (mis. 365 hari) + frekuensi `daily` membuat hampir semua kontrak dikirimi email tiap hari, dan sekarang satu email per kontrak per trigger. | Validasi range di endpoint (FR-004), `one_time` sebagai default, dan catatan volume di FSD §8. |
| **R4** | `one_time` mengirim saat penyimpanan; menyimpan berulang kali berarti mengirim berulang kali. | Didokumentasikan di FSD §5 dan di respons endpoint; tidak ada peredam pada rilis ini. |
| **R5** | Contract Critical dialihkan ke baris config baru yang di-seed dengan nilai default (A12). Kalau nilai lama berbeda, klasifikasi Critical berubah pada hari rilis. | Tiket seed (T-01) mewajibkan pengecekan nilai `contracts.budget_threshold` / `contracts.time_threshold` di tiap environment dan menyalinnya bila perlu; nilai lama dicatat di catatan rilis. |
