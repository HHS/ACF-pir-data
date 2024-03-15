DROP VIEW IF EXISTS pir_question_links.linked_v;

CREATE OR REPLACE VIEW linked_v AS
SELECT *
FROM pir_question_links.linked
;