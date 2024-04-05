-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This stored procedure creates a table of proposed links for questions that have not been linked in previous years.
-- Parameters: None
-- Returns: None
-- Example: CALL pir_question_links.proposedLink();
-- =============================================
DROP PROCEDURE IF EXISTS pir_question_links.proposedLink;

DELIMITER //

CREATE PROCEDURE pir_question_links.proposedLink()
BEGIN

	-- Drop table if it exists
	DROP TABLE IF EXISTS pir_question_links.proposed_link;

	-- Create table
	CREATE TABLE pir_question_links.proposed_link AS
	SELECT 
		question_id,
		`year`,
		pir_question_links.combineArray(
			JSON_KEYS(proposed_link), 
			pir_question_links.addQuestionID(
				JSON_EXTRACT(proposed_link, "$.*"), 
				question_id, 
				'question_id'
			), 
			'proposed_id'
		) as proposed_link
	FROM pir_question_links.unlinked
	;

END //

DELIMITER ;