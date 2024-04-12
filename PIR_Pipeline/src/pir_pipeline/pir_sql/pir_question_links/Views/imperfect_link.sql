-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This view provides a list of questions that have inconsistent question IDs or intermittent links.
-- =============================================

CREATE OR REPLACE VIEW pir_question_links.imperfect_link_v AS
SELECT DISTINCT pir_question_links.linked.uqid, inconsistent.inconsistent_question_id, intermittent.intermittent_link
FROM pir_question_links.linked 
LEFT JOIN pir_question_links.inconsistent_question_id_v inconsistent
ON pir_question_links.linked.uqid = inconsistent.uqid
LEFT JOIN pir_question_links.intermittent_link_v intermittent
ON pir_question_links.linked.uqid = intermittent.uqid
WHERE inconsistent.inconsistent_question_id IS NOT NULL OR intermittent.intermittent_link IS NOT NULL
;