-- Exhibit 4
select uqid, year, question_id, question_name, question_text, question_number
from (
	select 
		*, 
        lag(question_number) over (
			partition by uqid
            order by uqid, year, question_id
		) as lag_qnum,
        lead(question_number) over (
			partition by uqid
            order by uqid, year, question_id
		) as lead_qnum
	from linked
) a
where (question_number != lag_qnum OR question_number != lead_qnum) AND uqid NOT IN (
	select a.uqid
	from linked a
	inner join (
		select distinct uqid, count(uqid) as count
		from linked
		group by `year`, uqid
		having count > 1
	) b
	on a.uqid = b.uqid
)
;