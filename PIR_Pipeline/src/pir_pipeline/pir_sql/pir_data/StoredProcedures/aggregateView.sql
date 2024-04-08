-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: Create a view aggregated at the specified level.
-- Parameters:
--   IN view_name VARCHAR(64) - The name of the view to be created
--   IN agg_level VARCHAR(64) - Aggregation level (state, type, region, grant, or national)
--   IN question_id VARCHAR(64) - The ID of the question to be aggregated
--   IN kind VARCHAR(12) - The kind of question ID (uqid or question_id)
-- Returns: None
-- Example: 
-- CALL pir_data.aggregateView('test', 'state', '0008a5809edbdca1d1141ea1f2eb8dfa', 'question_id');
-- SELECT * from test_state limit 1;
-- +---------------+------+------+---------------------+------+--------------------+-------+
-- | program_state | year | min  | mean                | max  | std                | count |
-- +---------------+------+------+---------------------+------+--------------------+-------+
-- | AK            | 2021 | 0    | 0.15384615384615385 | 4    | 0.7692307692307693 |    26 |
-- +---------------+------+------+---------------------+------+--------------------+-------+
-- =============================================
DROP PROCEDURE IF EXISTS pir_data.aggregateView;

DELIMITER //

CREATE PROCEDURE pir_data.aggregateView(
	IN view_name VARCHAR(64), IN agg_level VARCHAR(64),
    IN question_id VARCHAR(64), IN kind VARCHAR(12)
)
BEGIN

	DECLARE suffix VARCHAR(10) DEFAULT '';
	DECLARE where_cond TEXT DEFAULT '';
    
	-- PROGRAM TYPE AND GRANT IS NOT HANDLED HERE, NEED TO ADJUST INPUTS
	IF agg_level REGEXP 'state' THEN
		SET agg_level = 'program_state';
		SET suffix = '_state';
	ELSEIF agg_level REGEXP 'type' THEN
		SET agg_level = 'program_type';
		SET suffix = '_type';
	ELSEIF agg_level REGEXP 'region' THEN
		SET suffix = '_region';
	ELSEIF agg_level REGEXP 'grant' THEN
		SET agg_level = 'grant_number';
		SET suffix = '_grant';
	ELSE 
		SET SUFFIX = '_national';
    END IF;
    
	-- Get the where condition for the aggregation level
    SET where_cond = (SELECT aggregateWhereCondition(agg_level));
    
	-- Create the question query for the view
    IF kind = 'uqid' THEN
		SET @question_query = CONCAT(
			'FROM response resp ',
			'INNER JOIN (
				SELECT DISTINCT question_id
				FROM pir_question_links.linked a
				INNER JOIN (
					SELECT DISTINCT uqid 
					FROM pir_question_links.linked 
					WHERE question_id = ', QUOTE(question_id),
				') b
				ON a.uqid = b.uqid
			) c
			ON resp.question_id = c.question_id ',
            'LEFT JOIN program prg ',
			'ON resp.uid = prg.uid AND resp.`year` = prg.`year` '
		);
	ELSE
		SET @question_query = CONCAT(
			'FROM ( ',
			'	SELECT * ',
			'	FROM response',
			'	WHERE question_id = ', QUOTE(question_id),
			') resp ',
			'LEFT JOIN program prg ',
			'ON resp.uid = prg.uid AND resp.`year` = prg.`year` '
        );
    END IF;

	-- Create the aggregation query for the view
	IF agg_level = "national" THEN
		SET @agg_query = CONCAT(
			'CREATE OR REPLACE VIEW ', view_name, suffix, ' AS ',
			'SELECT resp.year, min(answer) as `min`, avg(answer) as `mean`, max(answer) as `max`, std(answer) as `std`, ',
				'count(answer) as `count` ',
			@question_query,
            'GROUP BY resp.year'
        );
    ELSE
		SET @agg_query = CONCAT(
			'CREATE OR REPLACE VIEW ', view_name, suffix, ' AS ',
			'SELECT ', agg_level, ', resp.year, min(answer) as `min`, avg(answer) as `mean`, max(answer) as `max`, std(answer) as `std`, ',
				'count(answer) as `count` ',
			@question_query,
			'WHERE ', where_cond, ' ',
			'GROUP BY ', agg_level, ', resp.year'
			' ORDER BY ', agg_level, ', resp.year'
		);
	END IF;
    
	-- Execute the aggregation query
    SELECT @agg_query;
    PREPARE view_statement FROM @agg_query;
    EXECUTE view_statement;
    DEALLOCATE PREPARE view_statement;

END //

DELIMITER ;