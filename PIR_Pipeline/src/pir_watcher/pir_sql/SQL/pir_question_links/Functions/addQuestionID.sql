DROP FUNCTION IF EXISTS addQuestionID;

DELIMITER //
CREATE FUNCTION addQuestionID (json_obj JSON, id VARCHAR(100), var_name VARCHAR(64))
RETURNS JSON DETERMINISTIC
BEGIN

	DECLARE i INT DEFAULT 0;
    DECLARE ind VARCHAR(10);
    DECLARE extract JSON;
    DECLARE new_val JSON;
    
    WHILE i < JSON_LENGTH(json_obj) DO
		SET ind = CONCAT('$[', i, ']');
		SET extract = JSON_EXTRACT(json_obj, ind);
        SET new_val = JSON_SET(extract, CONCAT('$.', var_name), JSON_ARRAY(id));
        SET json_obj = JSON_REPLACE(json_obj, ind, new_val);
        SET i = i + 1;
    END WHILE;
    RETURN json_obj;

END //
DELIMITER ;