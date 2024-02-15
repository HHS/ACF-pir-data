CREATE OR REPLACE VIEW imperfect_link_v AS
SELECT DISTINCT a.uqid, b.inconsistent_question_id, c.intermittent_link
FROM linked a
LEFT JOIN inconsistent_question_id_v b
ON a.uqid = b.uqid
LEFT JOIN intermittent_link_v c
ON a.uqid = c.uqid
WHERE b.inconsistent_question_id IS NOT NULL OR c.intermittent_link IS NOT NULL
;