CREATE DATABASE IF NOT EXISTS `pir_logs`;
use `pir_logs`;

CREATE TABLE `pir_ingestion_logs` (
    `run` TIMESTAMP,
    `timestamp` TIMESTAMP,
    `message` TEXT
);

CREATE TABLE `pir_question_linkage_logs` (
    `run` TIMESTAMP,
    `timestamp` TIMESTAMP,
    `message` TEXT
)

CREATE TABLE `mysql_logs` (
    `timestamp` TIMESTAMP,
    `message` TEXT
);

CREATE TABLE `security_logs` (
    `timestamp` TIMESTAMP,
    `message` TEXT
);