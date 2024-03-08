
DROP VIEW IF EXISTS pir_question_links.distinct_linked_v;

-- Create or replace a view named distinct_linked_v in the pir_question_links schema
CREATE OR REPLACE VIEW pir_question_links.distinct_linked_v AS
-- Select all columns from the subquery aliased as 'a', and add the 'year' column from the 'new_questions' table as 'first_appearance'
SELECT a.*, b.`year` AS first_appearance
FROM (
	-- Select distinct records based on 'question_id' from the 'linked' table and alias it as 'a'
	SELECT DISTINCT question_id, question_name, question_text, question_number, category, section
    FROM linked
) a
-- Left join the subquery 'a' with the 'new_questions' table based on matching 'question_id'
LEFT JOIN new_questions b
ON a.question_id = b.question_id;
