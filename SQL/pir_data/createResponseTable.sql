DELIMITER //

CREATE PROCEDURE createResponseTable(IN `response_year` YEAR)
BEGIN

	SET @table_name = CONCAT('response', response_year);
	SET @response_query = CONCAT(
		'CREATE TABLE IF NOT EXISTS `', @table_name, '` (
			`uid` varchar(255),
			`question_id` varchar(255),
			`answer` TEXT,
			`year` YEAR,
			PRIMARY KEY (`uid`, `question_id`)
		)'
	);
	SET @program_query = CONCAT(
		'ALTER TABLE `', @table_name, '` 
		ADD FOREIGN KEY (`uid`, `year`) 
		REFERENCES `Program` (`uid`, `year`)
		'
	);
	SET @question_query = CONCAT(
		'ALTER TABLE `', @table_name, '` 
		ADD FOREIGN KEY (`question_id`, `year`) 
		REFERENCES `Question` (`question_id`, `year`)
		'
	);
	PREPARE response_stmt FROM @response_query;
	PREPARE program_stmt FROM @program_query;
	PREPARE question_stmt FROM @question_query;

	EXECUTE response_stmt;
	EXECUTE program_stmt;
	EXECUTE question_stmt;

	DEALLOCATE PREPARE response_stmt;
	DEALLOCATE PREPARE program_stmt;
	DEALLOCATE PREPARE question_stmt;
END //
DELIMITER ;