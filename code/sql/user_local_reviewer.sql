CREATE USER reviewer
WITH PASSWORD '$reviewer_user_password';

GRANT SELECT ON ALL TABLES IN SCHEMA public TO reviewer;

GRANT ALL PRIVILEGES ON proposed_changes, link_history TO reviewer;

ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT SELECT ON TABLES TO reviewer;
