def main():
    import subprocess, argparse, json, os, glob
    
    parser = argparse.ArgumentParser(
        prog="pir-ingest",
        description="Schedule PIR data for ingestion, or ingest data in Raw folder."
    )
    parser.add_argument('--now', action='store_true')
    parser.add_argument('--files', nargs='+')
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    script_dir = os.path.join(current_dir, "pir_ingestion")
    script_path = os.path.join(script_dir, "ingest_data.R")
    schedule_command = 'schtasks /CREATE /TN {} /TR "{}" /SC ONCE /SD {} /ST 01:00'
    
    args = parser.parse_args()
    
    if args.files:
        files = args.files
    else:
        files = glob.glob(config["Raw"] + "/*.xls*")
    
    if args.now:
        subprocess.call([config["R_Path"], script_path, *files], cwd = current_dir)
    else:
        from .pir_watcher import watcher
        watcher.FolderWatcher(config, schedule_command)