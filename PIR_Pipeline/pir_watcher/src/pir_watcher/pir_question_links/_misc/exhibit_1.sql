-- Exhibit 1
select a.*
from linked a
inner join (
	select distinct uqid, count(uqid) as count
	from linked
	group by `year`, uqid
	having count > 1
) b
on a.uqid = b.uqid
;