-- Drop the table if it already exists to avoid conflicts.
DROP TABLE IF EXISTS pir_question_links.proposed_link;

-- Create a new table named proposed_link in the pir_question_links database.
CREATE TABLE pir_question_links.proposed_link AS

-- Select data from the unlinked table in the pir_question_links database.
SELECT 
	question_id,                    -- Select the question_id column from the unlinked table.
    `year`,                         -- Select the year column from the unlinked table.

    -- Combine arrays of JSON keys extracted from the proposed_link column with the question_id column added to each element.
    pir_question_links.combineArray(
        JSON_KEYS(proposed_link),                              -- Extract JSON keys from the proposed_link column.
        pir_question_links.addQuestionID(                       -- Add question_id to each JSON key.
            JSON_EXTRACT(proposed_link, "$.*"),                -- Extract each JSON value.
            question_id,                                        -- Pass the question_id.
            'question_id'                                       -- Name the added key as 'question_id'.
        ), 
        'proposed_id'                                           -- Name the combined array as 'proposed_id'.
    ) as proposed_link                                          -- Alias the combined array as 'proposed_link'.
    
-- Perform the above operations for each row in the unlinked table.
FROM pir_question_links.unlinked;
