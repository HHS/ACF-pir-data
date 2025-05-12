cd /srv/pir-qa-dashboard/
source .venv/bin/activate
google-chrome http://localhost:8080 &>/dev/null &
waitress-serve --host 127.0.0.1 --call "pir_pipeline.dashboard:create_app"