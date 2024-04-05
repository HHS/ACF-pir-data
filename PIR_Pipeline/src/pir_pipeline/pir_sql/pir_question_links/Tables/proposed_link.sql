DROP TABLE IF EXISTS pir_question_links.proposed_link;

-- Create the proposed_link table
CREATE TABLE pir_question_links.proposed_link AS
SELECT 
	question_id,
    `year`,
    -- Add question_id and proposed_id to the proposed_link JSON object
    pir_question_links.combineArray(
        JSON_KEYS(proposed_link), 
        pir_question_links.addQuestionID(
            JSON_EXTRACT(proposed_link, "$.*"), 
            question_id, 'question_id'
        ), 
        'proposed_id'
    ) as proposed_link
FROM pir_question_links.unlinked
;