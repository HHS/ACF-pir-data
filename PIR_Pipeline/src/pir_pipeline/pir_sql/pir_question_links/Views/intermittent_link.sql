CREATE OR REPLACE VIEW pir_question_links.intermittent_link_v AS
SELECT DISTINCT a.uqid, 1 AS intermittent_link
FROM pir_question_links.linked a
RIGHT JOIN (
    SELECT uqid
    FROM pir_question_links.linked
    GROUP BY uqid
    HAVING min(year) != pir_question_links.minYearLinked() and max(year) != pir_question_links.maxYearLinked()
) b
ON a.uqid = b.uqid
ORDER BY uqid
;