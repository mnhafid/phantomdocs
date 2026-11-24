-- =====================================================================================
-- SPK BoQ Shorten Flow — demo fixture
--
--   Doc set : docs/ShortenFlow/PRD.md, docs/ShortenFlow/FSD.md
--   Target  : SQL Server (phantomdb)
--   Version : 1.0  ·  2026-09-03
--
-- WHAT THIS IS
--   A self-contained scenario for the SPK BoQ shorten-flow wizard. It creates its own
--   contractor, two contracts, two BOQs, one project and five project tasks, so the
--   wizard's four interesting states can be exercised without depending on any
--   pre-existing row:
--
--     S-A  happy path   — one task, one SPK, two submitted BoQ lines, progress recorded
--     S-B  multi-SPK    — one task holding two ACTIVE spk assignments (spk_type='multi'),
--                         and one BoQ line linked to BOTH SPKs, which is exactly the case
--                         v1 hides and v2's per-line `spks[]` exposes
--     S-C  over-budget  — a contract whose spk_value exceeds its contract_value, so the
--                         draft reports a NEGATIVE spk_remaining. Nothing blocks submit;
--                         see FSD §7 GAP-1
--     S-D  saved draft  — a task with no submitted lines and one saved draft, so the
--                         wizard resumes and the picker shows is_selected=true from the
--                         draft alone
--
-- RE-RUNS
--   Every row this script owns has a literal GUID in the reserved 5F000000-…-0000000000XX
--   range. Section 1 deletes exactly those, in FK order, then section 2 inserts. Running
--   the script twice lands on the same state. Section 1 on its own is the teardown.
--
-- PORTABILITY
--   * No DECLARE, no GO, no batch separators — every statement stands alone, so a JDBC
--     client that splits the file on ';' (DBeaver) executes it correctly.
--   * `units` is a shared master table, so unit references are inline subqueries by NAME
--     rather than hardcoded ids. If a name is missing in your environment the INSERT fails
--     loudly on a NULL in a NOT NULL column, which is the intended outcome.
--   * FIXTURE_USER below is the only environment-specific literal. It is R3TEST.tiar on the
--     shared dev box. Find-and-replace it for another environment:
--        SELECT id FROM users WHERE retina_id = 'R3TEST.TIAR' AND deleted_at IS NULL;
--     FIXTURE_USER = 314ee091-4525-4098-9c45-0b39edf8fad0
--
-- MONEY (all IDR)
--   contract A  5F000000-…-000000000002  value 1,000,000,000  spk_value 370,000,000
--                                        -> spk_remaining      630,000,000
--   contract B  5F000000-…-000000000005  value   100,000,000  spk_value 130,000,000
--                                        -> spk_remaining      -30,000,000   (S-C)
-- =====================================================================================


-- =====================================================================================
-- SECTION 1 — TEARDOWN.  Children first; this block alone is the undo.
-- =====================================================================================

DELETE FROM project_task_boq_drafts
WHERE id IN ('5F000000-0000-4000-8000-000000000801','5F000000-0000-4000-8000-000000000802');

DELETE FROM spk_boqs
WHERE id IN ('5F000000-0000-4000-8000-000000000701','5F000000-0000-4000-8000-000000000702',
             '5F000000-0000-4000-8000-000000000703','5F000000-0000-4000-8000-000000000704',
             '5F000000-0000-4000-8000-000000000705');

DELETE FROM project_task_boq_details
WHERE id IN ('5F000000-0000-4000-8000-000000000601','5F000000-0000-4000-8000-000000000602',
             '5F000000-0000-4000-8000-000000000603','5F000000-0000-4000-8000-000000000604',
             '5F000000-0000-4000-8000-000000000605','5F000000-0000-4000-8000-000000000606');

DELETE FROM project_task_boqs
WHERE id IN ('5F000000-0000-4000-8000-000000000501','5F000000-0000-4000-8000-000000000502',
             '5F000000-0000-4000-8000-000000000503','5F000000-0000-4000-8000-000000000504',
             '5F000000-0000-4000-8000-000000000505','5F000000-0000-4000-8000-000000000506');

DELETE FROM project_task_spks
WHERE id IN ('5F000000-0000-4000-8000-000000000401','5F000000-0000-4000-8000-000000000402',
             '5F000000-0000-4000-8000-000000000403');

DELETE FROM spks
WHERE spk_id IN ('5F000000-0000-4000-8000-000000000301','5F000000-0000-4000-8000-000000000302',
                 '5F000000-0000-4000-8000-000000000303');

DELETE FROM project_tasks
WHERE id IN ('5F000000-0000-4000-8000-000000000201','5F000000-0000-4000-8000-000000000210',
             '5F000000-0000-4000-8000-000000000211','5F000000-0000-4000-8000-000000000212',
             '5F000000-0000-4000-8000-000000000213');

DELETE FROM boq_details
WHERE boq_id IN ('5F000000-0000-4000-8000-000000000003','5F000000-0000-4000-8000-000000000006');

DELETE FROM boqs
WHERE id IN ('5F000000-0000-4000-8000-000000000003','5F000000-0000-4000-8000-000000000006');

DELETE FROM projects
WHERE id = '5F000000-0000-4000-8000-000000000004';

DELETE FROM contracts
WHERE contract_id IN ('5F000000-0000-4000-8000-000000000002','5F000000-0000-4000-8000-000000000005');

DELETE FROM contractors
WHERE id = '5F000000-0000-4000-8000-000000000001';


-- =====================================================================================
-- SECTION 2 — MASTER DATA
-- =====================================================================================

-- 2.1 Contractor -----------------------------------------------------------------------
INSERT INTO contractors (id, code, name, address, telephone, email, is_active, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000001', 'SF-FIXTURE',
        'PT Shorten Flow Fixture', 'Jl. Fixture No. 1, Jakarta', '021-0000000',
        'fixture@example.invalid', 1, '2026-08-01T08:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 2.2 Contract A — healthy. Backs S-A, S-B and S-D. ------------------------------------
--     spk_value 370,000,000 = 240,000,000 (SPK A) + 50,000,000 (SPK B1) + 80,000,000 (SPK B2).
INSERT INTO contracts (contract_id, contractor_id, contract_no, contract_title,
                       start_date, work_end_date, contract_end_date,
                       contract_value, spk_count, spk_value, physical_progress_value,
                       sa_value, invoice_value, status, autogenerated_spk_number,
                       retention_percentage, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000002', '5F000000-0000-4000-8000-000000000001',
        'SF/FIXTURE/A/2026', 'Shorten Flow Fixture — Kontrak Utama',
        '2026-08-01', '2026-12-31', '2027-01-31',
        1000000000, 3, 370000000, 0,
        0, 0, 'approved', 1,
        10.00, '2026-08-01T08:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 2.3 Contract B — DEPLETED. Backs S-C. ------------------------------------------------
--     spk_value is deliberately ABOVE contract_value so the draft response reports
--     spk_remaining = -30,000,000. No SPK rows back this number on purpose: nothing in the
--     shorten-flow read path recomputes contracts.spk_value, it is read as stored
--     (ProjectTaskBoqsService.FillCommonDraftFields). See FSD §7 GAP-1.
INSERT INTO contracts (contract_id, contractor_id, contract_no, contract_title,
                       start_date, work_end_date, contract_end_date,
                       contract_value, spk_count, spk_value, physical_progress_value,
                       sa_value, invoice_value, status, autogenerated_spk_number,
                       retention_percentage, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000005', '5F000000-0000-4000-8000-000000000001',
        'SF/FIXTURE/B/2026', 'Shorten Flow Fixture — Kontrak Habis Pagu',
        '2026-08-01', '2026-12-31', '2027-01-31',
        100000000, 0, 130000000, 0,
        0, 0, 'approved', 0,
        5.00, '2026-08-01T08:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');


-- =====================================================================================
-- SECTION 3 — BOQs
-- Resolution rule (BoqsService.BuildBoqDetailQuery): among a contract's boqs rows with
-- is_active = 1 and deleted_at IS NULL, the highest version wins. One active BOQ each.
-- =====================================================================================

INSERT INTO boqs (id, contract_id, original_file, is_active, version, created_at, created_by, template_type)
VALUES ('5F000000-0000-4000-8000-000000000003', '5F000000-0000-4000-8000-000000000002',
        'shortenflow-fixture-a.xlsx', 1, 1, '2026-08-01T08:00:00',
        '314ee091-4525-4098-9c45-0b39edf8fad0', 'type_n');

INSERT INTO boqs (id, contract_id, original_file, is_active, version, created_at, created_by, template_type)
VALUES ('5F000000-0000-4000-8000-000000000006', '5F000000-0000-4000-8000-000000000005',
        'shortenflow-fixture-b.xlsx', 1, 1, '2026-08-01T08:00:00',
        '314ee091-4525-4098-9c45-0b39edf8fad0', 'type_n');

-- 3.1 BOQ A rows — HIERARCHICAL on purpose. -------------------------------------------
-- parent_id (BoqsService.ApplyParentIdsAsync) strips the last '.' segment and matches a
-- header row with that breakdown, so this tree resolves as:
--     SF.1.   header  -> parent_id ""            (StripLastSegment('SF.1.') = 'SF.' — no row)
--     SF.1.1. item    -> parent_id <SF.1. id>
--     SF.1.2. item    -> parent_id <SF.1. id>
--     SF.2.   header  -> parent_id ""
--     SF.2.1. item    -> parent_id <SF.2. id>
--     SF.2.2. item    -> parent_id <SF.2. id>
--     SF.3.   item    -> parent_id ""            (a top-level item with no header above it)
-- unit_price in the API response is computed as total / quantity, so both must be set on
-- item rows or the row reports an empty unit_price.
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000000-0000-4000-8000-000000000101', '5F000000-0000-4000-8000-000000000003', 1,
        'SF.1.', 'A. PEKERJAAN PERSIAPAN DAN MOBILISASI', NULL, NULL, NULL, NULL, NULL, 'header', 1);

INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000000-0000-4000-8000-000000000102', '5F000000-0000-4000-8000-000000000003', 1,
        'SF.1.1.', 'Mobilisasi peralatan ke lokasi', 'Upah', 10,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Pcs' AND deleted_at IS NULL),
        50000000, NULL, 'item', 2);

INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000000-0000-4000-8000-000000000103', '5F000000-0000-4000-8000-000000000003', 1,
        'SF.1.2.', 'Mobilisasi material ke lokasi', 'Material', 20,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Pcs' AND deleted_at IS NULL),
        80000000, NULL, 'item', 3);

INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000000-0000-4000-8000-000000000104', '5F000000-0000-4000-8000-000000000003', 1,
        'SF.2.', 'B. PEKERJAAN INSTALASI', NULL, NULL, NULL, NULL, NULL, 'header', 4);

INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000000-0000-4000-8000-000000000105', '5F000000-0000-4000-8000-000000000003', 1,
        'SF.2.1.', 'Instalasi panel distribusi', 'Upah', 5,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL),
        150000000, NULL, 'item', 5);

INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000000-0000-4000-8000-000000000106', '5F000000-0000-4000-8000-000000000003', 1,
        'SF.2.2.', 'Sewa crane 25 ton', 'Sewa Alat', 3,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL),
        90000000, NULL, 'item', 6);

INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000000-0000-4000-8000-000000000107', '5F000000-0000-4000-8000-000000000003', 1,
        'SF.3.', 'Dokumentasi as-built', 'Transport', 1,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Doc' AND deleted_at IS NULL),
        30000000, NULL, 'item', 7);

-- 3.2 BOQ B rows — the over-budget contract's lines. -----------------------------------
INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000000-0000-4000-8000-000000000111', '5F000000-0000-4000-8000-000000000006', 1,
        'SFB.1.', 'A. PEKERJAAN TAMBAH KURANG', NULL, NULL, NULL, NULL, NULL, 'header', 1);

INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000000-0000-4000-8000-000000000112', '5F000000-0000-4000-8000-000000000006', 1,
        'SFB.1.1.', 'Pekerjaan tambah - perkuatan struktur', 'Upah', 4,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL),
        60000000, NULL, 'item', 2);

INSERT INTO boq_details (id, boq_id, origin_number, code, description, kind, quantity, unit_id, total, remark, data_type, [order])
VALUES ('5F000000-0000-4000-8000-000000000113', '5F000000-0000-4000-8000-000000000006', 1,
        'SFB.1.2.', 'Pekerjaan tambah - material tambahan', 'Material', 2,
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Lot' AND deleted_at IS NULL),
        70000000, NULL, 'item', 3);


-- =====================================================================================
-- SECTION 4 — PROJECT AND TASKS
-- The project status MUST be 'in progress': SetProjectTaskBoqAsync rejects a submit
-- against any other status with "You cannot set the SPK BoQ because the Project Details'
-- status is not yet In Progress".
-- =====================================================================================

INSERT INTO projects (id, project_no, wbs, description, category, start_date, end_date,
                      budget_forecast, status, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000004', 'SF-FIXTURE-2026', 'SF',
        'Shorten Flow Fixture Project', 'Project', '2026-08-01', '2026-12-31',
        1000000000, 'in progress', '2026-08-01T08:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 4.1 Root header task ------------------------------------------------------------------
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date,
                           created_at, created_by, data_type, status, unique_id, parent_unique_id,
                           milestone, duration, is_critical_path)
VALUES ('5F000000-0000-4000-8000-000000000201', '5F000000-0000-4000-8000-000000000004',
        '1', 'SHORTEN FLOW FIXTURE', 100, '2026-08-01', '2026-12-31',
        '2026-08-01T08:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0', 'header', 'in progress', 1, NULL,
        0, 153, 0);

-- 4.2 S-A — happy path. One SPK, spk_type 'single'. -------------------------------------
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date,
                           created_at, created_by, data_type, status, unique_id, parent_unique_id,
                           milestone, duration, is_critical_path,
                           contract_id, spk_id, spk_cost, spk_type, estimated_cost)
VALUES ('5F000000-0000-4000-8000-000000000210', '5F000000-0000-4000-8000-000000000004',
        '1.1', 'S-A Instalasi panel dan sewa crane', 30, '2026-09-01', '2026-09-30',
        '2026-08-01T08:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0', 'item', 'in progress', 2, 1,
        0, 30, 1,
        '5F000000-0000-4000-8000-000000000002', '5F000000-0000-4000-8000-000000000301',
        240000000, 'single', 240000000);

-- 4.3 S-B — multi-SPK. spk_id shows only the PRIMARY assignment, so it understates. ------
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date,
                           created_at, created_by, data_type, status, unique_id, parent_unique_id,
                           milestone, duration, is_critical_path,
                           contract_id, spk_id, spk_cost, spk_type, estimated_cost)
VALUES ('5F000000-0000-4000-8000-000000000211', '5F000000-0000-4000-8000-000000000004',
        '1.2', 'S-B Mobilisasi peralatan dan material', 30, '2026-09-01', '2026-09-20',
        '2026-08-01T08:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0', 'item', 'in progress', 3, 1,
        0, 20, 0,
        '5F000000-0000-4000-8000-000000000002', '5F000000-0000-4000-8000-000000000302',
        50000000, 'multi', 130000000);

-- 4.4 S-C — over-budget. On contract B, no SPK linked yet. ------------------------------
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date,
                           created_at, created_by, data_type, status, unique_id, parent_unique_id,
                           milestone, duration, is_critical_path,
                           contract_id, spk_id, spk_cost, spk_type, estimated_cost)
VALUES ('5F000000-0000-4000-8000-000000000212', '5F000000-0000-4000-8000-000000000004',
        '1.3', 'S-C Pekerjaan tambah melebihi pagu', 25, '2026-10-01', '2026-10-31',
        '2026-08-01T08:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0', 'item', 'not started', 4, 1,
        0, 31, 0,
        '5F000000-0000-4000-8000-000000000005', NULL, NULL, NULL, 130000000);

-- 4.5 S-D — draft only. No submitted lines. --------------------------------------------
INSERT INTO project_tasks (id, project_id, breakdown, description, weight, start_date, end_date,
                           created_at, created_by, data_type, status, unique_id, parent_unique_id,
                           milestone, duration, is_critical_path,
                           contract_id, spk_id, spk_cost, spk_type, estimated_cost)
VALUES ('5F000000-0000-4000-8000-000000000213', '5F000000-0000-4000-8000-000000000004',
        '1.4', 'S-D Dokumentasi as-built (draft belum submit)', 15, '2026-11-01', '2026-11-15',
        '2026-08-01T08:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0', 'item', 'not started', 5, 1,
        0, 15, 0,
        '5F000000-0000-4000-8000-000000000002', NULL, NULL, NULL, 0);


-- =====================================================================================
-- SECTION 5 — SPKs
-- =====================================================================================

-- 5.1 SPK A — S-A's single SPK.
INSERT INTO spks (spk_id, contract_id, spk_no, spk_title, start_date, end_date,
                  spk_value, final_spk_value, physical_progress_value, remark, status,
                  version, pekerjaan, is_various, sum_released_spk_value, remaining_contract_value,
                  created_at, created_by, released_at, released_by)
VALUES ('5F000000-0000-4000-8000-000000000301', '5F000000-0000-4000-8000-000000000002',
        '001/SPK/SF-FIXTURE/2026', 'SPK Instalasi Panel Distribusi', '2026-09-01', '2026-09-30',
        240000000, 240000000, 60000000, 'Fixture S-A', 'released',
        1, 'Instalasi panel distribusi dan sewa crane 25 ton', 0, 240000000, 760000000,
        '2026-08-15T09:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0',
        '2026-08-20T09:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 5.2 SPK B1 — S-B's PRIMARY assignment. This is the one project_tasks.spk_id mirrors.
INSERT INTO spks (spk_id, contract_id, spk_no, spk_title, start_date, end_date,
                  spk_value, final_spk_value, physical_progress_value, remark, status,
                  version, pekerjaan, is_various, sum_released_spk_value, remaining_contract_value,
                  created_at, created_by, released_at, released_by)
VALUES ('5F000000-0000-4000-8000-000000000302', '5F000000-0000-4000-8000-000000000002',
        '002/SPK/SF-FIXTURE/2026', 'SPK Mobilisasi Peralatan', '2026-09-01', '2026-09-10',
        50000000, 50000000, 0, 'Fixture S-B primary', 'released',
        1, 'Mobilisasi peralatan ke lokasi', 0, 290000000, 710000000,
        '2026-08-16T09:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0',
        '2026-08-21T09:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 5.3 SPK B2 — S-B's SECOND active assignment. Invisible to v1.
INSERT INTO spks (spk_id, contract_id, spk_no, spk_title, start_date, end_date,
                  spk_value, final_spk_value, physical_progress_value, remark, status,
                  version, pekerjaan, is_various, sum_released_spk_value, remaining_contract_value,
                  created_at, created_by, released_at, released_by)
VALUES ('5F000000-0000-4000-8000-000000000303', '5F000000-0000-4000-8000-000000000002',
        '003/SPK/SF-FIXTURE/2026', 'SPK Mobilisasi Material', '2026-09-05', '2026-09-20',
        80000000, 80000000, 0, 'Fixture S-B secondary', 'released',
        1, 'Mobilisasi material ke lokasi', 0, 370000000, 630000000,
        '2026-08-17T09:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0',
        '2026-08-22T09:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');


-- =====================================================================================
-- SECTION 6 — SPK ASSIGNMENTS (project_task_spks)
-- Authoritative at task grain. Two unique indexes constrain what can be inserted here:
--   UX_project_task_spks_active   (project_task_id, spk_id)  — no duplicate assignment
--   UX_project_task_spks_primary  (project_task_id)          — at most ONE primary per task
-- unassigned_at IS NULL means the assignment is live. Rows are never deleted.
-- =====================================================================================

-- 6.1 S-A: one live assignment, primary. project_tasks.spk_type = 'single'.
INSERT INTO project_task_spks (id, project_task_id, spk_id, spk_cost, is_primary, source, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000401', '5F000000-0000-4000-8000-000000000210',
        '5F000000-0000-4000-8000-000000000301', 240000000, 1, 'app',
        '2026-08-20T09:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 6.2 S-B primary.
INSERT INTO project_task_spks (id, project_task_id, spk_id, spk_cost, is_primary, source, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000402', '5F000000-0000-4000-8000-000000000211',
        '5F000000-0000-4000-8000-000000000302', 50000000, 1, 'app',
        '2026-08-21T09:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 6.3 S-B second live assignment. is_primary = 0, so the primary index still holds, and
--     project_tasks.spk_type = 'multi' is the only field that reports its existence.
INSERT INTO project_task_spks (id, project_task_id, spk_id, spk_cost, is_primary, source, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000403', '5F000000-0000-4000-8000-000000000211',
        '5F000000-0000-4000-8000-000000000303', 80000000, 0, 'app',
        '2026-08-22T09:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');


-- =====================================================================================
-- SECTION 7 — SUBMITTED BoQ LINES (project_task_boqs + project_task_boq_details)
-- These are the rows POST /projects/tasks/boqs/submit writes. One row = one draw from one
-- contract BOQ line; the row and its single detail describe the same money.
-- Upsert key on submit is (project_task_id, code, description, kind).
-- =====================================================================================

-- 7.1 S-A line 1 — SF.2.1. Instalasi panel distribusi. 5 x 30,000,000 = 150,000,000.
INSERT INTO project_task_boqs (id, project_task_id, code, description, kind, unit_id, volume,
                               total_price, remarks, start_date, end_date, type, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000501', '5F000000-0000-4000-8000-000000000210',
        'SF.2.1.', 'Instalasi panel distribusi', 'Upah',
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL), 5,
        150000000, 'Fixture S-A', '2026-09-01', '2026-09-20', 'inline',
        '2026-08-20T10:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

INSERT INTO project_task_boq_details (id, project_task_boq_id, boq_detail_id, unit_id, volume,
                                      unit_price, total_price, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000601', '5F000000-0000-4000-8000-000000000501',
        '5F000000-0000-4000-8000-000000000105',
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL), 5,
        30000000, 150000000, '2026-08-20T10:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 7.2 S-A line 2 — SF.2.2. Sewa crane. 3 x 30,000,000 = 90,000,000.
INSERT INTO project_task_boqs (id, project_task_id, code, description, kind, unit_id, volume,
                               total_price, remarks, start_date, end_date, type, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000502', '5F000000-0000-4000-8000-000000000210',
        'SF.2.2.', 'Sewa crane 25 ton', 'Sewa Alat',
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL), 3,
        90000000, 'Fixture S-A', '2026-09-10', '2026-09-30', 'inline',
        '2026-08-20T10:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

INSERT INTO project_task_boq_details (id, project_task_boq_id, boq_detail_id, unit_id, volume,
                                      unit_price, total_price, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000602', '5F000000-0000-4000-8000-000000000502',
        '5F000000-0000-4000-8000-000000000106',
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL), 3,
        30000000, 90000000, '2026-08-20T10:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 7.3 S-B line 1 — SF.1.1. Mobilisasi peralatan. 10 x 5,000,000 = 50,000,000.
--     This is the line that ends up on TWO SPKs (see 8.3 / 8.5).
INSERT INTO project_task_boqs (id, project_task_id, code, description, kind, unit_id, volume,
                               total_price, remarks, start_date, end_date, type, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000503', '5F000000-0000-4000-8000-000000000211',
        'SF.1.1.', 'Mobilisasi peralatan ke lokasi', 'Upah',
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Pcs' AND deleted_at IS NULL), 10,
        50000000, 'Fixture S-B', '2026-09-01', '2026-09-10', 'inline',
        '2026-08-21T10:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

INSERT INTO project_task_boq_details (id, project_task_boq_id, boq_detail_id, unit_id, volume,
                                      unit_price, total_price, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000603', '5F000000-0000-4000-8000-000000000503',
        '5F000000-0000-4000-8000-000000000102',
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Pcs' AND deleted_at IS NULL), 10,
        5000000, 50000000, '2026-08-21T10:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 7.4 S-B line 2 — SF.1.2. Mobilisasi material. 20 x 4,000,000 = 80,000,000.
INSERT INTO project_task_boqs (id, project_task_id, code, description, kind, unit_id, volume,
                               total_price, remarks, start_date, end_date, type, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000504', '5F000000-0000-4000-8000-000000000211',
        'SF.1.2.', 'Mobilisasi material ke lokasi', 'Material',
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Pcs' AND deleted_at IS NULL), 20,
        80000000, 'Fixture S-B', '2026-09-05', '2026-09-20', 'inline',
        '2026-08-22T10:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

INSERT INTO project_task_boq_details (id, project_task_boq_id, boq_detail_id, unit_id, volume,
                                      unit_price, total_price, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000604', '5F000000-0000-4000-8000-000000000504',
        '5F000000-0000-4000-8000-000000000103',
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Pcs' AND deleted_at IS NULL), 20,
        4000000, 80000000, '2026-08-22T10:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 7.5 S-C line 1 — SFB.1.1. 4 x 15,000,000 = 60,000,000.
INSERT INTO project_task_boqs (id, project_task_id, code, description, kind, unit_id, volume,
                               total_price, remarks, start_date, end_date, type, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000505', '5F000000-0000-4000-8000-000000000212',
        'SFB.1.1.', 'Pekerjaan tambah - perkuatan struktur', 'Upah',
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL), 4,
        60000000, 'Fixture S-C', '2026-10-01', '2026-10-15', 'inline',
        '2026-08-25T10:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

INSERT INTO project_task_boq_details (id, project_task_boq_id, boq_detail_id, unit_id, volume,
                                      unit_price, total_price, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000605', '5F000000-0000-4000-8000-000000000505',
        '5F000000-0000-4000-8000-000000000112',
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL), 4,
        15000000, 60000000, '2026-08-25T10:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 7.6 S-C line 2 — SFB.1.2. 2 x 35,000,000 = 70,000,000.
--     60,000,000 + 70,000,000 = 130,000,000 against a 100,000,000 contract. It committed
--     anyway; that is the point of S-C.
INSERT INTO project_task_boqs (id, project_task_id, code, description, kind, unit_id, volume,
                               total_price, remarks, start_date, end_date, type, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000506', '5F000000-0000-4000-8000-000000000212',
        'SFB.1.2.', 'Pekerjaan tambah - material tambahan', 'Material',
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Lot' AND deleted_at IS NULL), 2,
        70000000, 'Fixture S-C', '2026-10-10', '2026-10-31', 'inline',
        '2026-08-25T10:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

INSERT INTO project_task_boq_details (id, project_task_boq_id, boq_detail_id, unit_id, volume,
                                      unit_price, total_price, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000606', '5F000000-0000-4000-8000-000000000506',
        '5F000000-0000-4000-8000-000000000113',
        (SELECT TOP 1 unit_id FROM units WHERE name = 'Lot' AND deleted_at IS NULL), 2,
        35000000, 70000000, '2026-08-25T10:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');


-- =====================================================================================
-- SECTION 8 — SPK <-> BoQ LINKS (spk_boqs)
-- Audit columns on this table are PascalCase (CreatedAt/CreatedBy), unlike every other
-- table in the fixture. That is the real schema, not a typo.
--
-- v1 reports only the link with the LATEST CreatedAt per project_task_boq, in the scalar
-- spk_id / spk_boq_id / progress fields. v2 reports every link in `spks[]`, newest first.
-- Row 8.5 is what makes that difference observable.
-- =====================================================================================

-- 8.1 S-A: SF.2.1. on SPK A. 40% physical progress, 2 of 5 units done.
INSERT INTO spk_boqs (id, spk_id, project_task_boq_id, weighted_project_task, weighted_spk,
                      physical_progress, physical_progress_weighted, actual_volume,
                      actual_progress_cost, CreatedAt, CreatedBy)
VALUES ('5F000000-0000-4000-8000-000000000701', '5F000000-0000-4000-8000-000000000301',
        '5F000000-0000-4000-8000-000000000501', 62.5, 62.5,
        40, 25, 2,
        60000000, '2026-08-20T10:05:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 8.2 S-A: SF.2.2. on SPK A. Not started.
INSERT INTO spk_boqs (id, spk_id, project_task_boq_id, weighted_project_task, weighted_spk,
                      physical_progress, physical_progress_weighted, actual_volume,
                      actual_progress_cost, CreatedAt, CreatedBy)
VALUES ('5F000000-0000-4000-8000-000000000702', '5F000000-0000-4000-8000-000000000301',
        '5F000000-0000-4000-8000-000000000502', 37.5, 37.5,
        0, 0, 0,
        0, '2026-08-20T10:05:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 8.3 S-B: SF.1.1. on SPK B1 (the primary).
INSERT INTO spk_boqs (id, spk_id, project_task_boq_id, weighted_project_task, weighted_spk,
                      physical_progress, physical_progress_weighted, actual_volume,
                      actual_progress_cost, CreatedAt, CreatedBy)
VALUES ('5F000000-0000-4000-8000-000000000703', '5F000000-0000-4000-8000-000000000302',
        '5F000000-0000-4000-8000-000000000503', 38.46, 100,
        20, 7.69, 2,
        10000000, '2026-08-21T10:05:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 8.4 S-B: SF.1.2. on SPK B2.
INSERT INTO spk_boqs (id, spk_id, project_task_boq_id, weighted_project_task, weighted_spk,
                      physical_progress, physical_progress_weighted, actual_volume,
                      actual_progress_cost, CreatedAt, CreatedBy)
VALUES ('5F000000-0000-4000-8000-000000000704', '5F000000-0000-4000-8000-000000000303',
        '5F000000-0000-4000-8000-000000000504', 61.54, 100,
        0, 0, 0,
        0, '2026-08-22T10:05:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 8.5 THE CROSS-LINK. SF.1.1. is ALSO on SPK B2, created after 8.3, so it is the newest
--     link on that project_task_boq. v1 therefore reports spk_id = SPK B2 for this line and
--     never mentions SPK B1 at all; v2's `spks[]` lists both, B2 first.
INSERT INTO spk_boqs (id, spk_id, project_task_boq_id, weighted_project_task, weighted_spk,
                      physical_progress, physical_progress_weighted, actual_volume,
                      actual_progress_cost, CreatedAt, CreatedBy)
VALUES ('5F000000-0000-4000-8000-000000000705', '5F000000-0000-4000-8000-000000000303',
        '5F000000-0000-4000-8000-000000000503', 38.46, 0,
        50, 19.23, 5,
        25000000, '2026-08-23T10:05:00', '314ee091-4525-4098-9c45-0b39edf8fad0');


-- =====================================================================================
-- SECTION 9 — SAVED DRAFTS (project_task_boq_drafts)
-- One row per project_task_id (UX_project_task_boq_drafts_project_task_id). The row's
-- EXISTENCE is the draft state; there is no status column.
--
-- payload is the SetProjectTaskBoqRequest JSON verbatim, deliberately unnormalized so a
-- half-filled form can be stored. Both payloads below are already in the canonical FLAT
-- shape (boq_detail_id / unit_id / unit_price on the row, no nested boq_details[], and
-- type 'inline' not 'item'), which is what NormalizeDraftPayload would produce anyway —
-- so they are stored byte-for-byte and would survive a submit unchanged.
--
-- Dates inside the payload are dd-MM-yyyy: submit parses them with ParseExact against that
-- exact format, so any other layout is a 400.
-- =====================================================================================

-- 9.1 S-D — the resume case. No submitted lines exist for this task, so the only reason
--     GET /contracts/boqs/details?project_task_id=…0213 stamps is_selected=true on SF.1.1.
--     is this draft (BoqsService.BuildTaskSelectionAsync reads submitted rows AND the draft;
--     the draft wins on conflict).
INSERT INTO project_task_boq_drafts (id, project_task_id, contract_id, payload, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000801', '5F000000-0000-4000-8000-000000000213',
        '5F000000-0000-4000-8000-000000000002',
        '{"project_task_id":"5f000000-0000-4000-8000-000000000213","contract_id":"5f000000-0000-4000-8000-000000000002","spk_boqs":[{"code":"SF.3.","description":"Dokumentasi as-built","kind":"Transport","unit_id":"UNIT_DOC_ID","volume":1,"unit_price":30000000,"total_price":30000000,"start_date":"01-11-2026","end_date":"15-11-2026","boq_detail_id":"5f000000-0000-4000-8000-000000000107","type":"inline","remarks":"draft - belum submit"}]}',
        '2026-08-28T11:00:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 9.2 S-C — the over-budget draft. GET /projects/tasks/boqs/draft?project_task_id=…0212
--     answers with contract_value "100000000" and spk_remaining "-30000000". Nothing about
--     that negative number stops a submit; see FSD §7 GAP-1.
INSERT INTO project_task_boq_drafts (id, project_task_id, contract_id, payload, created_at, created_by)
VALUES ('5F000000-0000-4000-8000-000000000802', '5F000000-0000-4000-8000-000000000212',
        '5F000000-0000-4000-8000-000000000005',
        '{"project_task_id":"5f000000-0000-4000-8000-000000000212","contract_id":"5f000000-0000-4000-8000-000000000005","spk_boqs":[{"code":"SFB.1.1.","description":"Pekerjaan tambah - perkuatan struktur","kind":"Upah","unit_id":"UNIT_UNIT_ID","volume":4,"unit_price":15000000,"total_price":60000000,"start_date":"01-10-2026","end_date":"15-10-2026","boq_detail_id":"5f000000-0000-4000-8000-000000000112","type":"inline","remarks":"melebihi pagu kontrak"},{"code":"SFB.1.2.","description":"Pekerjaan tambah - material tambahan","kind":"Material","unit_id":"UNIT_LOT_ID","volume":2,"unit_price":35000000,"total_price":70000000,"start_date":"10-10-2026","end_date":"31-10-2026","boq_detail_id":"5f000000-0000-4000-8000-000000000113","type":"inline","remarks":"melebihi pagu kontrak"}]}',
        '2026-08-28T11:05:00', '314ee091-4525-4098-9c45-0b39edf8fad0');

-- 9.3 Patch the unit ids into the two payloads. Done as UPDATEs rather than inline in the
--     INSERT because the ids live inside a JSON string, and a subquery cannot be spliced
--     into a string literal. Each REPLACE is a no-op if the placeholder is already gone,
--     so this is safe to re-run.
UPDATE project_task_boq_drafts
SET payload = REPLACE(payload, 'UNIT_DOC_ID',
        CONVERT(nvarchar(36), (SELECT TOP 1 unit_id FROM units WHERE name = 'Doc' AND deleted_at IS NULL)))
WHERE id = '5F000000-0000-4000-8000-000000000801';

UPDATE project_task_boq_drafts
SET payload = REPLACE(
        REPLACE(payload, 'UNIT_UNIT_ID',
            CONVERT(nvarchar(36), (SELECT TOP 1 unit_id FROM units WHERE name = 'Unit' AND deleted_at IS NULL))),
        'UNIT_LOT_ID',
        CONVERT(nvarchar(36), (SELECT TOP 1 unit_id FROM units WHERE name = 'Lot' AND deleted_at IS NULL)))
WHERE id = '5F000000-0000-4000-8000-000000000802';


-- =====================================================================================
-- SECTION 10 — VERIFICATION.  Read-only. Run after loading; every row must say PASS.
-- =====================================================================================

SELECT 'V1 task/boq/spk counts' AS check_name,
       CASE WHEN (SELECT COUNT(*) FROM project_tasks WHERE project_id = '5F000000-0000-4000-8000-000000000004') = 5
             AND (SELECT COUNT(*) FROM project_task_boqs WHERE id LIKE '5F000000-0000-4000-8000-0000000005%') = 6
             AND (SELECT COUNT(*) FROM spk_boqs WHERE id LIKE '5F000000-0000-4000-8000-0000000007%') = 5
            THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'V2 S-B holds two live SPK assignments' AS check_name,
       CASE WHEN (SELECT COUNT(*) FROM project_task_spks
                  WHERE project_task_id = '5F000000-0000-4000-8000-000000000211'
                    AND unassigned_at IS NULL AND deleted_at IS NULL) = 2
            THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'V3 spk_type matches the live assignment count' AS check_name,
       CASE WHEN (SELECT spk_type FROM project_tasks WHERE id = '5F000000-0000-4000-8000-000000000210') = 'single'
             AND (SELECT spk_type FROM project_tasks WHERE id = '5F000000-0000-4000-8000-000000000211') = 'multi'
             AND (SELECT spk_type FROM project_tasks WHERE id = '5F000000-0000-4000-8000-000000000212') IS NULL
            THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'V4 SF.1.1. is linked to two different SPKs' AS check_name,
       CASE WHEN (SELECT COUNT(DISTINCT spk_id) FROM spk_boqs
                  WHERE project_task_boq_id = '5F000000-0000-4000-8000-000000000503') = 2
            THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'V5 contract B reports a negative spk_remaining' AS check_name,
       CASE WHEN (SELECT contract_value - spk_value FROM contracts
                  WHERE contract_id = '5F000000-0000-4000-8000-000000000005') = -30000000
            THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'V6 S-D has a draft and no submitted lines' AS check_name,
       CASE WHEN (SELECT COUNT(*) FROM project_task_boq_drafts
                  WHERE project_task_id = '5F000000-0000-4000-8000-000000000213') = 1
             AND (SELECT COUNT(*) FROM project_task_boqs
                  WHERE project_task_id = '5F000000-0000-4000-8000-000000000213' AND deleted_at IS NULL) = 0
            THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'V7 no unit placeholder survived in a draft payload' AS check_name,
       CASE WHEN (SELECT COUNT(*) FROM project_task_boq_drafts
                  WHERE id LIKE '5F000000-0000-4000-8000-0000000008%'
                    AND payload LIKE '%UNIT[_]%[_]ID%') = 0
            THEN 'PASS' ELSE 'FAIL' END AS result;

SELECT 'V8 project is in progress (submit precondition)' AS check_name,
       CASE WHEN (SELECT status FROM projects WHERE id = '5F000000-0000-4000-8000-000000000004') = 'in progress'
            THEN 'PASS' ELSE 'FAIL' END AS result;
