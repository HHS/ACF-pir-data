-- The view selects distinct values of uqid, inconsistent_question_id, and intermittent_link.

CREATE OR REPLACE VIEW pir_question_links.imperfect_link_v AS

-- The following query retrieves data from the linked table and two other views: inconsistent_question_id_v and intermittent_link_v.

SELECT DISTINCT 
    a.uqid, 
    b.inconsistent_question_id, 
    c.intermittent_link

FROM 
    pir_question_links.linked a

-- Left join with the inconsistent_question_id_v view based on the uqid column.
LEFT JOIN 
    pir_question_links.inconsistent_question_id_v b
ON 
    a.uqid = b.uqid

-- Left join with the intermittent_link_v view based on the uqid column.
LEFT JOIN 
    pir_question_links.intermittent_link_v c
ON 
    a.uqid = c.uqid

-- Filters out rows where either inconsistent_question_id or intermittent_link is NULL.
WHERE 
    b.inconsistent_question_id IS NOT NULL OR c.intermittent_link IS NOT NULL
;
