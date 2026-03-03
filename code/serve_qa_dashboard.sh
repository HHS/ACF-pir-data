source ./application/.venv/bin/activate

USER_NUMBER=$(id -u)
USER_NAME=$(id -un)
USER_PORT=$((5000 + $USER_NUMBER % 1000))
export DB_ENV="production"

if [ $USER_NAME == "reggie.gilliard" ]; then
    export DB_PROFILE="approver"
else
    export DB_PROFILE="reviewer"
fi

waitress-serve --host 127.0.0.1 --port=${USER_PORT} --call "pir_pipeline.dashboard:create_app" 