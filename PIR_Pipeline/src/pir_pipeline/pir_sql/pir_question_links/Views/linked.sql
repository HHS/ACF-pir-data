-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This view provides a list of questions that have been linked.
-- =============================================
DROP VIEW IF EXISTS pir_question_links.linked_v;

CREATE OR REPLACE VIEW linked_v AS
SELECT *
FROM pir_question_links.linked
;