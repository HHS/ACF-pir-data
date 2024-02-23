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
    
    SET tname = CONCAT('response', suffix);
    
    SET where_cond = (SELECT aggregateWhereCondition(agg_level));

	SET @drop_query = CONCAT(
		'DROP TABLE IF EXISTS ', tname
	);
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
    SET @index_qid = CONCAT(
		'CREATE INDEX ix_', tname, '_question_id ON ', tname, ' (question_id)'
    );
    SET @index_yr = CONCAT(
		'CREATE INDEX ix_', tname, '_year ON ', tname, ' (`year`)'
    );
    
    SET query_list = CONCAT(
		@drop_query, ';', @agg_query, ';', @index_qid, ';', @index_yr
    );
    
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