-- Exhibit 3
select uqid, year, question_id, question_name, question_text, question_number
from (
	select 
		*, 
        lag(question_text) over (
			partition by uqid
            order by uqid, year, question_id
		) as lag_qtext,
        lead(question_text) over (
			partition by uqid
            order by uqid, year, question_id
		) as lead_qtext
	from linked
) a
where question_text != lag_qtext OR question_text != lead_qtext
;