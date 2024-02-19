CREATE OR REPLACE VIEW pir_question_links.unlinked_v AS 
SELECT b.*, a.`year`, c.question_name, c.question_text, c.question_number, c.section
FROM pir_question_links.proposed_link a
JOIN JSON_TABLE(
	a.proposed_link,
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
) b
ON a.question_id = b.question_id
LEFT JOIN (
	SELECT DISTINCT question_id, question_name, question_text, question_number, section
    FROM pir_question_links.unlinked
) c
ON a.question_id = c.question_id
;