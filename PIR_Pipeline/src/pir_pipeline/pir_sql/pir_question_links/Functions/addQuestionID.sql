-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This function adds the values from the question ID column as elements of a JSON object.
-- Parameters:
--   json_obj JSON - The JSON object to add the question ID to.
--   id VARCHAR(100) - The question ID to add. Can be a column value or a string literal.
--   var_name VARCHAR(64) - The name of the json element where the question ID will be added.
-- Returns: A JSON object with the question ID added to each element.
-- Examples: 
--  SELECT pir_question_links.addQuestionID('[{"name": "John"}, {"name": "Jane"}]', '4fbac59c868a7255a0acb42bd6e2ec54', 'question_id');
--  SELECT pir_question_links.addQuestionID(JSON_EXTRACT(proposed_link, "$.*"), question_id, 'question_id')
--  FROM pir_question_links.unlinked;
-- =============================================
DROP FUNCTION IF EXISTS pir_question_links.addQuestionID;

DELIMITER //
CREATE FUNCTION pir_question_links.addQuestionID (json_obj JSON, id VARCHAR(100), var_name VARCHAR(64))
RETURNS JSON DETERMINISTIC
BEGIN

    -- Declare variables
	DECLARE i INT DEFAULT 0;
    DECLARE ind VARCHAR(10);
    DECLARE extract JSON;
    DECLARE new_val JSON;
    
    -- Loop through the JSON object and add the question ID to each element
    WHILE i < JSON_LENGTH(json_obj) DO
		SET ind = CONCAT('$[', i, ']');
		SET extract = JSON_EXTRACT(json_obj, ind);
        SET new_val = JSON_SET(extract, CONCAT('$.', var_name), JSON_ARRAY(id));
        SET json_obj = JSON_REPLACE(json_obj, ind, new_val);
        SET i = i + 1;
    END WHILE;
    RETURN json_obj;

END //
DELIMITER ;