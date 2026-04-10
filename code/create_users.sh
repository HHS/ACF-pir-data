set -a
source ./.env
set +a

# https://stackoverflow.com/questions/78251247/how-to-use-systems-environnement-variables-in-sql-script
if [ $1 == "local" ]; then
    psql -U $dbusername -p $dbport -h 127.0.0.1 -d pir -f <(envsubst < $2)
else
    psql -U $DB_USER -p $DB_PORT -h $DB_HOST -d $DB_NAME -f <(envsubst < $2)
fi