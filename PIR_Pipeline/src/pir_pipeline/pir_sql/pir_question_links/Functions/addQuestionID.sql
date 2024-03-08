DROP FUNCTION IF EXISTS pir_question_links.addQuestionID;

DELIMITER //

-- Create a MySQL function named 'addQuestionID' that takes three parameters:
-- 1. json_obj: The JSON object to modify.
-- 2. id: The ID to add to the JSON array.
-- 3. var_name: The name of the variable where the ID will be added.
-- Returns: JSON object with the added question ID.

CREATE FUNCTION pir_question_links.addQuestionID (json_obj JSON, id VARCHAR(100), var_name VARCHAR(64))

-- Define the return type of the function as JSON and set it to be deterministic.
RETURNS JSON DETERMINISTIC
BEGIN

    -- Declare variables to be used within the function.
    DECLARE i INT DEFAULT 0;             -- Counter for the loop.
    DECLARE ind VARCHAR(10);             -- Holds the index of the JSON array.
    DECLARE extract JSON;                -- Holds the extracted JSON object.
    DECLARE new_val JSON;                -- Holds the new JSON object after modification.
    
    -- Start a loop to iterate through each element of the JSON array.
    WHILE i < JSON_LENGTH(json_obj) DO

        -- Set the index variable based on the current iteration.
        SET ind = CONCAT('$[', i, ']');

        -- Extract the JSON object at the specified index.
        SET extract = JSON_EXTRACT(json_obj, ind);

        -- Set the new value by adding the ID to the specified variable name.
        SET new_val = JSON_SET(extract, CONCAT('$.', var_name), JSON_ARRAY(id));

        -- Replace the original JSON object with the modified one.
        SET json_obj = JSON_REPLACE(json_obj, ind, new_val);

        -- Increment the counter for the next iteration.
        SET i = i + 1;
    END WHILE;

    -- Return the modified JSON object.
    RETURN json_obj;

END //

-- Reset the delimiter back to semicolon.
DELIMITER ;
