DELIMITER //

CREATE PROCEDURE newQuestions()
BEGIN

DECLARE current_year INT DEFAULT 0;
DECLARE max_year INT DEFAULT 0;

DROP TEMPORARY TABLE IF EXISTS qid_year;
DROP TEMPORARY TABLE IF EXISTS qid_year2;
CREATE TEMPORARY TABLE qid_year AS (
	SELECT DISTINCT `year`, question_id, question_number, question_name, question_text, category, section
	FROM linked
	UNION 
	SELECT DISTINCT `year`, question_id, question_number, question_name, question_text, category, section
	FROM unlinked
);

CREATE TEMPORARY TABLE qid_year2 AS (
	SELECT *
    FROM qid_year
);

SET current_year = (
	SELECT min(`year`)
    FROM qid_year
);

SET max_year = (
	SELECT max(`year`)
    FROM qid_year
);

WHILE current_year <= max_year DO
	INSERT INTO new_questions
		SELECT `year`, question_id, question_name, question_text, question_number, category, section
		from qid_year
		where `year` = current_year and question_id not in (
			select question_id
			from qid_year2
			where `year` < current_year
		)
	;
    SET current_year = current_year + 1;
END WHILE;

END //
DELIMITER ;
