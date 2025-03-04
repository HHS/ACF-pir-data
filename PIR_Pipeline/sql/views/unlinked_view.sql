-- =============================================
-- Author:      Reggie Gilliard
-- Create date: 03/01/2024
-- Description: This view provides a list of questions that have not been linked.
-- =============================================

CREATE OR REPLACE VIEW pir.unlinked AS
SELECT *
FROM question
WHERE uqid IS NULL
;