
CREATE OR REPLACE VIEW pir_question_links.unlinked_v AS 

-- The SELECT statement retrieves data from the proposed_link table and processes JSON data using JSON_TABLE function.
SELECT b.*, a.`year`, c.question_name, c.question_text, c.question_number, c.section

-- The main source of data is the proposed_link table aliased as 'a'.
FROM pir_question_links.proposed_link a

-- The JSON_TABLE function is used to process JSON data stored in the 'proposed_link' column of the 'a' table.
JOIN JSON_TABLE(
    a.proposed_link,
    '$[*]' COLUMNS(
        NESTED PATH '$' COLUMNS(
            -- Columns are extracted from nested JSON arrays.
            question_id VARCHAR(100) PATH '$.question_id[*]',
            proposed_id VARCHAR(100) PATH '$.proposed_id[*]',
            question_name_dist INT PATH '$.question_name_dist[*]',
            question_text_dist INT PATH '$.question_text_dist[*]',
            question_number_dist INT PATH '$.question_number_dist[*]',
            section_dist INT PATH '$.section_dist[*]'
        )
    )
) b
-- The ON clause joins the 'b' result set with the 'a' table based on the 'question_id' column.
ON a.question_id = b.question_id

-- The LEFT JOIN retrieves data from the 'unlinked' table aliased as 'c', which contains information about unlinked questions.
LEFT JOIN (
    -- Subquery selects distinct columns from the 'unlinked' table.
    SELECT DISTINCT question_id, question_name, question_text, question_number, section
    FROM pir_question_links.unlinked
) c
-- The ON clause joins the 'c' result set with the 'a' table based on the 'question_id' column.
ON a.question_id = c.question_id;
