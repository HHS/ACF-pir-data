DROP TABLE IF EXISTS proposed_link;

CREATE TABLE proposed_link AS
SELECT 
	question_id,
    `year`,
    combineArray(JSON_KEYS(proposed_link), addQuestionID(JSON_EXTRACT(proposed_link, "$.*"), question_id, 'question_id'), 'proposed_id') as proposed_link
FROM unlinked
;

CREATE OR REPLACE VIEW unlinked_v AS 
SELECT b.*, a.`year`
FROM proposed_link a
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
;