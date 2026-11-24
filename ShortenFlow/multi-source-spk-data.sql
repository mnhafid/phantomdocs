-- =====================================================================================
-- [SHORTENFLOW] Multi Source SPK — QA fixture, one task per spreadsheet case
--
--   Doc set : docs/ShortenFlow/2026-09-07-multi-source-spk-TICKETS.md (+ HANDOFF.md)
--   Cases   : docs/ShortenFlow/multi-source-spk-cases.md (data + executed results)
--   QA plan : "Multi Source SPK" sheet, cases 001–019
--   Target  : SQL Server (phantomdb, dev)   ·   Version 1.1  ·  2026-09-07
--
-- WHAT THIS IS
--   Self-contained starting data for every case on the QA sheet. One contractor, SEVEN
--   contracts (each with one active BOQ), one in-progress project and one task PER CASE.
--   No task has an SPK BoQ, draft or SPK: the run builds those.
--
--   contracts (…0002 etc. = 5F000001-0000-4000-8000-0000000000XX)
--     X  …0002  approved, active, 2,000,000,000     the "same contract" selections
--     Y  …0005  approved, active, 1,500,000,000     the "different contract" selection
--     Z  …0008  approved, ENDED 2026-06-30          006 "approve inactive"
--     D  …000B  draft                               007
--     H  …000E  on hold                             008
--     F  …0011  finished                            009
--     S  …0014  approved, value only 50,000,000     014 insufficient contract value at Create SPK
--
--   tasks (…03NN) — case NN, budget (estimated_cost) in the comment of each INSERT
--
-- VISIBILITY
--   projects.department_id / contracts.department_id / users.department must agree for the
--   list, picker and create endpoints. Every row is stamped 'Project' = r3test.agil's
--   department. FIXTURE_USER = 8ad89747-d543-4a0a-a2ff-57e9960535e0 (R3TEST.AGIL).
--
-- RE-RUNS
--   Everything hangs off contractor …0001 and project …0004, so Section 1 deletes by those
--   two roots — INCLUDING whatever a QA run attached (drafts, lines, links, assignments,
--   SPKs, schedules, progress). Section 1 alone is the teardown. Re-running lands on the
--   same state. The older shorten-flow fixture owns 5F000000-…; this one owns 5F000001-….
--
-- PORTABILITY
--   No DECLARE, no GO. Units by NAME through inline subqueries ('Unit','Pcs','Lot','Set',
--   'm','m3' exist on dev). unique_id starts at 960001 (dev max was 950002).
-- =====================================================================================


-- =====================================================================================
-- SECTION 1 — TEARDOWN (children first; scoped by project …0004 and contractor …0001)
-- =====================================================================================

DELETE FROM project_task_boq_drafts
WHERE project_task_id IN (SELECT id FROM project_tasks WHERE project_id = '5F000001-0000-4000-8000-000000000004');

DELETE FROM spk_boq_progresses
WHERE spk_boq_schedule_id IN (
    SELECT s.id FROM spk_boq_schedules s
    JOIN spk_boqs sb ON sb.id = s.spk_boq_id
    JOIN spks sp ON sp.spk_id = sb.spk_id
    WHERE sp.contract_id IN (SELECT contract_id FROM contracts WHERE contractor_id = '5F000001-0000-4000-8000-000000000001'));

DELETE FROM spk_boq_schedules
WHERE spk_boq_id IN (
    SELECT sb.id FROM spk_boqs sb
    JOIN spks sp ON sp.spk_id = sb.spk_id
    WHERE sp.contract_id IN (SELECT contract_id FROM contracts WHERE contractor_id = '5F000001-0000-4000-8000-000000000001'));

DELETE FROM spk_boqs
WHERE spk_id IN (SELECT spk_id FROM spks
                 WHERE contract_id IN (SELECT contract_id FROM contracts WHERE contractor_id = '5F000001-0000-4000-8000-000000000001'))
   OR project_task_boq_id IN (SELECT id FROM project_task_boqs
                              WHERE project_task_id IN (SELECT id FROM project_tasks WHERE project_id = '5F000001-0000-4000-8000-000000000004'));

DELETE FROM project_task_boq_details
WHERE project_task_boq_id IN (SELECT id FROM project_task_boqs
                              WHERE project_task_id IN (SELECT id FROM project_tasks WHERE project_id = '5F000001-0000-4000-8000-000000000004'));

DELETE FROM project_task_boqs
WHERE project_task_id IN (SELECT id FROM project_tasks WHERE project_id = '5F000001-0000-4000-8000-000000000004');

DELETE FROM project_task_spks
WHERE project_task_id IN (SELECT id FROM project_tasks WHERE project_id = '5F000001-0000-4000-8000-000000000004');

DELETE FROM spks
WHERE contract_id IN (SELECT contract_id FROM contracts WHERE contractor_id = '5F000001-0000-4000-8000-000000000001');

DELETE FROM project_tasks
WHERE project_id = '5F000001-0000-4000-8000-000000000004';

DELETE FROM projects
WHERE id = '5F000001-0000-4000-8000-000000000004';

DELETE FROM boq_details
WHERE boq_id IN (SELECT id FROM boqs
                 WHERE contract_id IN (SELECT contract_id FROM contracts WHERE contractor_id = '5F000001-0000-4000-8000-000000000001'));

DELETE FROM boqs
WHERE contract_id IN (SELECT contract_id FROM contracts WHERE contractor_id = '5F000001-0000-4000-8000-000000000001');

DELETE FROM contracts
WHERE contractor_id = '5F000001-0000-4000-8000-000000000001';

DELETE FROM contractors
WHERE id = '5F000001-0000-4000-8000-000000000001';


-- =====================================================================================
-- SECTION 2 — CONTRACTOR AND CONTRACTS
-- =====================================================================================

INSERT INTO contractors (id, code, name, address, telephone, email, is_active, created_at, created_by)
VALUES ('5F000001-0000-4000-8000-000000000001', 'MSSPK-FIXTURE',
        'PT Multi Source SPK Fixture', 'Jl. Fixture No. 2, Jakarta', '021-0000001',
        'msspk@example.invalid', 1, '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0');

-- 2.1 X — approved, active --------------------------------------------------------------
INSERT INTO contracts (contract_id, contractor_id, contract_no, contract_title,
                       start_date, work_end_date, contract_end_date,
                       contract_value, spk_count, spk_value, physical_progress_value,
                       sa_value, invoice_value, status, autogenerated_spk_number,
                       retention_percentage, currency, department_id, created_at, created_by)
VALUES ('5F000001-0000-4000-8000-000000000002', '5F000001-0000-4000-8000-000000000001',
        'MSSPK/X/2026', 'Multi Source SPK — Kontrak X (aktif)',
        '2026-08-01', '2027-05-31', '2027-06-30',
        2000000000, 0, 0, 0, 0, 0, 'approved', 1,
        10.00, 'IDR', 'Project', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0');

-- 2.2 Y — approved, active --------------------------------------------------------------
INSERT INTO contracts (contract_id, contractor_id, contract_no, contract_title,
                       start_date, work_end_date, contract_end_date,
                       contract_value, spk_count, spk_value, physical_progress_value,
                       sa_value, invoice_value, status, autogenerated_spk_number,
                       retention_percentage, currency, department_id, created_at, created_by)
VALUES ('5F000001-0000-4000-8000-000000000005', '5F000001-0000-4000-8000-000000000001',
        'MSSPK/Y/2026', 'Multi Source SPK — Kontrak Y (aktif)',
        '2026-08-01', '2027-05-31', '2027-06-30',
        1500000000, 0, 0, 0, 0, 0, 'approved', 1,
        10.00, 'IDR', 'Project', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0');

-- 2.3 Z — approved but ENDED (006) ------------------------------------------------------
INSERT INTO contracts (contract_id, contractor_id, contract_no, contract_title,
                       start_date, work_end_date, contract_end_date,
                       contract_value, spk_count, spk_value, physical_progress_value,
                       sa_value, invoice_value, status, autogenerated_spk_number,
                       retention_percentage, currency, department_id, created_at, created_by)
VALUES ('5F000001-0000-4000-8000-000000000008', '5F000001-0000-4000-8000-000000000001',
        'MSSPK/Z/2025', 'Multi Source SPK — Kontrak Z (approved, sudah berakhir)',
        '2025-07-01', '2026-05-31', '2026-06-30',
        800000000, 0, 0, 0, 0, 0, 'approved', 0,
        5.00, 'IDR', 'Project', '2025-07-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0');

-- 2.4 D — draft (007) ------------------------------------------------------------------
INSERT INTO contracts (contract_id, contractor_id, contract_no, contract_title,
                       start_date, work_end_date, contract_end_date,
                       contract_value, spk_count, spk_value, physical_progress_value,
                       sa_value, invoice_value, status, autogenerated_spk_number,
                       retention_percentage, currency, department_id, created_at, created_by)
VALUES ('5F000001-0000-4000-8000-00000000000B', '5F000001-0000-4000-8000-000000000001',
        'MSSPK/D/2026', 'Multi Source SPK — Kontrak D (draft)',
        '2026-09-01', '2027-05-31', '2027-06-30',
        600000000, 0, 0, 0, 0, 0, 'draft', 0,
        5.00, 'IDR', 'Project', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0');

-- 2.5 H — on hold (008) ----------------------------------------------------------------
INSERT INTO contracts (contract_id, contractor_id, contract_no, contract_title,
                       start_date, work_end_date, contract_end_date,
                       contract_value, spk_count, spk_value, physical_progress_value,
                       sa_value, invoice_value, status, autogenerated_spk_number,
                       retention_percentage, currency, department_id, created_at, created_by)
VALUES ('5F000001-0000-4000-8000-00000000000E', '5F000001-0000-4000-8000-000000000001',
        'MSSPK/H/2026', 'Multi Source SPK — Kontrak H (on hold)',
        '2026-09-01', '2027-05-31', '2027-06-30',
        600000000, 0, 0, 0, 0, 0, 'on hold', 0,
        5.00, 'IDR', 'Project', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0');

-- 2.6 F — finished (009) ---------------------------------------------------------------
INSERT INTO contracts (contract_id, contractor_id, contract_no, contract_title,
                       start_date, work_end_date, contract_end_date,
                       contract_value, spk_count, spk_value, physical_progress_value,
                       sa_value, invoice_value, status, autogenerated_spk_number,
                       retention_percentage, currency, department_id, created_at, created_by)
VALUES ('5F000001-0000-4000-8000-000000000011', '5F000001-0000-4000-8000-000000000001',
        'MSSPK/F/2025', 'Multi Source SPK — Kontrak F (finished)',
        '2025-01-01', '2026-06-30', '2027-06-30',
        600000000, 0, 0, 0, 0, 0, 'finished', 0,
        5.00, 'IDR', 'Project', '2025-01-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0');

-- 2.7 S — approved, value only 50,000,000 (014: its single line is 80,000,000) -----------
INSERT INTO contracts (contract_id, contractor_id, contract_no, contract_title,
                       start_date, work_end_date, contract_end_date,
                       contract_value, spk_count, spk_value, physical_progress_value,
                       sa_value, invoice_value, status, autogenerated_spk_number,
                       retention_percentage, currency, department_id, created_at, created_by)
VALUES ('5F000001-0000-4000-8000-000000000014', '5F000001-0000-4000-8000-000000000001',
        'MSSPK/S/2026', 'Multi Source SPK — Kontrak S (nilai kontrak kecil)',
        '2026-08-01', '2027-05-31', '2027-06-30',
        50000000, 0, 0, 0, 0, 0, 'approved', 1,
        10.00, 'IDR', 'Project', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0');


-- =====================================================================================
-- SECTION 3 — BOQs (one active version each) AND LINES
-- =====================================================================================

INSERT INTO boqs (id, contract_id, original_file, is_active, version, created_at, created_by, template_type)
VALUES ('5F000001-0000-4000-8000-000000000003', '5F000001-0000-4000-8000-000000000002', 'msspk-x.xlsx', 1, 1, '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'type_n');
INSERT INTO boqs (id, contract_id, original_file, is_active, version, created_at, created_by, template_type)
VALUES ('5F000001-0000-4000-8000-000000000006', '5F000001-0000-4000-8000-000000000005', 'msspk-y.xlsx', 1, 1, '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'type_n');
INSERT INTO boqs (id, contract_id, original_file, is_active, version, created_at, created_by, template_type)
VALUES ('5F000001-0000-4000-8000-000000000009', '5F000001-0000-4000-8000-000000000008', 'msspk-z.xlsx', 1, 1, '2025-07-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'type_n');
INSERT INTO boqs (id, contract_id, original_file, is_active, version, created_at, created_by, template_type)
VALUES ('5F000001-0000-4000-8000-00000000000C', '5F000001-0000-4000-8000-00000000000B', 'msspk-d.xlsx', 1, 1, '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'type_n');
INSERT INTO boqs (id, contract_id, original_file, is_active, version, created_at, created_by, template_type)
VALUES ('5F000001-0000-4000-8000-00000000000F', '5F000001-0000-4000-8000-00000000000E', 'msspk-h.xlsx', 1, 1, '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'type_n');
INSERT INTO boqs (id, contract_id, original_file, is_active, version, created_at, created_by, template_type)
VALUES ('5F000001-0000-4000-8000-000000000012', '5F000001-0000-4000-8000-000000000011', 'msspk-f.xlsx', 1, 1, '2025-01-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'type_n');
INSERT INTO boqs (id, contract_id, original_file, is_active, version, created_at, created_by, template_type)
VALUES ('5F000001-0000-4000-8000-000000000015', '5F000001-0000-4000-8000-000000000014', 'msspk-s.xlsx', 1, 1, '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'type_n');

-- 3.1 X: MSX.1. > MSX.1.1./MSX.1.2., MSX.2. > MSX.2.1./MSX.2.2., MSX.3. --------------------
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000101', '5F000001-0000-4000-8000-000000000003', 1, 'MSX.1.', 'A. PEKERJAAN PERSIAPAN', NULL, NULL, NULL, NULL, NULL, 'header', 1);
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000102', '5F000001-0000-4000-8000-000000000003', 1, 'MSX.1.1.', 'Mobilisasi peralatan berat', 'Upah', 10,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL), 100000000, NULL, 'item', 2);
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000103', '5F000001-0000-4000-8000-000000000003', 1, 'MSX.1.2.', 'Pembersihan dan perataan lahan', 'Upah', 500,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'm3' AND deleted_at IS NULL), 75000000, NULL, 'item', 3);
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000104', '5F000001-0000-4000-8000-000000000003', 1, 'MSX.2.', 'B. PEKERJAAN MEKANIKAL', NULL, NULL, NULL, NULL, NULL, 'header', 4);
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000105', '5F000001-0000-4000-8000-000000000003', 1, 'MSX.2.1.', 'Pemasangan pompa transfer 50 HP', 'Material', 4,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL), 240000000, NULL, 'item', 5);
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000106', '5F000001-0000-4000-8000-000000000003', 1, 'MSX.2.2.', 'Pemipaan 6 inch sch 40', 'Material', 300,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'm' AND deleted_at IS NULL), 180000000, NULL, 'item', 6);
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000107', '5F000001-0000-4000-8000-000000000003', 1, 'MSX.3.', 'Dokumentasi dan as-built drawing', 'Transport', 1,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Set' AND deleted_at IS NULL), 25000000, NULL, 'item', 7);

-- 3.2 Y: MSY.1. > MSY.1.1./MSY.1.2./MSY.1.3. ---------------------------------------------
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000111', '5F000001-0000-4000-8000-000000000006', 1, 'MSY.1.', 'A. PEKERJAAN ELEKTRIKAL', NULL, NULL, NULL, NULL, NULL, 'header', 1);
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000112', '5F000001-0000-4000-8000-000000000006', 1, 'MSY.1.1.', 'Panel distribusi 400 A', 'Material', 2,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL), 160000000, NULL, 'item', 2);
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000113', '5F000001-0000-4000-8000-000000000006', 1, 'MSY.1.2.', 'Kabel NYY 4x50 mm2', 'Material', 1200,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'm' AND deleted_at IS NULL), 96000000, NULL, 'item', 3);
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000114', '5F000001-0000-4000-8000-000000000006', 1, 'MSY.1.3.', 'Instalasi dan commissioning', 'Upah', 1,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Lot' AND deleted_at IS NULL), 60000000, NULL, 'item', 4);

-- 3.3 Z (ended) ----------------------------------------------------------------------------
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000121', '5F000001-0000-4000-8000-000000000009', 1, 'MSZ.1.', 'A. PEKERJAAN SIPIL (KONTRAK BERAKHIR)', NULL, NULL, NULL, NULL, NULL, 'header', 1);
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000122', '5F000001-0000-4000-8000-000000000009', 1, 'MSZ.1.1.', 'Pondasi beton K-300', 'Material', 50,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'm3' AND deleted_at IS NULL), 125000000, NULL, 'item', 2);

-- 3.4 D (draft) ----------------------------------------------------------------------------
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000131', '5F000001-0000-4000-8000-00000000000C', 1, 'MSD.1.', 'A. PEKERJAAN KONTRAK DRAFT', NULL, NULL, NULL, NULL, NULL, 'header', 1);
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000132', '5F000001-0000-4000-8000-00000000000C', 1, 'MSD.1.1.', 'Pengadaan valve gate 8 inch', 'Material', 5,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL), 50000000, NULL, 'item', 2);

-- 3.5 H (on hold) --------------------------------------------------------------------------
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000141', '5F000001-0000-4000-8000-00000000000F', 1, 'MSH.1.', 'A. PEKERJAAN KONTRAK ON HOLD', NULL, NULL, NULL, NULL, NULL, 'header', 1);
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000142', '5F000001-0000-4000-8000-00000000000F', 1, 'MSH.1.1.', 'Pengecatan tangki T-101', 'Upah', 800,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'm' AND deleted_at IS NULL), 40000000, NULL, 'item', 2);

-- 3.6 F (finished) -------------------------------------------------------------------------
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000151', '5F000001-0000-4000-8000-000000000012', 1, 'MSF.1.', 'A. PEKERJAAN KONTRAK SELESAI', NULL, NULL, NULL, NULL, NULL, 'header', 1);
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000152', '5F000001-0000-4000-8000-000000000012', 1, 'MSF.1.1.', 'Perbaikan jalan akses', 'Upah', 2,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Lot' AND deleted_at IS NULL), 30000000, NULL, 'item', 2);

-- 3.7 S (small contract value) -----------------------------------------------------------
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000161', '5F000001-0000-4000-8000-000000000015', 1, 'MSS.1.', 'A. PEKERJAAN MELEBIHI NILAI KONTRAK', NULL, NULL, NULL, NULL, NULL, 'header', 1);
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000001-0000-4000-8000-000000000162', '5F000001-0000-4000-8000-000000000015', 1, 'MSS.1.1.', 'Sewa genset 500 kVA', 'Sewa Alat', 4,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL), 80000000, NULL, 'item', 2);


-- =====================================================================================
-- SECTION 4 — PROJECT AND ONE TASK PER CASE (no SPK BoQ, draft or SPK yet)
-- =====================================================================================

INSERT INTO projects (id, project_no, wbs, description, category, start_date, end_date,
                      budget_forecast, status, department_id, created_at, created_by)
VALUES ('5F000001-0000-4000-8000-000000000004', 'MSSPK-2026', 'MSSPK',
        'Multi Source SPK Fixture Project', 'Project', '2026-09-01', '2027-03-31',
        5000000000, 'in progress', 'Project', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0');

INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000201', '5F000001-0000-4000-8000-000000000004', '1', 'MULTI SOURCE SPK FIXTURE', 100, '2026-09-01', '2027-03-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'header', 'in progress', 960001, NULL, 0, 212, 0, 4010000000);

-- 001 same contract, select manual — budget 500,000,000
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000301', '5F000001-0000-4000-8000-000000000004', '1.1', 'T001 same contract via select manual', 7, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960002, 960001, 0, 108, 0, 500000000);
-- 002 different contract, bulk upload — budget 500,000,000
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000302', '5F000001-0000-4000-8000-000000000004', '1.2', 'T002 different contract via bulk upload', 7, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960003, 960001, 0, 108, 0, 500000000);
-- 003 reset then recreate — budget 500,000,000
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000303', '5F000001-0000-4000-8000-000000000004', '1.3', 'T003 reset contract BoQ then recreate', 7, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960004, 960001, 0, 108, 0, 500000000);
-- 004 submit, insufficient estimated cost — budget 5,000,000 (cheapest X line is 25,000,000)
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000304', '5F000001-0000-4000-8000-000000000004', '1.4', 'T004 submit with insufficient estimated cost', 7, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960005, 960001, 0, 108, 0, 5000000);
-- 005 save draft, insufficient estimated cost — budget 5,000,000
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000305', '5F000001-0000-4000-8000-000000000004', '1.5', 'T005 save draft with insufficient estimated cost', 7, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960006, 960001, 0, 108, 0, 5000000);
-- 006 inactive contract (Z) — budget 500,000,000
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000306', '5F000001-0000-4000-8000-000000000004', '1.6', 'T006 select approve-inactive contract', 7, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960007, 960001, 0, 108, 0, 500000000);
-- 007 draft contract (D)
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000307', '5F000001-0000-4000-8000-000000000004', '1.7', 'T007 select draft contract', 7, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960008, 960001, 0, 108, 0, 500000000);
-- 008 on hold contract (H)
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000308', '5F000001-0000-4000-8000-000000000004', '1.8', 'T008 select on-hold contract', 7, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960009, 960001, 0, 108, 0, 500000000);
-- 009 finished contract (F)
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000309', '5F000001-0000-4000-8000-000000000004', '1.9', 'T009 select finished contract', 7, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960010, 960001, 0, 108, 0, 500000000);
-- 010 save to draft
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000310', '5F000001-0000-4000-8000-000000000004', '1.10', 'T010 save to draft', 7, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960011, 960001, 0, 108, 0, 500000000);
-- 011 create from saved draft
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000311', '5F000001-0000-4000-8000-000000000004', '1.11', 'T011 create from saved draft', 7, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960012, 960001, 0, 108, 0, 500000000);
-- 012 create SPK, same contract (X lines submitted; SPK created by hand)
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000312', '5F000001-0000-4000-8000-000000000004', '1.12', 'T012 create SPK from SPK BoQ same contract', 7, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960013, 960001, 0, 108, 0, 500000000);
-- 013 create SPK, different contract (X + Y lines submitted; SPK created by hand)
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000313', '5F000001-0000-4000-8000-000000000004', '1.13', 'T013 create SPK from SPK BoQ different contract', 7, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960014, 960001, 0, 108, 0, 500000000);
-- 014 create SPK, insufficient contract value (S line 80,000,000 > contract 50,000,000)
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000314', '5F000001-0000-4000-8000-000000000004', '1.14', 'T014 create SPK with insufficient contract value', 7, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960015, 960001, 0, 108, 0, 500000000);
-- 015–019 progress input on a task with several SPKs (X + Y lines; SPKs and progress by hand)
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date, created_at, created_by, data_type, status, unique_id, parent_unique_id, milestone, duration, is_critical_path, estimated_cost)
VALUES ('5F000001-0000-4000-8000-000000000315', '5F000001-0000-4000-8000-000000000004', '1.15', 'T015 progress input with several SPKs (015-019)', 9, '2026-09-15', '2026-12-31', '2026-09-01T08:00:00', '8ad89747-d543-4a0a-a2ff-57e9960535e0', 'item', 'in progress', 960016, 960001, 0, 108, 0, 500000000);


-- =====================================================================================
-- SECTION 5 — VERIFICATION. Read-only. Every row must say PASS.
-- =====================================================================================

SELECT 'V1 seven contracts, seven active BOQs, 23 BOQ lines' AS check_name,
       CASE WHEN (SELECT COUNT(*) FROM contracts WHERE contractor_id = '5F000001-0000-4000-8000-000000000001' AND deleted_at IS NULL) = 7
             AND (SELECT COUNT(*) FROM boqs WHERE contract_id IN (SELECT contract_id FROM contracts WHERE contractor_id = '5F000001-0000-4000-8000-000000000001') AND is_active = 1) = 7
             AND (SELECT COUNT(*) FROM boq_details WHERE boq_id IN (SELECT id FROM boqs WHERE contract_id IN (SELECT contract_id FROM contracts WHERE contractor_id = '5F000001-0000-4000-8000-000000000001'))) = 23
            THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'V2 every item line resolved its unit by name' AS check_name,
       CASE WHEN (SELECT COUNT(*) FROM boq_details
                  WHERE boq_id IN (SELECT id FROM boqs WHERE contract_id IN (SELECT contract_id FROM contracts WHERE contractor_id = '5F000001-0000-4000-8000-000000000001'))
                    AND data_type = 'item' AND unit_id IS NULL) = 0
            THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'V3 project in progress, 16 tasks, no SPK BoQ / draft / SPK yet' AS check_name,
       CASE WHEN (SELECT status FROM projects WHERE id = '5F000001-0000-4000-8000-000000000004') = 'in progress'
             AND (SELECT COUNT(*) FROM project_tasks WHERE project_id = '5F000001-0000-4000-8000-000000000004') = 16
             AND (SELECT COUNT(*) FROM project_task_boqs WHERE project_task_id IN (SELECT id FROM project_tasks WHERE project_id = '5F000001-0000-4000-8000-000000000004')) = 0
             AND (SELECT COUNT(*) FROM project_task_boq_drafts WHERE project_task_id IN (SELECT id FROM project_tasks WHERE project_id = '5F000001-0000-4000-8000-000000000004')) = 0
             AND (SELECT COUNT(*) FROM spks WHERE contract_id IN (SELECT contract_id FROM contracts WHERE contractor_id = '5F000001-0000-4000-8000-000000000001')) = 0
            THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'V4 contract statuses: Z ended, D draft, H on hold, F finished, S small' AS check_name,
       CASE WHEN (SELECT COUNT(*) FROM contracts WHERE contract_id = '5F000001-0000-4000-8000-000000000008' AND CAST(status AS nvarchar(30)) = 'approved' AND contract_end_date < CAST(GETDATE() AS date)) = 1
             AND (SELECT CAST(status AS nvarchar(30)) FROM contracts WHERE contract_id = '5F000001-0000-4000-8000-00000000000B') = 'draft'
             AND (SELECT CAST(status AS nvarchar(30)) FROM contracts WHERE contract_id = '5F000001-0000-4000-8000-00000000000E') = 'on hold'
             AND (SELECT CAST(status AS nvarchar(30)) FROM contracts WHERE contract_id = '5F000001-0000-4000-8000-000000000011') = 'finished'
             AND (SELECT contract_value FROM contracts WHERE contract_id = '5F000001-0000-4000-8000-000000000014') = 50000000
            THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'V5 rows are visible to the Project department' AS check_name,
       CASE WHEN (SELECT department_id FROM projects WHERE id = '5F000001-0000-4000-8000-000000000004') = 'Project'
             AND (SELECT COUNT(*) FROM contracts WHERE contractor_id = '5F000001-0000-4000-8000-000000000001' AND department_id = 'Project') = 7
            THEN 'PASS' ELSE 'FAIL' END AS result;
