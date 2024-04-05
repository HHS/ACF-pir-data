-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This stored procedure queries the program and response tables to get program-level data based on a column filter.
-- Parameters:
--  IN col TEXT - The column name to filter on. Must be a column in the response table.
--  IN val TEXT - The value of the column to filter on.
-- Returns: None
-- Example: CALL pir_data.getProgramLevelData('question_id', '4fbac59c868a7255a0acb42bd6e2ec54');
-- =============================================
DROP PROCEDURE IF EXISTS pir_data.getProgramLevelData;

DELIMITER //

CREATE PROCEDURE pir_data.getProgramLevelData(
	IN col TEXT, IN val TEXT
)
BEGIN

	DECLARE where_cond TEXT DEFAULT '';
    
  -- Add 'resp.' prefix to column name
  SET col = CONCAT(
    'resp.', col
  );

  -- Create the WHERE condition for the query
	SET where_cond = CONCAT(
    'WHERE ', col, ' = ', QUOTE(val)
  );

-- Create the query to get program-level data based on the column filter
	SET @prg_query = CONCAT(
    '
    SELECT prg.program_name, prg.grant_number, prg.program_number, prg.program_type, resp.question_id, resp.answer, resp.`year`
    FROM pir_data.response resp
    LEFT JOIN pir_data.program prg
    ON resp.uid = prg.uid AND resp.year = prg.year
    ',
    where_cond, ' ',
    'ORDER BY prg.grant_number, prg.program_number, prg.program_type, resp.year'
  );
    
  -- Prepare and execute the query
  SELECT @prg_query;
  PREPARE statement FROM @prg_query;
  EXECUTE statement;
  DEALLOCATE PREPARE statement;

END //

DELIMITER ;