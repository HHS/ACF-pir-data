-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: Get program-level data from the response table.
-- Parameters:
--  IN col TEXT - The column name to filter on. Must be a column in the response table.
--  IN val TEXT - The value of the column to filter on.
-- 	IN view_name VARCHAR(64) - The name of the view to be created. Specify NULL if no view is desired.
-- Returns: None
-- 	Optionally: View
-- Examples: 
-- 	CALL pir_data.getProgramLevelData('question_id', '4fbac59c868a7255a0acb42bd6e2ec54', NULL);
-- 	CALL pir_data.getProgramLevelData('question_id', '4fbac59c868a7255a0acb42bd6e2ec54', 'tot_cumul_enr_v');
-- =============================================
DROP PROCEDURE IF EXISTS pir_data.getProgramLevelData;

DELIMITER //

CREATE PROCEDURE pir_data.getProgramLevelData(
	IN col TEXT, 
    IN val TEXT,
    IN view_name VARCHAR(64)
)
BEGIN

	DECLARE where_cond TEXT DEFAULT '';
    
  -- Add 'response.' prefix to column name
  SET col = CONCAT(
    'response.', col
  );

  -- Create the WHERE condition for the query
	SET where_cond = CONCAT(
    'WHERE ', col, ' = ', QUOTE(val)
  );

-- Create the query to get program-level data based on the column filter
	SET @prg_query = CONCAT(
    '
    SELECT program.program_name, program.grant_number, program.program_number, program.program_type, response.question_id, response.answer, response.`year`
    FROM response
    LEFT JOIN pir_data.program program
    ON response.uid = program.uid AND response.year = program.year
    ',
    where_cond, ' ',
    'ORDER BY program.grant_number, program.program_number, program.program_type, response.year'
  );
    
    -- If view_name is specified, create a view
	IF (view_name IS NOT NULL) THEN
		SET @prg_query = CONCAT(
			'CREATE OR REPLACE VIEW ', view_name, ' AS ', @prg_query
        );
    END IF;
    
  -- Prepare and execute the query
  SELECT @prg_query;
  PREPARE statement FROM @prg_query;
  EXECUTE statement;
  DEALLOCATE PREPARE statement;

END //

DELIMITER ;