DROP USER IF EXISTS 'analyst'@'%';
CREATE USER 'analyst'@'%' IDENTIFIED BY '7aZ98pz1z2';
GRANT SELECT, INSERT, EXECUTE ON * . * TO 'analyst'@'%';
