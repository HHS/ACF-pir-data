DELIMITER //

CREATE PROCEDURE questionKeywordSearch(
	IN tab varchar(25), IN col VARCHAR(100), IN string TEXT, IN exact INT
)
BEGIN

IF exact = 1 THEN
    SET @q = CONCAT(
        'SELECT * ',
        'FROM ', tab,
        ' WHERE ', col, ' = ', QUOTE(string)
    );
ELSE
    SET @q = CONCAT(
        'SELECT * ',
        'FROM ', tab,
        ' WHERE ', col, ' REGEXP ', QUOTE(string)
    );
END IF;

PREPARE stmt from @q;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

END //
DELIMITER ;