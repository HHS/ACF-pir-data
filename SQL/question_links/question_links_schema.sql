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