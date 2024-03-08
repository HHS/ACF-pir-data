-- Drop the stored procedure if it exists to avoid conflicts
DROP PROCEDURE IF EXISTS pir_data.aggregateView;

-- Change the delimiter temporarily
DELIMITER //

-- Create the stored procedure 'aggregateView' in the 'pir_data' database
CREATE PROCEDURE pir_data.aggregateView(
    IN view_name VARCHAR(64), IN agg_level VARCHAR(64),
    IN question_id VARCHAR(64), IN kind VARCHAR(12)
)
BEGIN

    -- Declare variables to be used in the procedure
    DECLARE suffix VARCHAR(10) DEFAULT '';
    DECLARE where_cond TEXT DEFAULT '';

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
        SET SUFFIX = '_national';
    END IF;

    -- Set the WHERE condition based on the aggregation level
    SET where_cond = (SELECT aggregateWhereCondition(agg_level));

    -- Construct the query for different kinds of aggregation
    IF kind = 'uqid' THEN
        SET @question_query = CONCAT(
            'FROM response resp ',
            'INNER JOIN (',
                'SELECT DISTINCT question_id ',
                'FROM pir_question_links.linked a ',
                'INNER JOIN (',
                    'SELECT DISTINCT uqid ',
                    'FROM pir_question_links.linked ',
                    'WHERE question_id = ', QUOTE(question_id),
                ') b ON a.uqid = b.uqid',
            ') c ON resp.question_id = c.question_id ',
            'LEFT JOIN program prg ON resp.uid = prg.uid AND resp.`year` = prg.`year` '
        );
    ELSE
        SET @question_query = CONCAT(
            'FROM (',
                'SELECT * FROM response',
                'WHERE question_id = ', QUOTE(question_id),
            ') resp ',
            'LEFT JOIN program prg ON resp.uid = prg.uid AND resp.`year` = prg.`year` '
        );
    END IF;

    -- Construct the aggregation query based on the aggregation level
    IF agg_level = "national" THEN
        SET @agg_query = CONCAT(
            'CREATE OR REPLACE VIEW ', view_name, suffix, ' AS ',
            'SELECT min(resp.`year`) as year, min(answer) as `min`, avg(answer) as `mean`, max(answer) as `max`, std(answer) as `std`, ',
            'count(answer) as `count` ',
            @question_query
        );
    ELSE
        SET @agg_query = CONCAT(
            'CREATE OR REPLACE VIEW ', view_name, suffix, ' AS ',
            'SELECT ', agg_level, ', min(resp.`year`) as year, min(answer) as `min`, avg(answer) as `mean`, max(answer) as `max`, std(answer) as `std`, ',
            'count(answer) as `count` ',
            @question_query,
            'WHERE ', where_cond, ' ',
            'GROUP BY ', agg_level,
            ' ORDER BY ', agg_level
        );
    END IF;

    -- Prepare and execute the aggregation query
    select @agg_query; -- Print the generated query for debugging purposes
    PREPARE view_statement FROM @agg_query;
    EXECUTE view_statement;
    DEALLOCATE PREPARE view_statement;

END //

-- Reset the delimiter
DELIMITER ;
