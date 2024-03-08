
DROP FUNCTION IF EXISTS pir_question_links.minYearLinked;

-- Change delimiter to //
DELIMITER //

-- Create the function 'minYearLinked'.
CREATE FUNCTION pir_question_links.minYearLinked ()
RETURNS INT DETERMINISTIC
BEGIN
    -- Declare a variable 'min_year' to store the minimum year value.
    DECLARE min_year INT DEFAULT 0;
    
    -- Set 'min_year' to the minimum year retrieved from the 'linked' table.
    SET min_year = (SELECT min(year) FROM linked);
    
    -- Return the minimum year.
    RETURN min_year;
END //

-- Reset the delimiter to ;
DELIMITER ;
