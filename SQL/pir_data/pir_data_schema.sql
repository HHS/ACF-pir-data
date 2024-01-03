CREATE DATABASE IF NOT EXISTS pir_data;
USE pir_data;

CREATE TABLE `Response` (
  `uid` varchar(255),
  `question_id` varchar(255),
  `answer` text,
  `year` year,
  PRIMARY KEY (`uid`, `question_id`, `year`)
);

CREATE TABLE `unmatched_response` (
  `uid` varchar(255),
  `question_id` varchar(255),
  `answer` text,
  `reason` varchar(255),
  `year` year,
  PRIMARY KEY (`uid`, `question_id`, `year`)
);

CREATE TABLE `Program` (
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

CREATE TABLE `Question` (
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
