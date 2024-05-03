CREATE DATABASE IF NOT EXISTS `pir_logs`;
use `pir_logs`;

CREATE TABLE `pir_ingestion_logs` (
    `run` TIMESTAMP,
    `timestamp` TIMESTAMP,
    `message` TEXT,
    PRIMARY KEY (`run`, `timestamp`)
);

CREATE TABLE `pir_question_linkage_logs` (
    `run` TIMESTAMP,
    `timestamp` TIMESTAMP,
    `message` TEXT,
    PRIMARY KEY (`run`, `timestamp`)
);

CREATE TABLE `pir_listener_logs` (
    `run` TIMESTAMP,
    `timestamp` TIMESTAMP,
    `message` TEXT,
    PRIMARY KEY (`run`, `timestamp`)
);

CREATE TABLE `pir_manual_question_link` (
    `base_id` TEXT,
    `linked_id` TEXT,
    `timestamp` TIMESTAMP,
    `type` TEXT
);