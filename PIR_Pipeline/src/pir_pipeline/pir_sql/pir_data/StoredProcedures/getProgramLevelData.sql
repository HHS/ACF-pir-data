DROP PROCEDURE IF EXISTS pir_data.getProgramLevelData;

DELIMITER //

CREATE PROCEDURE pir_data.getProgramLevelData(
	IN col TEXT, IN val TEXT
)
BEGIN

	DECLARE where_cond TEXT DEFAULT '';
    
    SET col = CONCAT(
		'resp.', col
    );
	SET where_cond = CONCAT(
		'WHERE ', col, ' = ', QUOTE(val)
    );

	SET @prg_query = CONCAT(
		'
        SELECT prg.program_name, prg.grant_number, prg.program_number, prg.program_type, resp.question_id, resp.answer, resp.`year`
        FROM pir_data.response resp
        LEFT JOIN pir_data.program prg
        ON resp.uid = prg.uid AND resp.year = prg.year
        ',
        where_cond, ' ',
        'ORDER BY prg.grant_number, prg.program_number, prg.program_type, resp.year'
    );
    
    SELECT @prg_query;
    PREPARE statement FROM @prg_query;
    EXECUTE statement;
    DEALLOCATE PREPARE statement;

END //

DELIMITER ;