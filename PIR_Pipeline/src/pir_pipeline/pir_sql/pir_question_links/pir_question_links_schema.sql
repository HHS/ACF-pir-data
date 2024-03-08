
CREATE DATABASE IF NOT EXISTS `pir_question_links`;
USE `pir_question_links`;

-- Table to store linked questions
CREATE TABLE `linked` (
	uqid VARCHAR(255), -- Unique identifier for the question
	`year` YEAR, -- Year of the question
	question_id VARCHAR(255), -- Identifier for the question
	question_name TEXT, -- Name of the question
	question_text TEXT, -- Text of the question
	question_number VARCHAR(55), -- Number of the question
	category VARCHAR(255), -- Category of the question
	section VARCHAR(2), -- Section of the question
	PRIMARY KEY (uqid, `year`, `question_id`) -- Primary key constraint
);
CREATE INDEX ix_linked_uqid ON linked (uqid); -- Index on uqid for faster lookups
CREATE INDEX ix_linked_year ON linked (`year`); -- Index on year for faster lookups
CREATE INDEX ix_linked_question_id ON linked (question_id); -- Index on question_id for faster lookups

-- Table to store unlinked questions
CREATE TABLE `unlinked` (
	`year` YEAR, -- Year of the question
	question_id VARCHAR(255), -- Identifier for the question
	question_name TEXT, -- Name of the question
	question_text TEXT, -- Text of the question
	question_number VARCHAR(55), -- Number of the question
	category VARCHAR(255), -- Category of the question
	section VARCHAR(2), -- Section of the question
	proposed_link TEXT, -- Proposed link for the question
	PRIMARY KEY (question_id, `year`) -- Primary key constraint
);
CREATE INDEX ix_unlinked_year ON unlinked (`year`); -- Index on year for faster lookups
CREATE INDEX ix_unlinked_question_id ON unlinked (question_id); -- Index on question_id for faster lookups

-- Table to store new questions
CREATE TABLE `new_questions` (
	`year` YEAR, -- Year of the question
	question_id VARCHAR(255), -- Identifier for the question
	question_name TEXT, -- Name of the question
	question_text TEXT, -- Text of the question
	question_number VARCHAR(55), -- Number of the question
	category VARCHAR(255), -- Category of the question
	section VARCHAR(2), -- Section of the question
	PRIMARY KEY (question_id, `year`) -- Primary key constraint
);
CREATE INDEX ix_new_questions_year ON new_questions (`year`); -- Index on year for faster lookups
CREATE INDEX ix_new_questions_question_id ON new_questions (question_id); -- Index on question_id for faster lookups
