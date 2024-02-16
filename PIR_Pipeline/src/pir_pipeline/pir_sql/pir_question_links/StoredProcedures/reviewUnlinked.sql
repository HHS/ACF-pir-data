DROP PROCEDURE IF EXISTS reviewUnlinked;
DELIMITER //

CREATE PROCEDURE reviewUnlinked(IN qid VARCHAR(255))
BEGIN

SELECT a.*, 
    d.question_name as base_question_name,
    COALESCE(b.question_name, c.question_name) AS comparison_question_name,
    d.question_text as base_question_text,
    COALESCE(b.question_text, c.question_text) AS comparison_question_text,
    d.question_number as base_question_number,
    COALESCE(b.question_number, c.question_number) AS comparison_question_number,
	d.section as base_section,
    COALESCE(b.section, c.section) AS comparison_section,
    d.`year` as base_year,
    COALESCE(b.`year`, c.`year`) AS comparison_year
FROM (
	SELECT *
	FROM unlinked_v
	WHERE question_id = qid
) a
LEFT JOIN (
	SELECT DISTINCT question_id, question_name, question_text, question_number, section, JSON_ARRAYAGG(`year`) OVER (PARTITION BY question_id) as `year`
    FROM linked
) b
ON a.proposed_id = b.question_id
LEFT JOIN (
	SELECT DISTINCT question_id, question_name, question_text, question_number, section, JSON_ARRAYAGG(`year`) OVER (PARTITION BY question_id) as `year`
    FROM unlinked 
) c
ON a.proposed_id = c.question_id
LEFT JOIN (
	SELECT DISTINCT question_id, question_name, question_text, question_number, section, JSON_ARRAYAGG(`year`) OVER (PARTITION BY question_id) as `year`
    FROM unlinked 
) d
ON a.question_id = d.question_id
;

END //
DELIMITER ;