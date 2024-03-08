
DROP VIEW IF EXISTS pir_question_links.linked_v;

-- Create or replace the view 'linked_v'.
CREATE OR REPLACE VIEW linked_v AS
-- Select all columns from the table 'pir_question_links.linked'.
SELECT *
FROM pir_question_links.linked;
