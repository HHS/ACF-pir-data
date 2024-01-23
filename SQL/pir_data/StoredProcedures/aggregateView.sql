DROP PROCEDURE IF EXISTS aggregateView;

DELIMITER //

CREATE PROCEDURE aggregateView(
	IN view_name VARCHAR(64), IN agg_level VARCHAR(64),
	IN response_table VARCHAR(64), IN question_id VARCHAR(64)
)
BEGIN

	DECLARE suffix VARCHAR(10) DEFAULT '';
	DECLARE where_cond TEXT DEFAULT '';
    
	-- PROGRAM TYPE AND GRANT IS NOT HANDLED HERE, NEED TO ADJUST INPUTS
	IF agg_level REGEXP 'state' THEN
		SET suffix = '_state';
	ELSEIF agg_level REGEXP 'type' THEN
		SET suffix = '_type';
	ELSEIF agg_level REGEXP 'region' THEN
		SET suffix = '_region';
	ELSEIF agg_level REGEXP 'grant' THEN
		SET suffix = '_grant';
	ELSE 
		SET SUFFIX = '_national';
    END IF;
    
    SET where_cond = (SELECT aggregateWhereCondition(agg_level));

	IF agg_level = "national" THEN
		SET @agg_query = CONCAT(
			'CREATE OR REPLACE VIEW ', view_name, suffix, ' AS '
			'SELECT min(resp.`year`) as year, min(answer) as `min`, avg(answer) as `mean`, max(answer) as `max`, std(answer) as `std`, ',
				'count(answer) as `count` ',
			'FROM ( ',
			'	SELECT * ',
			'	FROM ', response_table,
			'	WHERE question_id = ', QUOTE(question_id),
			') resp ',
			'LEFT JOIN program prg ',
			'ON resp.uid = prg.uid '
        );
    ELSE
		SET @agg_query = CONCAT(
			'CREATE OR REPLACE VIEW ', view_name, suffix, ' AS '
			'SELECT ', agg_level, ', min(resp.`year`) as year, min(answer) as `min`, avg(answer) as `mean`, max(answer) as `max`, std(answer) as `std`, ',
				'count(answer) as `count` ',
			'FROM ( ',
			'	SELECT * ',
			'	FROM ', response_table,
			'	WHERE question_id = ', QUOTE(question_id),
			') resp ',
			'LEFT JOIN program prg ',
			'ON resp.uid = prg.uid ',
			'WHERE ', where_cond, ' ',
			'GROUP BY ', agg_level,
			' ORDER BY ', agg_level
		);
	END IF;
    
    -- select @agg_query;
    PREPARE view_statement FROM @agg_query;
    EXECUTE view_statement;
    DEALLOCATE PREPARE view_statement;

END //

DELIMITER ;