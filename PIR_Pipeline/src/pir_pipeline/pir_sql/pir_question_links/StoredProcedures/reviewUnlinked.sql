-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: Return a question and its proposed links. Used in the Monitoring Dashboard for reviewing unlinked questions.
-- Parameters:
--   qid VARCHAR(255) - The question ID to review.
-- Returns: None
-- Example: CALL pir_question_links.reviewUnlinked('01b3b14a36cc12d7db5dac4b163a35da');
-- =============================================
DROP PROCEDURE IF EXISTS pir_question_links.reviewUnlinked;
DELIMITER //

CREATE PROCEDURE pir_question_links.reviewUnlinked(IN qid VARCHAR(255))
BEGIN

    -- Query unlinked_v, linked, and unlinked tables to get information about the base question and comparison question
    WITH
	unlinked_q AS (
		SELECT *
        FROM unlinked_v
        WHERE question_id = qid
	),
    distinct_linked AS (
        SELECT DISTINCT question_id, question_name, question_text, question_number, section, JSON_ARRAYAGG(`year`) OVER (PARTITION BY question_id) as `year`
        FROM linked
    ),
    distinct_unlinked AS (
        SELECT DISTINCT question_id, question_name, question_text, question_number, section, JSON_ARRAYAGG(`year`) OVER (PARTITION BY question_id) as `year`
        FROM unlinked 
    ),
    distinct_unlinked_base AS (
		SELECT *
        FROM distinct_unlinked
	)
    SELECT unlinked_q.*, 
        distinct_unlinked_base.question_name as base_question_name,
        COALESCE(distinct_linked.question_name, distinct_unlinked.question_name) AS comparison_question_name,
        distinct_unlinked_base.question_text as base_question_text,
        COALESCE(distinct_linked.question_text, distinct_unlinked.question_text) AS comparison_question_text,
        distinct_unlinked_base.question_number as base_question_number,
        COALESCE(distinct_linked.question_number, distinct_unlinked.question_number) AS comparison_question_number,
        distinct_unlinked_base.section as base_section,
        COALESCE(distinct_linked.section, distinct_unlinked.section) AS comparison_section,
        distinct_unlinked_base.`year` as base_year,
        COALESCE(distinct_linked.`year`, distinct_unlinked.`year`) AS comparison_year
    FROM unlinked_q
    LEFT JOIN distinct_linked
    ON unlinked_q.proposed_id = distinct_linked.question_id
    LEFT JOIN distinct_unlinked
    ON unlinked_q.proposed_id = distinct_unlinked.question_id
    LEFT JOIN distinct_unlinked_base
    ON unlinked_q.question_id = distinct_unlinked_base.question_id
    ;

END //
DELIMITER ;