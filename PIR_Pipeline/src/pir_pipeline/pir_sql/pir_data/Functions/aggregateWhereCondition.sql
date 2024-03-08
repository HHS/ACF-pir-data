-- This function drops the existing 'aggregateWhereCondition' function if it already exists in the pir_data schema.
DROP FUNCTION IF EXISTS pir_data.aggregateWhereCondition;

-- Delimiter is changed to // to enable the creation of the function.
DELIMITER //

-- This function takes a string of column names as input and returns a WHERE condition string 
-- that checks if each column is not NULL.
CREATE FUNCTION pir_data.aggregateWhereCondition(cols VARCHAR(100))
RETURNS TEXT DETERMINISTIC
BEGIN

    -- Declaration of variables used within the function.
    DECLARE where_cond TEXT DEFAULT '';
    DECLARE extract VARCHAR(100) DEFAULT '';
    DECLARE ind INT DEFAULT 0;
    
    -- Loop iterates until 'ind' becomes 1.
    WHILE ind != 1 DO
		-- Extracts the first column name from 'cols'.
		SET extract = SUBSTRING_INDEX(cols, ',', 1);
        -- If 'where_cond' is empty, concatenate the column name with 'IS NOT NULL',
        -- else concatenate 'AND' followed by the column name with 'IS NOT NULL'.
        IF where_cond = '' THEN
			SET where_cond = CONCAT(where_cond, ' ', extract, ' IS NOT NULL');
		ELSE
			SET where_cond = CONCAT(where_cond, ' AND ', extract, ' IS NOT NULL');
		END IF;
        -- Sets the position of the next comma in 'cols' to 'ind'.
        SET ind = Locate(',', cols) + 1;
        -- Removes the first column name from 'cols' using 'ind' as the starting position.
        SET cols = TRIM(SUBSTR(cols, ind));
    END WHILE;
    
    -- Returns the aggregated WHERE condition string.
	RETURN where_cond;

END //

-- Resetting the delimiter back to ;
DELIMITER ;