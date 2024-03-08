-- This stored procedure is designed to review unlinked questions in the 'pir_question_links' database.
-- The procedure takes one parameter 'qid' (question ID) of type VARCHAR(255).

DROP PROCEDURE IF EXISTS pir_question_links.reviewUnlinked; 
DELIMITER //

 -- Create a new stored procedure named 'reviewUnlinked' with one input parameter 'qid'.
CREATE PROCEDURE pir_question_links.reviewUnlinked(IN qid VARCHAR(255))
BEGIN
    -- The SELECT statement retrieves data about unlinked questions and their corresponding linked questions for comparison.
    SELECT a.*, 
        d.question_name AS base_question_name, -- Alias for the name of the base question.
        COALESCE(b.question_name, c.question_name) AS comparison_question_name, -- Alias for the name of the comparison question, handling NULL values.
        d.question_text AS base_question_text, -- Alias for the text of the base question.
        COALESCE(b.question_text, c.question_text) AS comparison_question_text, -- Alias for the text of the comparison question, handling NULL values.
        d.question_number AS base_question_number, -- Alias for the number of the base question.
        COALESCE(b.question_number, c.question_number) AS comparison_question_number, -- Alias for the number of the comparison question, handling NULL values.
        d.section AS base_section, -- Alias for the section of the base question.
        COALESCE(b.section, c.section) AS comparison_section, -- Alias for the section of the comparison question, handling NULL values.
        d.`year` AS base_year, -- Alias for the year of the base question.
        COALESCE(b.`year`, c.`year`) AS comparison_year -- Alias for the year of the comparison question, handling NULL values.
    FROM (
        -- Subquery to retrieve unlinked questions based on the provided question ID.
        SELECT *
        FROM unlinked_v
        WHERE question_id = qid
    ) a
    LEFT JOIN (
        -- Subquery to retrieve linked questions and their corresponding years.
        SELECT DISTINCT question_id, question_name, question_text, question_number, section, JSON_ARRAYAGG(`year`) OVER (PARTITION BY question_id) AS `year`
        FROM linked
    ) b
    ON a.proposed_id = b.question_id -- Join condition based on proposed ID.
    LEFT JOIN (
        -- Subquery to retrieve unlinked questions and their corresponding years.
        SELECT DISTINCT question_id, question_name, question_text, question_number, section, JSON_ARRAYAGG(`year`) OVER (PARTITION BY question_id) AS `year`
        FROM unlinked 
    ) c
    ON a.proposed_id = c.question_id -- Join condition based on proposed ID.
    LEFT JOIN (
        -- Subquery to retrieve base questions and their corresponding years.
        SELECT DISTINCT question_id, question_name, question_text, question_number, section, JSON_ARRAYAGG(`year`) OVER (PARTITION BY question_id) AS `year`
        FROM unlinked 
    ) d
    ON a.question_id = d.question_id; -- Join condition based on question ID.
END //

DELIMITER ;
