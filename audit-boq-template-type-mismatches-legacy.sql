-- T-10: BOQ template-type audit (pre-migration rows, template_type IS NULL).
--
-- Type inferred from boq_details.kind, since the layout was never recorded on these rows.
-- Rows whose only kinds are PM/PC/DC are excluded as "ambiguous": Type 3 and Type 4 both
-- use those three, so the source is genuinely unrecoverable.
--
-- Zero result means "no PROVABLE mismatch," not "no mismatch" — a floor, not a ceiling.

WITH inferred AS (
    SELECT b.id, b.contract_id, b.boq_category_id,
           CASE
             WHEN MAX(CASE WHEN d.kind IN ('Discipline Eng','Designer Eng') THEN 1 ELSE 0 END) = 1 THEN 'Type 4'
             WHEN MAX(CASE WHEN d.kind IN ('Sr. Engr 2','Sr. Engr 1','Engr 3','Engr 2','Engr 1',
                                           'Sr. Dsgn 2','Sr. Dsgn 1','Dsgn 3','Dsgn 2','Dsgn 1',
                                           'Sr. Drftr','Drftr 3','Drftr 2','Drftr 1') THEN 1 ELSE 0 END) = 1 THEN 'Type 3'
             WHEN MAX(CASE WHEN d.kind IN ('Upah','Material','Sewa Alat','Transport') THEN 1 ELSE 0 END) = 1 THEN 'Type 2'
             WHEN MAX(CASE WHEN d.kind = 'Default' THEN 1 ELSE 0 END) = 1 THEN 'Type 1'
             ELSE 'ambiguous'
           END AS inferred_type
    FROM boqs b
    JOIN boq_details d ON d.boq_id = b.id
    WHERE b.deleted_at IS NULL AND b.template_type IS NULL
    GROUP BY b.id, b.contract_id, b.boq_category_id
)
SELECT i.id AS boq_id, i.contract_id, c.name AS category, i.inferred_type
FROM inferred i
LEFT JOIN boq_categories c ON c.id = i.boq_category_id
WHERE i.inferred_type <> 'ambiguous'
  AND NOT EXISTS (
        SELECT 1
        FROM boq_category_template_types ct
        WHERE ct.boq_category_id = i.boq_category_id
          AND ct.template_type = i.inferred_type
          AND ct.deleted_at IS NULL)
