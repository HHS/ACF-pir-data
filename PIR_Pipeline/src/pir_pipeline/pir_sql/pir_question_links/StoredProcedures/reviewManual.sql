-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 05/02/2024
-- Description: Review linked/unlinked manual records
-- Parameters:
--   IN agg_level VARCHAR(8) - Type of manual links to review (linked, unlinked)
-- Returns: None
-- Example: CALL pir_question_links.reviewManual('linked');
-- =============================================
DROP PROCEDURE IF EXISTS pir_question_links.reviewManual;

DELIMITER //

CREATE PROCEDURE pir_question_links.reviewManual(
	IN link_type VARCHAR(8)
)
BEGIN

	IF link_type = "linked" THEN
		WITH 
		DISTINCT_qid as (
			SELECT DISTINCT question_id, question_number, question_name
			FROM linked
		),
		DISTINCT_uqid as (
			SELECT DISTINCT uqid
			FROM linked
		)
		SELECT 
			`type`, base_id, linked_id,
			base.question_id as base_question_id, base.question_number as base_question_number, base.question_name as base_question_name,
			COALESCE(comparison_qid.question_id, comparison_uqid.uqid) as comparison_question_id,
            COALESCE(comparison_qid.question_number, "See pir_question_links.linked") as comparison_question_id,
            COALESCE(comparison_qid.question_name, "See pir_question_links.linked") as comparison_question_id
		FROM pir_logs.pir_manual_question_link pir_manual_question_link
		LEFT JOIN DISTINCT_qid base
		ON pir_manual_question_link.base_id = base.question_id
		LEFT JOIN DISTINCT_qid comparison_qid
		ON pir_manual_question_link.linked_id = comparison_qid.question_id
		LEFT JOIN DISTINCT_uqid comparison_uqid
		ON pir_manual_question_link.linked_id = comparison_uqid.uqid
		WHERE `type` = 'linked' & base.question_id IS NOT NULL
		;
	ELSE
		WITH 
		DISTINCT_linked as (
			SELECT DISTINCT uqid, question_number, question_name
			FROM linked
		),
		DISTINCT_unlinked as (
			SELECT DISTINCT question_id, question_number, question_name
			FROM unlinked
		)
		SELECT 
			`type`, 
			base.uqid as base_uqid, base.question_number as base_question_number, base.question_name as base_question_name,
			comparison.question_id as comparison_question_id, comparison.question_number as comparison_question_number, comparison.question_name as comparison_question_name
		FROM pir_logs.pir_manual_question_link pir_manual_question_link
		LEFT JOIN DISTINCT_linked base
		ON pir_manual_question_link.base_id = base.uqid
		LEFT JOIN DISTINCT_unlinked comparison
		ON pir_manual_question_link.linked_id = comparison.question_id
		WHERE `type` = 'unlinked' & base.uqid IS NOT NULL
		;
    END IF;

END //

DELIMITER ;