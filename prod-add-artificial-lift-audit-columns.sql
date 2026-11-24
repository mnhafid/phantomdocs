/* ============================================================
   PRODUCTION — tambah audit column ke phss_action_plan_artificial_lift
   Padanan manual dari migration 20260726152410_AddArtificialLiftAuditColumns.

   Jalankan di PRODUCTION sebelum deploy kode. Kalau kode naik duluan,
   query detail PHSS akan SELECT kolom yang belum ada -> endpoint 500.

   JALANKAN LEWAT sqlcmd ATAU SSMS. Script ini memakai pemisah GO, dan itu
   WAJIB, bukan gaya penulisan: SQL Server meng-compile satu batch sekaligus,
   jadi CREATE INDEX yang menyebut deleted_at akan gagal 'Invalid column name'
   kalau kolomnya ditambah di batch yang sama. GO memaksa batch baru.
   Kalau dijalankan lewat tool yang membuang GO, jalankan tiap bagian
   satu per satu, berurutan.

   Semua blok ber-guard, jadi aman dijalankan ulang.

   TIDAK menulis ke __EFMigrationsHistory — prod dikelola manual.
   Konsekuensinya di bagian 4.
   ============================================================ */

SET NOCOUNT ON;
GO

/* ============================================================
   BAGIAN 1 — tambah tiga kolom
   ============================================================ */

/* ---------- created_at ----------
   NOT NULL + DEFAULT (getdate()). Baris yang sudah ada semuanya dapat
   timestamp SAMA (waktu script ini jalan) — waktu tulis aslinya tidak
   tersimpan di mana pun dan tidak bisa dipulihkan.

   Akibatnya baris-baris lama SERI, dan created_at saja tidak bisa
   memisahkan mereka. Kode menengahi seri itu dengan action_mode menurun,
   yang memilih mode '_update' di atas '_schedule' pasangannya.
   created_at baru akurat untuk baris yang ditulis SETELAH ini.

   DILEWATI kalau kolomnya sudah ada.                                       */
IF COL_LENGTH('dbo.phss_action_plan_artificial_lift', 'created_at') IS NULL
BEGIN
    ALTER TABLE dbo.phss_action_plan_artificial_lift
        ADD created_at datetime NOT NULL CONSTRAINT DF_phss_al_created_at DEFAULT (getdate());
END;
GO

/* ---------- updated_at ----------
   NULL sampai barisnya benar-benar diedit. Baris baru hanya punya
   created_at. Terisi saat draft di-update: sejak perubahan ini baris
   artificial_lift di-update DI TEMPAT (mengikuti pola choke & well_test),
   bukan dihapus lalu disisipkan ulang.                                     */
IF COL_LENGTH('dbo.phss_action_plan_artificial_lift', 'updated_at') IS NULL
BEGIN
    ALTER TABLE dbo.phss_action_plan_artificial_lift ADD updated_at datetime NULL;
END;
GO

/* ---------- deleted_at ----------
   Soft delete. Terisi saat plan berpindah ke tipe lain, atau saat baris
   berlebih dirapikan menjadi satu baris hidup per plan.                    */
IF COL_LENGTH('dbo.phss_action_plan_artificial_lift', 'deleted_at') IS NULL
BEGIN
    ALTER TABLE dbo.phss_action_plan_artificial_lift ADD deleted_at datetime NULL;
END;
GO

/* ============================================================
   BAGIAN 2 — ganti index unik supaya sadar soft delete

   INI BAGIAN YANG PALING PENTING, jangan dilewat.

   Filter lamanya '[action_mode] IS NOT NULL' — itu filter otomatis EF untuk
   kolom unik yang nullable, BUKAN filter soft delete. Tanpa
   'AND deleted_at IS NULL', baris yang sudah di-soft-delete TETAP memegang
   slot (action_plan_id, action_mode)-nya, sehingga submit ulang mode yang
   sama gagal duplicate key — persis bug compressor_plant_types yang
   diperbaiki di PR #437.

   Drop dan create dibungkus SATU transaksi supaya tabel tidak pernah
   tertinggal tanpa index unik kalau ada kegagalan di tengah.

   KALAU CREATE INDEX GAGAL: berarti ada dua baris HIDUP dengan
   (action_plan_id, action_mode) yang sama. Transaksi rollback, index lama
   kembali, tidak ada yang rusak. Cek dengan query di bagian 5, rapikan,
   lalu jalankan ulang script ini.
   ============================================================ */

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF EXISTS (SELECT 1 FROM sys.indexes
           WHERE name = 'IX_phss_action_plan_artificial_lift_action_plan_id_action_mode'
             AND object_id = OBJECT_ID('dbo.phss_action_plan_artificial_lift'))
BEGIN
    DROP INDEX [IX_phss_action_plan_artificial_lift_action_plan_id_action_mode]
        ON dbo.phss_action_plan_artificial_lift;
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_phss_action_plan_artificial_lift_action_plan_id_action_mode'
                 AND object_id = OBJECT_ID('dbo.phss_action_plan_artificial_lift'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [IX_phss_action_plan_artificial_lift_action_plan_id_action_mode]
        ON dbo.phss_action_plan_artificial_lift (action_plan_id, action_mode)
        WHERE action_mode IS NOT NULL AND deleted_at IS NULL;
END;

COMMIT TRANSACTION;
GO

/* ============================================================
   BAGIAN 3 — verifikasi

   Harapan:
     3 baris kolom -> created_at (NO), updated_at (YES), deleted_at (YES)
     filter index  -> ([action_mode] IS NOT NULL AND [deleted_at] IS NULL)
     bentrok       -> 0
   ============================================================ */

SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME = 'phss_action_plan_artificial_lift'
  AND  COLUMN_NAME IN ('created_at', 'updated_at', 'deleted_at')
ORDER  BY COLUMN_NAME;

SELECT i.name AS index_name, i.is_unique, ISNULL(i.filter_definition, '-') AS filter_definition
FROM   sys.indexes i
WHERE  i.object_id = OBJECT_ID('dbo.phss_action_plan_artificial_lift')
  AND  i.name LIKE 'IX_%';

SELECT COUNT(*) AS pasangan_bentrok
FROM  (SELECT action_plan_id, action_mode
       FROM   dbo.phss_action_plan_artificial_lift
       WHERE  deleted_at IS NULL AND action_mode IS NOT NULL
       GROUP  BY action_plan_id, action_mode
       HAVING COUNT(*) > 1) t;
GO

/* ============================================================
   BAGIAN 4 — catatan __EFMigrationsHistory

   Script ini SENGAJA tidak mencatat migration-nya. Artinya kalau suatu saat
   prod dijalankan lewat `dotnet ef database update`, EF akan mencoba
   menambah kolom ini lagi dan GAGAL.

   Kalau prod nanti mau dikelola EF, jalankan baris ini SEKALI:

     INSERT INTO dbo.__EFMigrationsHistory (MigrationId, ProductVersion)
     VALUES (N'20260726152410_AddArtificialLiftAuditColumns', N'9.0.0');
   ============================================================ */

/* ============================================================
   BAGIAN 5 — laporan plan dengan lebih dari satu baris hidup

   Bukan error, dan tidak memblokir apa pun: mode-nya berbeda-beda, jadi
   index di bagian 2 tetap lolos. Ini hanya laporan.

   Plan seperti ini lahir dari desain lama yang menumpuk beberapa mode dalam
   satu plan. Detail sekarang menampilkan SATU baris (yang terbaru), jadi
   sisanya tidak terlihat di detail — walau tetap muncul di list.
   Rapikan lewat aplikasi kalau ingin detail dan list benar-benar sinkron.
   ============================================================ */

SELECT   action_plan_id, COUNT(*) AS baris_hidup
FROM     dbo.phss_action_plan_artificial_lift
WHERE    deleted_at IS NULL
GROUP BY action_plan_id
HAVING   COUNT(*) > 1
ORDER BY baris_hidup DESC;
GO
