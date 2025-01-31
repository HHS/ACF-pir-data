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

drop table if exists mv_race_ethnicity_counts;

create table
	mv_race_ethnicity_counts as
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
		"334f34de03b1fab8daaa94768e317055", -- American Indian/Alaska Native
		"7e450d0f527cf012fb8856908a637eb8", -- American Indian/Alaska Native
		"80b618ad5fcda27aeca5523ed906b981", -- American Indian/Alaska Native
		"adb51179718ab5e741076cc0f393cb7b", -- American Indian/Alaska Native
		"ebc1325e649f3fb822012444dc5d4708", -- American Indian/Alaska Native - Hispanic or Latino origin
		"0bccc3dff75644744e1143b99b10ceeb", -- American Indian/Alaska Native - Non-Hispanic or Non-Latino origin
		"259ddc565bb0435a96cd6b230eced95b", -- Asian
		"2ff01f908520b7edabc2f214ea2c7027", -- Asian
		"35f050b0620ab406597520e6b1604f81", -- Asian
		"721850595082e3ac31bad34af891255a", -- Asian
		"7581ea65dc41f28e315de5badd296b74", -- Asian - Hispanic or Latino origin
		"c8aed7708cd5a0e1720213d12d761e9c", -- Asian - Non-Hispanic or Non-Latino origin
		"442a69db5643870f6f66174a81e23712", -- Biracial or Multi-Racial
		"899674343b13424851965babb532419f", -- Biracial or Multi-Racial
		"a6a0a8cebeff9ea49c61212d50506045", -- Biracial or Multi-Racial
		"e0608e227075f65aa42b9ce224c9ec80", -- Biracial or Multi-Racial
		"ec0e6f5aa685459235f036fb1c38100c", -- Biracial or Multi-Racial - Hispanic or Latino origin
		"bac96b312080f184172035a092b6420a", -- Biracial or Multi-Racial - Non-Hispanic or Non-Latino origin
		"0ef77fa5d1baf76ee61e3dad5ae35c24", -- Black or African American
		"664497236ed281d56cd68c0de44fe955", -- Black or African American
		"7b89620d2cc00e3bd3c347d7d4b9cc69", -- Black or African American
		"be702f0cd1896c56e625eec5b50bd7d8", -- Black or African American
		"4f037f5037551d63db2c8873b2f39e61", -- Black or African American - Hispanic or Latino origin
		"97d70a275220f81662c1e1f34420aa8e", -- Black or African American - Non-Hispanic or Non-Latino origin
		"0fe4fd93da5126ac18d3665838f25ea1", -- Hispanic or Latino Origin
		"45f7acd064e4b3e015b8326db32af3b8", -- Hispanic or Latino Origin
		"835d6cab970c2eecc29720e473bc8e01", -- Hispanic or Latino Origin
		"957969b0c62308313b8826c7d876274f", -- Hispanic or Latino Origin
		"274125dc419b8d6f193ab34cf66954d8", -- Native Hawaiian/Pacific Islander
		"7af5cee74fc433229e6bfb96f86dc86c", -- Native Hawaiian/Pacific Islander
		"7c9a349be011f525cf0c216a4fb39b22", -- Native Hawaiian/Pacific Islander
		"eb411cdef421965940c5ff2f06245d90", -- Native Hawaiian/Pacific Islander
		"2ea5306ef01b86fe40a03c5791b63068", -- Native Hawaiian/Pacific Islander - Hispanic or Latino origin
		"d9713b02e0acc4fd58e07b21ab663916", -- Native Hawaiian/Pacific Islander - Non-Hispanic or Non-Latino origin
		"292d359a9077f5313d1ca8f0116d0d34", -- Other Race
		"2fcfece4f82f79a9147432232cd4dbee", -- Other Race
		"cd15f505ec1c244ffff8c65ef98c7460", -- Other Race
		"ce593a9df20483401f482462c0a01b33", -- Other Race
		"f9fd10b3edb0e28b013b37b3df996f9a", -- Other Race - Hispanic or Latino origin
		"b035ca5990959a6edbfbf4cb7433fa9f", -- Other Race - Non-Hispanic or Non-Latino origin
		"6cfeb8631fbad64ecf6334a1e19c0b06", -- White
		"82fd92aff9a3b9d118667cd5282afe73", -- White
		"9c30539bbbeafa7ff8339ce23048bcd3", -- White
		"ac69401c182fa077af054f2eb1f4ccd7", -- White
		"72f7e808ed397b2c3c5a44abf7c70826", -- White - Hispanic or Latino origin
		"d34f71c1ea0fa35cbfb0eff09d1b6082" -- White - Non-Hispanic or Non-Latino origin
	)
group by
	response.`year`,
	question.question_id, -- for cleaning in Tableau
	question.question_name,
	program.program_state,
	program.program_type;

drop table if exists mv_teacher_qual_counts;

create table
	mv_teacher_qual_counts as
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
		"8a3b01c962afd744cb40e04bec6db092", -- A baccalaureate degree in early childhood education, any field and coursework equivalent to a major relating to early childhood education with experience teaching preschool-age children, or any field and is part of the Teach for America program and passed a rigorous early childhood content exam - Classroom Teachers
		"fce9916509357801ff8b20ecc5a86d0a", -- A baccalaureate degree in early childhood education, any field and coursework equivalent to a major relating to early childhood education with experience teaching preschool-age children, or any field and is part of the Teach for America program and passed a rigorous early childhood content exam - Classroom Teachers
		"4f33a647901ef815541489be1c45d98d", -- A Child Development Associate (CDA) credential or state-awarded certification, credential, or licensure that meets or exceeds CDA requirements - Classroom Teachers
		"4b303dc2d927fa36669167ebd108be35", -- Advanced Degree Classroom Teachers
		"f96b44b6179da17a5dde10d11865cf1a", -- Advanced Degree in Any Related Field - Classroom Teachers
		"05562101247a0239137d7920c07398e8", -- Advanced Degree in Any Related Field - Preschool Classroom Teachers
		"c8da3f38e5e069dbd9ad54f12eb86379", -- Advanced Degree in ECE - Classroom Teachers
		"902ebc2fd3e6cce55a4b6850bb1321aa", -- Advanced Degree in ECE - Preschool Classroom Teachers
		"2bdf3cae3fe7ca779bf07666f60e5840", -- An Advanced degree in early childhood education or any field and coursework equivalent to a major relating to early childhood education, with experience teaching preschool-age children - Classroom Teachers
		"7dd304b105b5de568543d01ea096fc7d", -- An Advanced degree in early childhood education or any field and coursework equivalent to a major relating to early childhood education, with experience teaching preschool-age children - Classroom Teachers
		"264f740cb9d003954d3cc29d4831b507", -- An associate degree in early childhood education or a field related to early childhood education and coursework equivalent to a major relating to early childhood education with experience teaching preschool-age children - Classroom Teachers
		"db86ef0a61ce11c94046d58a2e072409", -- An associate degree in early childhood education or a field related to early childhood education and coursework equivalent to a major relating to early childhood education with experience teaching preschool-age children - Classroom Teachers
		"cc2fcd60facf755613426840eaa317b2", -- Associate Degree Classroom Teachers
		"bb510f185313c5b5548c57005a2bbbae", -- Associate Degree in Any Related Field - Classroom Teachers
		"cb61946796561ec7a6d4d3684e046c64", -- Associate Degree in Any Related Field - Preschool Classroom Teachers
		"7402ff8a88daa654ad662378dca3a811", -- Associate Degree in ECE - Classroom Teachers
		"094cd70cda320265ba85d53773288a64", -- Associate Degree in ECE - Preschool Classroom Teachers
		"f2daefe80e8b543f9fbcc76b1bcf35b8", -- Baccalaureate Degree Classroom Teachers
		"34ee8d5acb53673833e1d0f9b8e2aee0", -- Baccalaureate Degree in Any Related Field - Classroom Teachers
		"7f5f0045b70033e66431579103b7ea2e", -- Baccalaureate Degree in Any Related Field - Preschool Classroom Teachers
		"373ef01ad92e37c4ec9e84c46a676fda", -- Baccalaureate Degree in ECE - Classroom Teachers
		"7310fc2ba014c1e0396bdfc1fb6ba095", -- Baccalaureate Degree in ECE - Preschool Classroom Teachers
		"9c25361865086b5007f3546e31211d9b", -- CDA Classroom Teachers
		"4c507f1939533c3a67e7f5a865705b92", -- Child Development Associate (CDA) - Classroom Teachers
		"577c84d8e7242c10e66ab624069f0a2e", -- Child Development Associate (CDA) - Preschool Classroom Teachers
		"dbc3ca1c3a830ebd1719c6f6c57aa56b", -- No Credential - Classroom Teachers
		"58e0ab10ae3eb0f3609d3d93d9f664bc", -- No ECE Credential - Preschool Classroom Teachers
		"77c02252c376a9f7d12de63256805a5b", -- None of the qualifications listed in B.3.a through B.3.d  - Classroom Teachers
		"13bb48f30d145b35a1442ca33ab22dd3", -- Unqualified Classroom Teachers
	)
group by
	response.`year`,
	question.question_id, -- for cleaning in Tableau
	question.question_name,
	program.program_state,
	program.program_type;