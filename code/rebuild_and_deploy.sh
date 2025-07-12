# Activate virtual environment
source venv/bin/activate

# Rebuild python package
pip install build
python3.12 -m build --wheel
pip uninstall -y pir_pipeline
pip install dist/pir_pipeline-1.0.0-py3-none-any.whl
pip freeze > pir-pipeline/pir_ingestor/requirements.txt
pip freeze > pir-pipeline/pir_linker/requirements.txt

# CD and get environment variables
cd pir-pipeline
environment=$(cat env/env.json)
host=$(echo $environment | jq -r '.host')
pw=$(echo $environment | jq -r '.password')

# (Re)Build and (re)deploy
sam build
sam deploy --parameter-overrides ParameterKey=DBHost,ParameterValue=$host ParameterKey=DBPassword,ParameterValue=$pw