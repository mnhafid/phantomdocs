-- 12-modify-returned-data-fix.sql
-- Run once after deploying the change that removes modify_returned (02-changes.md, 18 Nov 2026).
-- Plans parked at modify_returned go back to need_review (waiting_review), or to rejected when their
-- last round was the final Reject round (cycle outcome = rejected, the new terminal state).
-- Check the counts with the SELECT first, then run the UPDATEs in one transaction.

SELECT 'pep' AS src, p.approval_status, c.outcome, COUNT(*) AS plans
FROM pep_action_plan p LEFT JOIN action_plan_approval_cycles c ON c.id = p.current_cycle_id
WHERE p.approval_status = 'modify_returned' GROUP BY p.approval_status, c.outcome
UNION ALL
SELECT 'phss', p.approval_status, c.outcome, COUNT(*)
FROM phss_action_plan p LEFT JOIN action_plan_approval_cycles c ON c.id = p.current_cycle_id
WHERE p.approval_status = 'modify_returned' GROUP BY p.approval_status, c.outcome;

BEGIN TRANSACTION;

UPDATE p SET p.approval_status = 'rejected'
FROM pep_action_plan p JOIN action_plan_approval_cycles c ON c.id = p.current_cycle_id
WHERE p.approval_status = 'modify_returned' AND c.outcome = 'rejected';

UPDATE p SET p.approval_status = 'rejected'
FROM phss_action_plan p JOIN action_plan_approval_cycles c ON c.id = p.current_cycle_id
WHERE p.approval_status = 'modify_returned' AND c.outcome = 'rejected';

UPDATE pep_action_plan SET approval_status = 'waiting_review' WHERE approval_status = 'modify_returned';
UPDATE phss_action_plan SET approval_status = 'waiting_review' WHERE approval_status = 'modify_returned';

-- COMMIT; -- after checking the row counts
