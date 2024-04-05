-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This function combines two JSON arrays into a single JSON array.
-- Parameters:
--   column_1 JSON - The first JSON array to combine.
--   column_2 JSON - The second JSON array to combine.
--   var_name VARCHAR(64) - The name of the json element where the values of column_1 will be added.
-- Returns: A JSON array with the values of column_1 added to each element.
-- Example:
--   SELECT 
--   	pir_question_links.combineArray(
--   		'["The Lawn", "The Lane"]',
--   		'[{"name": "John"}, {"name": "Dane"}]',
--           'location'
--   	)
--   ;
-- =============================================
DROP FUNCTION IF EXISTS pir_question_links.combineArray;

DELIMITER //

CREATE FUNCTION pir_question_links.combineArray(column_1 JSON, column_2 JSON, var_name VARCHAR(64))
RETURNS JSON DETERMINISTIC
BEGIN
	
    -- Declare variables
    DECLARE i INT DEFAULT 0;
    DECLARE extract JSON;
    DECLARE ind VARCHAR(100);
    
    -- Check if the JSON arrays have the same length
    IF JSON_LENGTH(column_1) != JSON_LENGTH(column_2) THEN
		SET SESSION sql_mode = if(0, @@SESSION.sql_mode, 'JSON columns do not have same length!');
	END IF;
    
    -- Loop through the first JSON array and add the values to the second JSON array
    WHILE i < JSON_LENGTH(column_1) DO
		SET ind = CONCAT('$[', i, ']');
		SET extract = JSON_EXTRACT(column_1, ind);
        SET ind = CONCAT('$[', i, '].', var_name);
        SET column_2 = JSON_INSERT(column_2, ind, JSON_ARRAY(extract));
        SET i = i + 1;
    END WHILE;
    RETURN column_2;
    
END //

DELIMITER ;