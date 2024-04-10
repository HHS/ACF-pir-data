-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This view provides a list of questions that have not been linked.
-- It unnests the proposed_link JSON array and joins it with the unlinked table,
-- so that the resultant view contains one row per proposed link.
-- =============================================

CREATE OR REPLACE VIEW pir_question_links.unlinked_v AS 
WITH 
distinct_unlinked AS (
	SELECT DISTINCT question_id, question_name, question_text, question_number, section
    FROM pir_question_links.unlinked
)
SELECT unnested_links.*, proposed.`year`, distinct_unlinked.question_name, distinct_unlinked.question_text, 
	distinct_unlinked.question_number, distinct_unlinked.section
FROM pir_question_links.proposed_link proposed
JOIN JSON_TABLE(
	proposed.proposed_link,
    '$[*]' COLUMNS(
		NESTED PATH '$' COLUMNS(
			question_id VARCHAR(100) PATH '$.question_id[*]',
            proposed_id VARCHAR(100) PATH '$.proposed_id[*]',
            question_name_dist INT PATH '$.question_name_dist[*]',
            question_text_dist INT PATH '$.question_text_dist[*]',
            question_number_dist INT PATH '$.question_number_dist[*]',
            section_dist INT PATH '$.section_dist[*]'
        )
    )
) unnested_links
ON proposed.question_id = unnested_links.question_id
LEFT JOIN distinct_unlinked
ON proposed.question_id = distinct_unlinked.question_id
;