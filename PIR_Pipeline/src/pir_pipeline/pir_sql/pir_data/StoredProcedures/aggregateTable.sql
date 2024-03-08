-- This stored procedure is designed to aggregate data from the "response" table based on the specified aggregation level.

-- Parameters:
--   - agg_level: Specifies the aggregation level (e.g., 'state', 'type', 'region', 'grant', 'national')

DROP PROCEDURE IF EXISTS pir_data.aggregateTable;

-- Change the delimiter temporarily
DELIMITER //

CREATE PROCEDURE pir_data.aggregateTable(
    IN agg_level VARCHAR(64)
)
BEGIN
    -- Declare variables for suffix, WHERE condition, table name, query list, and index
    DECLARE suffix VARCHAR(10) DEFAULT '';
    DECLARE where_cond TEXT DEFAULT '';
    DECLARE tname TEXT DEFAULT '';
    DECLARE query_list TEXT DEFAULT '';
    DECLARE ind INT DEFAULT 0;

    -- Determine the suffix based on the aggregation level provided
    IF agg_level REGEXP 'state' THEN
        SET suffix = '_state';
    ELSEIF agg_level REGEXP 'type' THEN
        SET suffix = '_type';
    ELSEIF agg_level REGEXP 'region' THEN
        SET suffix = '_region';
    ELSEIF agg_level REGEXP 'grant' THEN
        SET suffix = '_grant';
    ELSE
        SET suffix = '_national';
    END IF;

    -- Construct the table name using the suffix
    SET tname = CONCAT('response', suffix);

    -- Get the WHERE condition based on the aggregation level
    SET where_cond = (SELECT aggregateWhereCondition(agg_level));

    -- Construct the DROP TABLE query
    SET @drop_query = CONCAT(
        'DROP TABLE IF EXISTS ', tname
    );

    -- Construct the aggregation query based on the aggregation level
    IF agg_level = "national" THEN
        SET @agg_query = CONCAT(
            'CREATE TABLE ', tname, ' AS '
            'SELECT `year`, question_id, min(answer) as `min`, avg(answer) as `mean`, max(answer) as `max`, std(answer) as `std`, ',
                'count(answer) as `count` ',
            'FROM response ',
            'GROUP BY `year`, question_id'
        );
    ELSE
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

    -- Construct the index creation queries for question_id and year
    SET @index_qid = CONCAT(
        'CREATE INDEX ix_', tname, '_question_id ON ', tname, ' (question_id)'
    );
    SET @index_yr = CONCAT(
        'CREATE INDEX ix_', tname, '_year ON ', tname, ' (`year`)'
    );

    -- Concatenate all queries into a single list
    SET query_list = CONCAT(
        @drop_query, ';', @agg_query, ';', @index_qid, ';', @index_yr
    );

    -- Iterate through the query list, executing each query
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

-- Reset the delimiter 
DELIMITER ;