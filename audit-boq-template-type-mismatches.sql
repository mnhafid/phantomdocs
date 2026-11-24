-- T-10: BOQ template-type audit (post-migration rows).
--
-- Templates are code-defined (BoqFileType); a category's permitted types live in
-- boq_category_template_types.template_type. A BOQ is a mismatch if its own template_type
-- is not one of the types its category currently permits.
--
-- Only covers BOQs written after the code-first migration (template_type IS NOT NULL).
-- Pre-migration rows are NULL and unprovable from stored data alone — see
-- audit-boq-template-type-mismatches-legacy.sql for those, inferred from boq_details.kind.
--
-- Expect 0 rows. Non-zero blocks the phiDev cutover pending a remediation decision.

SELECT b.id AS boq_id, b.contract_id, b.template_type AS boq_template_type, c.name AS category
FROM boqs b
LEFT JOIN boq_categories c ON c.id = b.boq_category_id
WHERE b.deleted_at IS NULL
  AND b.template_type IS NOT NULL
  AND NOT EXISTS (
        SELECT 1
        FROM boq_category_template_types ct
        WHERE ct.boq_category_id = b.boq_category_id
          AND ct.template_type = b.template_type
          AND ct.deleted_at IS NULL)
