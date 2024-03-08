
CREATE OR REPLACE VIEW pir_question_links.intermittent_link_v AS

-- Select distinct uqid from the linked table aliased as 'a' and assign a constant value of 1 to intermittent_link
SELECT DISTINCT a.uqid, 1 AS intermittent_link

-- Perform a right join between the linked table aliased as 'a' and a subquery aliased as 'b'
FROM pir_question_links.linked a

-- Subquery 'b' selects uqid from the linked table and groups them by uqid, then filters the groups based on year conditions
RIGHT JOIN (
    SELECT uqid
    FROM pir_question_links.linked
    GROUP BY uqid
    HAVING min(year) != pir_question_links.minYearLinked() AND max(year) != pir_question_links.maxYearLinked()
) b

-- Join condition: uqid from table 'a' must match uqid from subquery 'b'
ON a.uqid = b.uqid

-- Order the result set by uqid
ORDER BY uqid;
