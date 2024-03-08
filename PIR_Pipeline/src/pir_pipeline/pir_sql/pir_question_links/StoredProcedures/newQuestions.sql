-- This stored procedure is designed to identify and insert new questions into the 'new_questions' table based on the data from the 'linked' and 'unlinked' tables.

DROP PROCEDURE IF EXISTS pir_question_links.newQuestions;

-- Change the delimiter to // to allow the use of semicolons within the procedure.
DELIMITER //

-- Create the stored procedure 'newQuestions'.
CREATE PROCEDURE pir_question_links.newQuestions()
BEGIN
    -- Declare variables to hold current and maximum years.
    DECLARE current_year INT DEFAULT 0;
    DECLARE max_year INT DEFAULT 0;
    
    -- Drop temporary tables if they already exist to avoid conflicts.
    DROP TEMPORARY TABLE IF EXISTS qid_year;
    DROP TEMPORARY TABLE IF EXISTS qid_year2;
    
    -- Create a temporary table 'qid_year' to hold distinct data from 'linked' and 'unlinked' tables.
    CREATE TEMPORARY TABLE qid_year AS (
        SELECT DISTINCT `year`, question_id, question_number, question_name, question_text, category, section
        FROM linked
        UNION 
        SELECT DISTINCT `year`, question_id, question_number, question_name, question_text, category, section
        FROM unlinked
    );

    -- Create another temporary table 'qid_year2' to hold data from 'qid_year'.
    CREATE TEMPORARY TABLE qid_year2 AS (
        SELECT *
        FROM qid_year
    );

    -- Retrieve the minimum and maximum years from the 'qid_year' table.
    SET current_year = (
        SELECT min(`year`)
        FROM qid_year
    );

    SET max_year = (
        SELECT max(`year`)
        FROM qid_year
    );

    -- Iterate over each year from the minimum to the maximum year.
    WHILE current_year <= max_year DO
        -- Insert new questions into the 'new_questions' table.
        INSERT INTO new_questions
            SELECT `year`, question_id, question_name, question_text, question_number, category, section
            FROM qid_year
            WHERE `year` = current_year AND question_id NOT IN (
                SELECT question_id
                FROM qid_year2
                WHERE `year` < current_year
            );
        
        -- Increment the current year.
        SET current_year = current_year + 1;
    END WHILE;
END //

-- Reset the delimiter to ;
DELIMITER ;
