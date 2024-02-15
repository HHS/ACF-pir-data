CREATE DATABASE IF NOT EXISTS `question_links`;
use `question_links`;

CREATE TABLE `linked` (
	uqid varchar(255), 
	`year` year, 
	question_id varchar(255), 
	question_name TEXT, 
	question_text TEXT, 
	question_number varchar(55), 
	category varchar(255),
	section varchar(2),
	PRIMARY KEY (uqid, `year`, `question_id`)
);
CREATE INDEX ix_linked_uqid ON linked (uqid);
CREATE INDEX ix_linked_year ON linked (`year`);
CREATE INDEX ix_linked_question_id ON linked (question_id);

CREATE TABLE `unlinked` (
	`year` year, 
	question_id varchar(255), 
	question_name TEXT, 
	question_text TEXT, 
	question_number varchar(55), 
	category varchar(255),
	section varchar(2),
	proposed_link TEXT,
	PRIMARY KEY (question_id, `year`)
);
CREATE INDEX ix_unlinked_year ON unlinked (`year`);
CREATE INDEX ix_unlinked_question_id ON unlinked (question_id);

CREATE TABLE `new_questions` (
	`year` year, 
	question_id varchar(255), 
	question_name TEXT, 
	question_text TEXT, 
	question_number varchar(55), 
	category varchar(255),
	section varchar(2),
	PRIMARY KEY (question_id, `year`)
);
CREATE INDEX ix_new_questions_year ON new_questions (`year`);
CREATE INDEX ix_new_questions_question_id ON new_questions (question_id);