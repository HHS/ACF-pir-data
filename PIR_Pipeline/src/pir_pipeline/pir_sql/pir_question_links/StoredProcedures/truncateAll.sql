-- Description: This MySQL stored procedure truncates data from two tables, 'linked' and 'unlinked', within the database 'pir_question_links'.

DROP PROCEDURE IF EXISTS pir_question_links.truncateAll;

-- Change delimiter to allow the use of semicolons within the procedure.
DELIMITER //

-- Create the stored procedure 'truncateAll'.
CREATE PROCEDURE pir_question_links.truncateAll()
BEGIN
    -- Truncate the 'linked' table, removing all records from it.
    TRUNCATE TABLE linked;
    
    -- Truncate the 'unlinked' table, removing all records from it.
    TRUNCATE TABLE unlinked;
END //

-- Reset delimiter to default.
DELIMITER ;
