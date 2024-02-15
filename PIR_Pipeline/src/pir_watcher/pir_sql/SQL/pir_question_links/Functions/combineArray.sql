DROP FUNCTION IF EXISTS combineArray;

DELIMITER //

CREATE FUNCTION combineArray(column_1 JSON, column_2 JSON, var_name VARCHAR(64))
RETURNS JSON DETERMINISTIC
BEGIN
	
    DECLARE i INT DEFAULT 0;
    DECLARE extract JSON;
    DECLARE ind VARCHAR(100);
    
    IF JSON_LENGTH(column_1) != JSON_LENGTH(column_2) THEN
		SET SESSION sql_mode = if(0, @@SESSION.sql_mode, 'JSON columns do not have same length!');
	END IF;
    
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