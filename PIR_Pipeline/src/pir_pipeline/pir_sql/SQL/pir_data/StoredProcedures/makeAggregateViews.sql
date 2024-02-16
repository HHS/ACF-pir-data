DROP PROCEDURE IF EXISTS makeAggregateViews;

DELIMITER //

CREATE PROCEDURE makeAggregateViews()
BEGIN

	DECLARE levels JSON DEFAULT '["national", "program_state", "region", "grant_number", "grant_number, program_type"]';
    DECLARE lvl VARCHAR(100) DEFAULT '';
    DECLARE i INT DEFAULT 0;
    
    WHILE i < JSON_LENGTH(levels) DO
		SET lvl = JSON_EXTRACT(levels, CONCAT('$[', i, ']'));
        CALL aggregateView('tot_cumul_enr_child', JSON_UNQUOTE(lvl), 'response2023', '06dab99713f029f78630648cc1e36bec');
        SET i = i + 1;
    END WHILE;

END //

DELIMITER ;