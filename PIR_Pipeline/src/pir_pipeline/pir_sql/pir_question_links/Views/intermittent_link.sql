-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This view provides a list of questions that have intermittent links.
-- =============================================

CREATE OR REPLACE VIEW pir_question_links.intermittent_link_v AS
WITH
intermittent AS (
    SELECT uqid
    FROM pir_question_links.linked
    GROUP BY uqid
    HAVING min(year) != pir_question_links.minYearLinked() and max(year) != pir_question_links.maxYearLinked()
)
SELECT DISTINCT pir_question_links.linked.uqid, 1 AS intermittent_link
FROM pir_question_links.linked
RIGHT JOIN intermittent
ON pir_question_links.linked.uqid = intermittent.uqid
ORDER BY uqid
;