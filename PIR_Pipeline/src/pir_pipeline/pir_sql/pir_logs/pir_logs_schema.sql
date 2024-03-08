
CREATE DATABASE IF NOT EXISTS `pir_logs`;

-- Switch to the 'pir_logs' database
USE `pir_logs`;

-- Create a table to store logs related to PIR ingestion
CREATE TABLE `pir_ingestion_logs` (
    `run` TIMESTAMP, -- Timestamp indicating when the PIR ingestion process occurred
    `timestamp` TIMESTAMP, -- Timestamp of the log entry
    `message` TEXT, -- Textual description of the log message
    PRIMARY KEY (`run`, `timestamp`) -- Composite primary key consisting of 'run' and 'timestamp'
);

-- Create a table to store logs related to PIR question linkage
CREATE TABLE `pir_question_linkage_logs` (
    `run` TIMESTAMP, -- Timestamp indicating when the question linkage process occurred
    `timestamp` TIMESTAMP, -- Timestamp of the log entry
    `message` TEXT, -- Textual description of the log message
    PRIMARY KEY (`run`, `timestamp`) -- Composite primary key consisting of 'run' and 'timestamp'
);

-- Create a table to store MySQL logs
CREATE TABLE `mysql_logs` (
    `timestamp` TIMESTAMP, -- Timestamp of the log entry
    `message` TEXT -- Textual description of the log message
);

-- Create a table to store security logs
CREATE TABLE `security_logs` (
    `timestamp` TIMESTAMP, -- Timestamp of the log entry
    `message` TEXT -- Textual description of the log message
);

-- Create a table to store logs related to PIR listeners
CREATE TABLE `pir_listener_logs` (
    `run` TIMESTAMP, -- Timestamp indicating when the PIR listener process occurred
    `timestamp` TIMESTAMP, -- Timestamp of the log entry
    `message` TEXT, -- Textual description of the log message
    PRIMARY KEY (`run`, `timestamp`) -- Composite primary key consisting of 'run' and 'timestamp'
);

-- Create a table to manually link PIR questions
CREATE TABLE `pir_manual_question_link` (
    `timestamp` TIMESTAMP, -- Timestamp of when the manual linking occurred
    `base_id` TEXT, -- Identifier for the base question
    `linked_id` TEXT, -- Identifier for the linked question
    `type` TEXT -- Type of linkage (e.g., suggested, approved)
);
