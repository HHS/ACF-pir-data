def main():
    import subprocess, argparse, json, os, glob
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    script_dir = os.path.join(current_dir, "pir_ingestion")
    script_path = os.path.join(script_dir, "ingest_data.R")
    
    parser = argparse.ArgumentParser(description='Ingest PIR Data')
    parser.add_argument(
        'directory', type=str, nargs=1, help='Directory housing PIR files.'
    )
    args = parser.parse_args()
    directory = args.directory[0] + "/*"
    files = glob.glob(directory)
    files = ' '.join(files)
    subprocess.call([config["R_Path"], script_path, files], cwd = script_dir)