DROP USER IF EXISTS 'developer'@'%';
CREATE USER 'developer'@'%' IDENTIFIED BY 'WPYtmRfZUn';
GRANT 'DBManager', 'DBDEsigner', 'BackupAdmin' TO 'developer'@'%';
