DROP PROCEDURE IF EXISTS aggregateTable;

DELIMITER //

CREATE PROCEDURE aggregateTable(
	IN agg_level VARCHAR(64)
)
BEGIN

	DECLARE suffix VARCHAR(10) DEFAULT '';
	DECLARE where_cond TEXT DEFAULT '';
    
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

	SET @drop_query = CONCAT(
		'DROP TABLE IF EXISTS response', suffix
	);
	IF agg_level = "national" THEN
		SET @agg_query = CONCAT(
			'CREATE TABLE response', suffix, ' AS '
			'SELECT `year`, question_id, min(answer) as `min`, avg(answer) as `mean`, max(answer) as `max`, std(answer) as `std`, ',
				'count(answer) as `count` ',
			'FROM response ',
            'GROUP BY `year`, question_id'
        );
    ELSE
		SET @agg_query = CONCAT(
			'CREATE TABLE response', suffix, ' AS '
			'SELECT ', agg_level, ', `year`, question_id, min(answer) as `min`, avg(answer) as `mean`, max(answer) as `max`, std(answer) as `std`, ',
				'count(answer) as `count` ',
			'FROM response resp ',
			'LEFT JOIN program prg ',
			'ON resp.uid = prg.uid ',
			'WHERE ', where_cond, ' ',
			'GROUP BY ', agg_level, ' `year`, question_id '
			'ORDER BY ', agg_level, ' `year`, quesiton_id '
		);
	END IF;
    
    -- select @agg_query;
    PREPARE drop_statement FROM @drop_query;
    EXECUTE drop_statement;
    DEALLOCATE PREPARE drop_statement;
    
    PREPARE create_statement FROM @agg_query;
    EXECUTE create_statement;
    DEALLOCATE PREPARE create_statement;

END //

DELIMITER ;