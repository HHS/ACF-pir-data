
CREATE DATABASE IF NOT EXISTS pir_data;

-- Use the pir_data database for subsequent operations
USE pir_data;

-- Create a table to store responses
CREATE TABLE `response` (
  `uid` varchar(255), -- Unique identifier for the respondent
  `question_id` varchar(255), -- Identifier for the question
  `answer` text, -- Textual response to the question
  `year` year, -- Year in which the response was recorded
  PRIMARY KEY (`uid`, `question_id`, `year`) -- Primary key comprising of uid, question_id, and year
);

-- Create indexes for faster retrieval of data based on uid, question_id, and year
CREATE INDEX ix_response_uid ON response (uid);
CREATE INDEX ix_response_question_id ON response (question_id);
CREATE INDEX ix_response_year ON response (`year`);

-- Create a table to store program information
CREATE TABLE `program` (
  `uid` varchar(255), -- Unique identifier for the program
  `program_number` varchar(255), -- Identifier for the program number
  `program_type` varchar(255), -- Type of program
  `program_name` varchar(255), -- Name of the program
  -- Other program details such as address, contact information, and grant information
  `year` year, -- Year in which the program data was recorded
  PRIMARY KEY (`uid`, `year`) -- Primary key comprising of uid and year
);

-- Create indexes for faster retrieval of data based on uid and year
CREATE INDEX ix_program_uid ON program (uid);
CREATE INDEX ix_program_year ON program (`year`);

-- Create a table to store questions
CREATE TABLE `question` (
  `question_id` varchar(255), -- Identifier for the question
  `category` varchar(255), -- Category to which the question belongs
  `section` varchar(255), -- Section of the questionnaire
  `subsection` varchar(255), -- Subsection of the questionnaire
  -- Other details such as question name, text, order, and type
  `year` year, -- Year in which the question data was recorded
  PRIMARY KEY (`question_id`, `year`) -- Primary key comprising of question_id and year
);

-- Create indexes for faster retrieval of data based on question_id and year
CREATE INDEX ix_question_question_id ON question (question_id);
CREATE INDEX ix_question_year ON question (`year`);

-- Create a table to store unmatched questions
CREATE TABLE `unmatched_question` (
  `question_id` varchar(255), -- Identifier for the unmatched question
  `category` varchar(255), -- Category to which the unmatched question belongs
  `section` varchar(255), -- Section of the questionnaire
  `subsection` varchar(255), -- Subsection of the questionnaire
  -- Other details such as question name, text, order, type, and reason for being unmatched
  `year` year, -- Year in which the unmatched question data was recorded
  PRIMARY KEY (`question_id`, `year`) -- Primary key comprising of question_id and year
);

-- Create indexes for faster retrieval of data based on question_id and year
CREATE INDEX ix_unmatched_question_question_id ON unmatched_question (question_id);
CREATE INDEX ix_unmatched_question_year ON unmatched_question (`year`);

-- Add foreign key constraints to ensure data integrity between tables
ALTER TABLE `response` ADD FOREIGN KEY (`uid`, `year`) REFERENCES `program` (`uid`, `year`);
ALTER TABLE `response` ADD FOREIGN KEY (`question_id`, `year`) REFERENCES `question` (`question_id`, `year`);
