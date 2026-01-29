cd ~/repos/ACF-pir-data/
source .venv/bin/activate
export LOADING_DASHBOARD="True"
google-chrome http://localhost:8080 &>/dev/null &
waitress-serve --host 127.0.0.1 --call "pir_pipeline.dashboard:create_app"