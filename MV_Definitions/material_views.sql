use pir_data;

drop table if exists mv_staffing_counts;

create table
	mv_staffing_counts as
select
	response.`year`,
	question.question_name,
	program.program_state,
	program.program_type,
	SUM(response.answer) as answer
from
	response
	left join question on response.question_id = question.question_id
	and response.`year` = question.`year`
	left join program on response.uid = program.uid
	and response.`year` = program.`year`
where
	response.question_id in (
		"3722754821cb16339f7dd7613a0f9aee", -- Total Contracted Parent Staff
		"5d7884f8e8f8735b3fc1d3d4426b68c2", -- Total Head Start Staff
		"862cf4c97a3e31652bbd1a67c0c7b25e", -- Total Contracted Staff
		"b9d40068777efa56512992700f548b11" -- Total Head Start Parent Staff
	) 
group by
	response.`year`,
	question.question_name,
	program.program_state,
	program.program_type;

drop table if exists mv_children_by_age_counts;

create table
	mv_children_by_age_counts as
select
	response.`year`,
	question.question_name,
	program.program_state,
	program.program_type,
	SUM(response.answer) as answer
from
	response
	left join question on response.question_id = question.question_id
	and response.`year` = question.`year`
	left join program on response.uid = program.uid
	and response.`year` = program.`year`
where
	response.question_id in (
		"202dc96ac25d827401c0b2577ee3c5e7", -- 5 Years and Older
		"c1f6cb313596d9940095898d66d52663", -- 5 Years and Older
		"2f10e44347be1ba01514e68decae0803", -- 5 Years and Older
		"d9e009441a37c599a26714514f46a021", -- 4 Years Old
		"cc71392611eec15a7d80b30a4bd665b1", -- 4 Years Old
		"59c88c09ec082ff30d9a69801362c436", -- 4 Years Old
		"9e17c6e383922330d5a59e051c25370f", -- 3 Years Old
		"98158bb5138a55d9701ea6cdac3ae25b", -- 3 Years Old
		"551701cbe5a2f0a7ad933c3818dc4cd0", -- 3 Years Old
		"ac33cc4858ad43c3e939fa25e4d185c7", -- 2 Years Old
		"7a3d70f4cedcde470e37cd0ef3a4274d", -- 2 Years Old
		"2cc8886b9e2c0db9f51c7ac33f7d61ae", -- 2 Years Old
		"bb3ae20db8c1f504b184fa92423df0ab", -- 1 Year Old
		"54e0dca6c7070902c5750285ac7f2535", -- 1 Year Old
		"19dc665526fd8b4e253214a1bcfb1da8", -- 1 Year Old
		"f9d7a0aa9625b7f0cdff6600cf04ca66", -- Less than 1 Year Old
		"bae5e02ba246ccc54798351f4616c648", -- Less than 1 Year Old
		"5b4f53b70ddbca37ff42b8760e11c186" -- Less than 1 Year Old
	) 
group by
	response.`year`,
	question.question_name,
	program.program_state,
	program.program_type;

drop table if exists mv_eligibility_counts;

create table
	mv_eligibility_counts as
select
	response.`year`,
	question.question_name,
	program.program_state,
	program.program_type,
	SUM(response.answer) as answer
from
	response
	left join question on response.question_id = question.question_id
	and response.`year` = question.`year`
	left join program on response.uid = program.uid
	and response.`year` = program.`year`
where
	response.question_id in (
		"922d7e5bcd1f5d752b35fcd798bf3425", -- Eligibility based on other type of need, but not counted in A.13.a through d
		"45c3df5ba0930ae4729439b0d9dd67e5", -- Foster Children
		"617ee969967b6e0601ae621816b7f29b", -- Foster Children
		"aa655709b12467aca7e7f51ea802f8c3", -- Foster Children
		"3af12ac823d4bfe70adb57c950f2b456", -- Homeless Children
		"908f104f14efce8151382321786fd437", -- Homeless Children
		"e7b4c41d43f66bfd7dea122b700bf057", -- Homeless Children
		"3fe09ba27976b31f172d47c3568bc5fc", -- Income between 100% and 130% of Poverty
		"5905ac7336287b034eb8b320ed29eee3", -- Income between 100% and 130% of Poverty
		"c128e31d09e25c0113603a9d7de3ee96", -- Income between 100% and 130% of Poverty
		"30a5c32a84299df26b9245378049fa35", -- Income Eligibility
		"5812d676622ee3118094fdfccc96bd8c", -- Income Eligibility
		"7a9498c8f5b5c73a06bb785894809884", -- Income Eligibility
		"8448e8b0680817ea990b5b2afd52d86e", -- Incomes between 100% and 130% of the federal poverty line, but not counted in A.13.a through e
		"59996dea6d6a2cd140aaf9da2ad64786", -- Over Income
		"7aaf58f012a1cf1aa553903cf202f62c", -- Over Income
		"dbc86979bd8875a207ba1596de984ca3", -- Over Income
		"1ecac19880e4cf5731d86d457cb21c28", -- Primary type of documentation for eligibility - Eligibility based on other type of need, but not counted in A.13.a thorugh d (commonly referred to as over-income)
		"2c1ce8ec67a60b78ff64d79c69770de9", -- Primary type of documentation for eligibility - Foster care
		"62d752410d073694b362aa84bf9d6845", -- Primary type of documentation for eligibility - Homeless
		"4a44c035d1625ff9fa4ca024c2b8bc9f", -- Primary type of documentation for eligibility - Income at or below 100% of federal poverty line
		"490a7567bf1eed2f0398974cd81ef49c", -- Primary type of documentation for eligibility - Incomes between 100% and 130% of the federal poverty line, but not counted in A.13.a through e
		"ed6b96cbff1879ddf1624054a1e89873", -- Primary type of documentation for eligibility - Public assistance
		"4709328fa6f7c4684c41198d246c2f41", -- Receipt of Public Assistance
		"6bee1123e7d364c046fd8b529d744dd8", -- Receipt of Public Assistance
		"c719f1b9e9bad9b8209f880426eb2ff9" -- Receipt of Public Assistance
	)
group by
	response.`year`,
	question.question_name,
	program.program_state,
	program.program_type;
    