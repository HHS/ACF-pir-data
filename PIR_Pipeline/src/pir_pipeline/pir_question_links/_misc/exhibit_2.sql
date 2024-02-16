-- Exhibit 2
select uqid, year, question_id, question_name, question_text, question_number
from (
	select 
		*, 
        lag(question_name) over (
			partition by uqid
            order by uqid, year, question_id
		) as lag_qname,
        lead(question_name) over (
			partition by uqid
            order by uqid, year, question_id
		) as lead_qname
	from linked
) a
where question_name != lag_qname OR question_name != lead_qname
;