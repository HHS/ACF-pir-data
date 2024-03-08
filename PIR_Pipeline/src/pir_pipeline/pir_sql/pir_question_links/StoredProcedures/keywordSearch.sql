DROP PROCEDURE IF EXISTS pir_question_links.keywordSearch;

-- Change delimiter to //
DELIMITER //

CREATE PROCEDURE pir_question_links.keywordSearch(
    IN tab VARCHAR(25), IN col VARCHAR(100), IN string TEXT, IN exact INT
)
BEGIN
    -- Check if exact match is required
    IF exact = 1 THEN
        -- If exact match required, construct query with equality condition
        SET @q = CONCAT(
            'SELECT * ',
            'FROM ', tab,
            ' WHERE ', col, ' = ', QUOTE(string)
        );
    ELSE
        -- If exact match is not required, construct query with regular expression
        SET @q = CONCAT(
            'SELECT * ',
            'FROM ', tab,
            ' WHERE ', col, ' REGEXP ', QUOTE(string)
        );
    END IF;

    -- Prepare and execute the constructed query
    PREPARE stmt FROM @q;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //

-- Reset the delimiter to ;
DELIMITER ;
