-- Seeds the admin-managed holiday row read by CalendarsService.HolidayConfigName ("calendars.holiday").
-- Fixed-date Indonesian national holidays only. The movable ones (Idul Fitri, Idul Adha, Tahun Baru
-- Islam, Maulid, Isra Miraj, Imlek, Nyepi, Waisak, Wafat/Kenaikan Isa Almasih) are set each year by
-- the SKB 3 Menteri decree - an admin adds those through the custom-configurations UI.
-- Keys are dd-MM-yyyy, matching what the API renders. The reader also accepts the older yyyy-MM-dd,
-- so a row seeded before the format change keeps working - but new rows use this shape.
-- Idempotent: the UPDATE refreshes an existing row, the INSERT only fires when there is none.
UPDATE custom_configurations
SET detail = '[{"key":"01-01-2026","value":"Tahun Baru Masehi","note":"Valid value is dd-MM-yyyy"},{"key":"01-05-2026","value":"Hari Buruh Internasional","note":"Valid value is dd-MM-yyyy"},{"key":"01-06-2026","value":"Hari Lahir Pancasila","note":"Valid value is dd-MM-yyyy"},{"key":"17-08-2026","value":"Hari Kemerdekaan RI","note":"Valid value is dd-MM-yyyy"},{"key":"25-12-2026","value":"Hari Raya Natal","note":"Valid value is dd-MM-yyyy"},{"key":"01-01-2027","value":"Tahun Baru Masehi","note":"Valid value is dd-MM-yyyy"},{"key":"01-05-2027","value":"Hari Buruh Internasional","note":"Valid value is dd-MM-yyyy"},{"key":"01-06-2027","value":"Hari Lahir Pancasila","note":"Valid value is dd-MM-yyyy"},{"key":"17-08-2027","value":"Hari Kemerdekaan RI","note":"Valid value is dd-MM-yyyy"},{"key":"25-12-2027","value":"Hari Raya Natal","note":"Valid value is dd-MM-yyyy"}]',
    updated_at = GETDATE(),
    updated_by = '904e638b-dc1d-46ee-81d6-bec0aea1dc6a'
WHERE name = 'calendars.holiday' AND deleted_at IS NULL

INSERT INTO custom_configurations (id, name, description, detail, created_at, created_by, updated_at, updated_by)
SELECT '3f2b9c14-5d8e-4a71-9c02-7e6a1b4d0f33',
       'calendars.holiday',
       'Admin-declared holidays merged into GET /api/v1/calendars/holiday (key = dd-MM-yyyy, value = label)',
       '[{"key":"01-01-2026","value":"Tahun Baru Masehi","note":"Valid value is dd-MM-yyyy"},{"key":"01-05-2026","value":"Hari Buruh Internasional","note":"Valid value is dd-MM-yyyy"},{"key":"01-06-2026","value":"Hari Lahir Pancasila","note":"Valid value is dd-MM-yyyy"},{"key":"17-08-2026","value":"Hari Kemerdekaan RI","note":"Valid value is dd-MM-yyyy"},{"key":"25-12-2026","value":"Hari Raya Natal","note":"Valid value is dd-MM-yyyy"},{"key":"01-01-2027","value":"Tahun Baru Masehi","note":"Valid value is dd-MM-yyyy"},{"key":"01-05-2027","value":"Hari Buruh Internasional","note":"Valid value is dd-MM-yyyy"},{"key":"01-06-2027","value":"Hari Lahir Pancasila","note":"Valid value is dd-MM-yyyy"},{"key":"17-08-2027","value":"Hari Kemerdekaan RI","note":"Valid value is dd-MM-yyyy"},{"key":"25-12-2027","value":"Hari Raya Natal","note":"Valid value is dd-MM-yyyy"}]',
       GETDATE(), '904e638b-dc1d-46ee-81d6-bec0aea1dc6a', GETDATE(), '904e638b-dc1d-46ee-81d6-bec0aea1dc6a'
WHERE NOT EXISTS (SELECT 1 FROM custom_configurations WHERE name = 'calendars.holiday' AND deleted_at IS NULL)
