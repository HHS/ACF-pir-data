CREATE DATABASE IF NOT EXISTS `pir_question_links`;
use `pir_question_links`;

CREATE TABLE `linked` (
	uqid varchar(255), 
	`year` year, 
	question_id varchar(255), 
	category varchar(255),
	question_name TEXT, 
	question_number varchar(55), 
	question_text TEXT, 
	section varchar(2),
	PRIMARY KEY (uqid, `year`, `question_id`)
);
CREATE INDEX ix_linked_uqid ON linked (uqid);
CREATE INDEX ix_linked_year ON linked (`year`);
CREATE INDEX ix_linked_question_id ON linked (question_id);

CREATE TABLE `unlinked` (
	question_id varchar(255), 
	`year` year, 
	category varchar(255),
	proposed_link TEXT,
	question_name TEXT, 
	question_number varchar(55), 
	question_text TEXT, 
	section varchar(2),
	PRIMARY KEY (question_id, `year`)
);
CREATE INDEX ix_unlinked_year ON unlinked (`year`);
CREATE INDEX ix_unlinked_question_id ON unlinked (question_id);