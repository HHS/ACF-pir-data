-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: Create a table aggregated at the specified level.
-- Parameters:
--   IN agg_level VARCHAR(64) - Aggregation level (state, type, region, grant, or national)
-- Returns: None
-- Example: CALL pir_data.aggregateTable('national');
-- =============================================
DROP PROCEDURE IF EXISTS pir_data.aggregateTable;

DELIMITER //

CREATE PROCEDURE pir_data.aggregateTable(
	IN agg_level VARCHAR(64)
)
BEGIN

	DECLARE suffix VARCHAR(10) DEFAULT '';
	DECLARE where_cond TEXT DEFAULT '';
	DECLARE tname TEXT DEFAULT '';
	DECLARE query_list TEXT DEFAULT '';
	DECLARE ind INT DEFAULT 0;
	
	-- Determine the suffix for the table name based on the aggregation level
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
	
	-- Set the table name
	SET tname = CONCAT('response', suffix);
	
	-- Get the where condition for the aggregation level
	SET where_cond = (SELECT aggregateWhereCondition(agg_level));

	-- Create the drop table query
	SET @drop_query = CONCAT(
		'DROP TABLE IF EXISTS ', tname
	);
	IF agg_level = "national" THEN
		-- Create the aggregation query for the national level
		SET @agg_query = CONCAT(
			'CREATE TABLE ', tname, ' AS '
			'SELECT `year`, question_id, min(answer) as `min`, avg(answer) as `mean`, max(answer) as `max`, std(answer) as `std`, ',
				'count(answer) as `count` ',
			'FROM response ',
			'GROUP BY `year`, question_id'
		);
	ELSE
		-- Create the aggregation query for the other levels
		SET @agg_query = CONCAT(
			'CREATE TABLE ', tname, ' AS '
			'SELECT ', agg_level, ', resp.year, question_id, min(answer) as `min`, avg(answer) as `mean`, max(answer) as `max`, std(answer) as `std`, ',
				'count(answer) as `count` ',
			'FROM response resp ',
			'LEFT JOIN program prg ',
			'ON resp.uid = prg.uid AND resp.year = prg.year ',
			'WHERE ', where_cond, ' ',
			'GROUP BY ', agg_level, ', resp.year, question_id '
			'ORDER BY ', agg_level, ', resp.year, question_id '
		);
	END IF;
	-- Create the index queries
	SET @index_qid = CONCAT(
		'CREATE INDEX ix_', tname, '_question_id ON ', tname, ' (question_id)'
	);
	SET @index_yr = CONCAT(
		'CREATE INDEX ix_', tname, '_year ON ', tname, ' (`year`)'
	);
	
	-- Combine all queries into a single string
	SET query_list = CONCAT(
		@drop_query, ';', @agg_query, ';', @index_qid, ';', @index_yr
	);
	
	-- Execute each query in the list
	SET ind = Locate(';', query_list) + 1;
	WHILE ind != 1 DO
		SET @extract = SUBSTRING_INDEX(query_list, ';', 1);
		SELECT @extract;
		PREPARE statement FROM @extract;
		EXECUTE statement;
		DEALLOCATE PREPARE statement;
		SET ind = Locate(';', query_list) + 1;
		SET query_list = TRIM(SUBSTR(query_list, ind));
	END WHILE;

END //

DELIMITER ;