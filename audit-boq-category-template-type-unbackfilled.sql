-- T-10: post-migration check — category/template links the backfill could not map.
--
-- The AddTemplateTypeToBoqCategoryTemplateTypes migration backfills template_type from the
-- old boq_file_templates.name FK, fail-closed: any link whose template name wasn't one of the
-- four known ones is left NULL on purpose, rather than guessing. A NULL here means that
-- category now permits NOTHING and its uploads will start failing — run this right after
-- the migration, not before.
--
-- Expect 0 rows.

SELECT ct.id, c.name AS category
FROM boq_category_template_types ct
LEFT JOIN boq_categories c ON c.id = ct.boq_category_id
WHERE ct.deleted_at IS NULL AND ct.template_type IS NULL
