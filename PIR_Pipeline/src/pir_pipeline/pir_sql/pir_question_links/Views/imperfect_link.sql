-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This view provides a list of questions that have inconsistent question IDs or intermittent links.
-- =============================================

CREATE OR REPLACE VIEW pir_question_links.imperfect_link_v AS
SELECT DISTINCT a.uqid, b.inconsistent_question_id, c.intermittent_link
FROM pir_question_links.linked a
LEFT JOIN pir_question_links.inconsistent_question_id_v b
ON a.uqid = b.uqid
LEFT JOIN pir_question_links.intermittent_link_v c
ON a.uqid = c.uqid
WHERE b.inconsistent_question_id IS NOT NULL OR c.intermittent_link IS NOT NULL
;