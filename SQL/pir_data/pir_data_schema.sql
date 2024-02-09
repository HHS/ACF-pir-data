CREATE DATABASE IF NOT EXISTS pir_data;
USE pir_data;

CREATE TABLE `response` (
  `uid` varchar(255),
  `question_id` varchar(255),
  `answer` text,
  `year` year,
  PRIMARY KEY (`uid`, `question_id`, `year`)
);
CREATE INDEX ix_response_uid ON response (uid);
CREATE INDEX ix_response_question_id ON response (question_id);
CREATE INDEX ix_response_year ON response (`year`);

CREATE TABLE `program` (
  `uid` varchar(255),
  `program_number` varchar(255),
  `program_type` varchar(255),
  `program_name` varchar(255),
  `program_address_line_1` varchar(255),
  `program_address_line_2` varchar(255),
  `program_city` varchar(255),
  `program_state` varchar(255),
  `program_zip1` varchar(255),
  `program_zip2` varchar(255),
  `program_phone` varchar(255),
  `program_email` varchar(255),
  `program_agency_type` varchar(255),
  `program_agency_description` varchar(255),
  `grant_number` varchar(255),
  `grantee_name` varchar(255),
  `region` varchar(255),
  `year` year,
  PRIMARY KEY (`uid`, `year`)
);
CREATE INDEX ix_program_uid ON program (uid);
CREATE INDEX ix_program_year ON program (`year`);

CREATE TABLE `question` (
  `question_id` varchar(255),
  `category` varchar(255),
  `section` varchar(255),
  `subsection` varchar(255),
  `question_name` text,
  `question_text` text,
  `question_order` varchar(255),
  `question_number` varchar(255),
  `question_type` varchar(255),
  `year` year,
  PRIMARY KEY (`question_id`, `year`)
);
CREATE INDEX ix_question_question_id ON question (question_id);
CREATE INDEX ix_question_year ON question (`year`);

CREATE TABLE `unmatched_question` (
  `question_id` varchar(255),
  `category` varchar(255),
  `section` varchar(255),
  `subsection` varchar(255),
  `question_name` text,
  `question_text` text,
  `question_order` varchar(255),
  `question_number` varchar(255),
  `question_type` varchar(255),
  `reason` varchar(255),
  `year` year,
  PRIMARY KEY (`question_id`, `year`)
);
CREATE INDEX ix_unmatched_question_question_id ON unmatched_question (question_id);
CREATE INDEX ix_unmatched_question_year ON unmatched_question (`year`);

ALTER TABLE `response` ADD FOREIGN KEY (`uid`, `year`) REFERENCES `program` (`uid`, `year`);

ALTER TABLE `response` ADD FOREIGN KEY (`question_id`, `year`) REFERENCES `question` (`question_id`, `year`);
