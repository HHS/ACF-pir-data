
CREATE OR REPLACE VIEW pir_question_links.inconsistent_question_id_v AS

-- Select distinct uqid values along with a flag indicating inconsistent question id.
SELECT DISTINCT a.uqid, 1 AS inconsistent_question_id
FROM pir_question_links.linked a

-- Join the 'linked' table with a subquery (aliased as 'c') that identifies uqid values with inconsistent question ids.
INNER JOIN (
    -- Select distinct uqid values along with their corresponding question ids and lagged question ids.
    SELECT DISTINCT uqid, question_id, lag(question_id) over (PARTITION BY uqid) as lag_question_id
    FROM pir_question_links.linked
) b

-- Filter the subquery results to include only rows where the lagged question id is not null and differs from the current question id.
WHERE b.lag_question_id IS NOT NULL AND b.lag_question_id != question_id

-- Join the main query with the subquery on the uqid column to identify inconsistent question id occurrences.
ON a.uqid = b.uqid;
