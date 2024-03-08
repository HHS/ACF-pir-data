-- This MySQL function checks the maximum year linked in the table `linked`.

-- Drop the function if it already exists to avoid conflicts.
DROP FUNCTION IF EXISTS pir_question_links.maxYearLinked;

-- Change the delimiter to // to allow defining the function.
DELIMITER //

-- Create the MySQL function maxYearLinked.
CREATE FUNCTION pir_question_links.maxYearLinked ()
RETURNS INT DETERMINISTIC
BEGIN
    -- Declare a variable max_year to store the maximum linked year.
    DECLARE max_year INT DEFAULT 0;
    
    -- Set max_year to the minimum year from the table `linked`.
    -- This query selects the minimum year from the `year` column in the `linked` table.
    SET max_year = (SELECT min(year) FROM linked);
    
    -- Return the maximum linked year.
    RETURN max_year;
    
-- End of the function definition.
END //

-- Reset the delimiter back to ;
DELIMITER ;
