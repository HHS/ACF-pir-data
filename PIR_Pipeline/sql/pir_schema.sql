CREATE DATABASE IF NOT EXISTS pir;
USE pir;

CREATE TABLE `program` (
  `uid` varchar(255),
  `year` year,
  `grantee_name` varchar(255),
  `grant_number` varchar(255),
  `program_address_line_1` varchar(255),
  `program_address_line_2` varchar(255),
  `program_agency_description` varchar(255),
  `program_agency_type` varchar(255),
  `program_city` varchar(255),
  `program_email` varchar(255),
  `program_name` varchar(255),
  `program_number` varchar(255),
  `program_phone` varchar(255),
  `program_type` varchar(255),
  `program_state` varchar(255),
  `program_zip1` varchar(255),
  `program_zip2` varchar(255),
  `region` int,
  PRIMARY KEY (`uid`, `year`),
  INDEX ix_program_uid (`uid`),
  INDEX ix_program_year (`year`)
);

CREATE TABLE `question` (
  `question_id` varchar(255),
  `year` year,
  `uqid` varchar(255),
  `category` varchar(255),
  `question_name` text,
  `question_number` varchar(255),
  `question_order` float,
  `question_text` text,
  `question_type` varchar(255),
  `section` varchar(255),
  `subsection` varchar(255),
  PRIMARY KEY (`question_id`, `year`),
  INDEX ix_question_question_id (`question_id`),
  INDEX ix_question_year (`year`)
);

CREATE TABLE `response` (
  `uid` varchar(255),
  `question_id` varchar(255),
  `year` year,
  `answer` text,
  PRIMARY KEY (`uid`, `question_id`, `year`),
  INDEX ix_response_uid (`uid`),
  INDEX ix_response_question_id (`question_id`),
  INDEX ix_response_year (`year`),
  FOREIGN KEY (`uid`, `year`) 
    REFERENCES `program` (`uid`, `year`)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (`question_id`, `year`) 
    REFERENCES `question` (`question_id`, `year`)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);