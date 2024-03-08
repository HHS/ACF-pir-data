-- This MySQL function combines elements from two JSON arrays into a single JSON array,
-- inserting each element from the first array into the corresponding index of the second array
-- along with an additional variable name.

DROP FUNCTION IF EXISTS pir_question_links.combineArray;

DELIMITER //

CREATE FUNCTION pir_question_links.combineArray(column_1 JSON, column_2 JSON, var_name VARCHAR(64))
RETURNS JSON DETERMINISTIC
BEGIN
    -- Declare variables to be used within the function.
    DECLARE i INT DEFAULT 0;
    DECLARE extract JSON;
    DECLARE ind VARCHAR(100);

    -- Check if the lengths of both JSON arrays are equal.
    IF JSON_LENGTH(column_1) != JSON_LENGTH(column_2) THEN
        -- Set a SQL mode message if the lengths are not equal, indicating a potential issue.
        SET SESSION sql_mode = if(0, @@SESSION.sql_mode, 'JSON columns do not have same length!');
    END IF;

    -- Loop through each element of the first JSON array.
    WHILE i < JSON_LENGTH(column_1) DO
        -- Construct the index to extract element from the first JSON array.
        SET ind = CONCAT('$[', i, ']');
        -- Extract the element from the first JSON array.
        SET extract = JSON_EXTRACT(column_1, ind);
        -- Construct the index to insert the extracted element into the second JSON array,
        -- along with the provided variable name.
        SET ind = CONCAT('$[', i, '].', var_name);
        -- Insert the extracted element into the second JSON array at the constructed index.
        SET column_2 = JSON_INSERT(column_2, ind, JSON_ARRAY(extract));
        -- Increment the loop counter.
        SET i = i + 1;
    END WHILE;
    
    -- Return the modified second JSON array.
    RETURN column_2;
END //

DELIMITER ;
