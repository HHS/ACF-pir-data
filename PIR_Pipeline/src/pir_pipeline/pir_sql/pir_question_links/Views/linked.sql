-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This view provides a list of questions that have been linked.
-- =============================================
CREATE OR REPLACE VIEW pir_question_links.linked_v AS
SELECT *
FROM pir_question_links.linked
;