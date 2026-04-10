CREATE USER approver
WITH PASSWORD '$USER_PASSWORD_APPROVER';

GRANT SELECT ON ALL TABLES IN SCHEMA public TO approver;

GRANT ALL PRIVILEGES ON proposed_changes, uqid_changelog, uqid_changelog_id_seq, link_history TO approver;
GRANT INSERT, SELECT, UPDATE ON question TO approver;

ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT SELECT ON TABLES TO approver;
