DROP PROCEDURE IF EXISTS pir_data_test.aggregateView;

DELIMITER //

CREATE PROCEDURE pir_data_test.aggregateView(
	IN view_name VARCHAR(64), IN agg_level VARCHAR(64),
    IN question_id VARCHAR(64), IN kind VARCHAR(12)
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
    
    IF kind = 'uqid' THEN
		SET @question_query = CONCAT(
			'FROM response resp ',
			'INNER JOIN (
				SELECT DISTINCT question_id
				FROM question_links.linked a
				INNER JOIN (
					SELECT DISTINCT uqid 
					FROM question_links.linked 
					WHERE question_id = ', QUOTE(question_id),
				') b
				ON a.uqid = b.uqid
			) c
			ON resp.question_id = c.question_id ',
            'LEFT JOIN program prg ',
			'ON resp.uid = prg.uid '
		);
	ELSE
		SET @question_query = CONCAT(
			'FROM ( ',
			'	SELECT * ',
			'	FROM response',
			'	WHERE question_id = ', QUOTE(question_id),
			') resp ',
			'LEFT JOIN program prg ',
			'ON resp.uid = prg.uid '
        );
    END IF;

	IF agg_level = "national" THEN
		SET @agg_query = CONCAT(
			'CREATE OR REPLACE VIEW ', view_name, suffix, ' AS ',
			'SELECT resp.year, sum(answer) as `sum`, min(answer) as `min`, avg(answer) as `mean`, max(answer) as `max`, std(answer) as `std`, ',
				'count(answer) as `count` ',
			@question_query,
            'GROUP BY resp.year'
        );
    ELSE
		SET @agg_query = CONCAT(
			'CREATE OR REPLACE VIEW ', view_name, suffix, ' AS ',
			'SELECT ', agg_level, ', resp.year, sum(answer) as `sum`, min(answer) as `min`, avg(answer) as `mean`, max(answer) as `max`, std(answer) as `std`, ',
				'count(answer) as `count` ',
			@question_query,
			'WHERE ', where_cond, ' ',
			'GROUP BY resp.year, ', agg_level,
			' ORDER BY resp.year, ', agg_level
		);
	END IF;
    
    select @agg_query;
    PREPARE view_statement FROM @agg_query;
    EXECUTE view_statement;
    DEALLOCATE PREPARE view_statement;

END //

DELIMITER ;