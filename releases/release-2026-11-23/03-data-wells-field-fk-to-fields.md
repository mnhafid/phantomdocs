# 03 — Data: FK wells.field_id dari well_fields ke fields

- **Ticket / PR:** migration `20260708053153_RepointWellsFieldToFields` (sudah ada di kode)
- **Dicatat:** 20 Nov 2026
- **Status:** SQL diberikan untuk dev `APP_PHANTOM_DEV_Z9`; menunggu user menjalankan. Prod belum dicek.

## Alasan

Update well gagal: `DbUpdateException` karena `FK_wells_well_fields_field_id`. Kode (WellPhssService /
WellPepService) memvalidasi `field_id` ke tabel `fields`, tetapi DB dev masih punya FK lama ke `well_fields`
(migration repoint belum jalan di DB ini). Sebagian well masih menyimpan id `well_fields`.

## Perubahan (SQL, jalankan satu per satu di DBeaver)

```sql
ALTER TABLE wells DROP CONSTRAINT IF EXISTS FK_wells_well_fields_field_id;

-- preview orphan
SELECT w.id, w.well_name, w.field_id, wf.name AS well_field_name, f.field_id AS new_field_id
FROM wells w LEFT JOIN well_fields wf ON wf.id = w.field_id
LEFT JOIN fields f ON LTRIM(RTRIM(f.name)) = LTRIM(RTRIM(wf.name)) AND f.deleted_at IS NULL
WHERE w.field_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fields x WHERE x.field_id = w.field_id);

-- remap by name
UPDATE w SET w.field_id = f.field_id, w.updated_at = GETDATE()
FROM wells w JOIN well_fields wf ON wf.id = w.field_id
JOIN fields f ON LTRIM(RTRIM(f.name)) = LTRIM(RTRIM(wf.name)) AND f.deleted_at IS NULL
WHERE NOT EXISTS (SELECT 1 FROM fields x WHERE x.field_id = w.field_id);

-- preview lagi harus 0 baris; sisa → insert ke fields (dengan working_area) atau SET field_id = NULL

ALTER TABLE wells WITH CHECK ADD CONSTRAINT FK_wells_fields_field_id
  FOREIGN KEY (field_id) REFERENCES fields (field_id);
```

## Langkah deploy (prod)

1. Cek FK yang ada: `SELECT name, OBJECT_NAME(referenced_object_id) FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('wells');`
2. Kalau masih `FK_wells_well_fields_field_id` → jalankan SQL di atas. Kalau sudah `FK_wells_fields_field_id` → skip.
3. Terkait: master `well_types` (Oil/Gas) dan `well_lifting_types` harus ada dan `is_active = 1`.
   Nama lifting type harus persis (case-sensitive) seperti di `MapArtificialLiftCode`:
   `Natural Flow`, `Artificial Lift`, `Artificial Lift GL`, `Artificial Lift PUMP`.

## Verifikasi

1. Preview orphan = 0 baris.
2. `sys.foreign_keys` menunjukkan `FK_wells_fields_field_id` → `fields`.
3. Update well PHSS/PEP dengan `fieldId` dari `/fields` → 200, tidak ada error 547.
