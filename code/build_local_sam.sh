source .sam_env/bin/activate
python3.12 -m build --wheel
pip uninstall -y pir_pipeline
pip install dist/pir_pipeline-1.0.0-py3-none-any.whl
pip freeze > pir-ingestor-lambda/pir_ingestor/requirements.txt
cd pir-ingestor-lambda
sam build
sam local invoke --env-vars env/env.json --event events/SampleEvent.json