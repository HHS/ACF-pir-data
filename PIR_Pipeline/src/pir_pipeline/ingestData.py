def main():
    import subprocess, argparse, json, os, glob
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    script_dir = os.path.join(current_dir, "pir_ingestion")
    script_path = os.path.join(script_dir, "ingest_data.R")
    schedule_command = 'schtasks /CREATE /TN {} /TR "{}" /SC ONCE /SD {} /ST 01:00'
    
    files = glob.glob(config["Raw"] + "/*")
    from .pir_watcher import watcher
    watcher.FolderWatcher(config, schedule_command)
    # subprocess.call([config["R_Path"], script_path, *files], cwd = current_dir)