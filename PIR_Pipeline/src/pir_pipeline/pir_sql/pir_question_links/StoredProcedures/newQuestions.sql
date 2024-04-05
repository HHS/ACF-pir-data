-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This stored procedure populates the new_questions table with questions that have not been linked in previous years.
-- Parameters: None
-- Returns: None
-- Example: CALL pir_question_links.newQuestions();
-- =============================================
DROP PROCEDURE IF EXISTS pir_question_links.newQuestions;

DELIMITER //

CREATE PROCEDURE pir_question_links.newQuestions()
BEGIN

	-- Declare variables
	DECLARE current_year INT DEFAULT 0;
	DECLARE max_year INT DEFAULT 0;

	-- Drop temporary tables if they exist
	DROP TEMPORARY TABLE IF EXISTS qid_year;
	DROP TEMPORARY TABLE IF EXISTS qid_year2;

	-- Create temporary tables
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

	-- Set current year and max year
	SET current_year = (
		SELECT min(`year`)
		FROM qid_year
	);

	SET max_year = (
		SELECT max(`year`)
		FROM qid_year
	);

	-- Create new_questions table
	WHILE current_year <= max_year DO
		REPLACE INTO new_questions
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
