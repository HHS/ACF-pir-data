def main():
    # Import necessary modules for running subprocesses, parsing command-line arguments, working with JSON, and file path manipulation
    import subprocess, argparse, json, os, glob

    # Set up argument parsing for the command-line interface
    parser = argparse.ArgumentParser(
        prog="pir-ingest",
        description="Schedule PIR data for ingestion, or ingest data in Raw folder."
    )
    # Add an optional argument for immediate ingestion
    parser.add_argument('--now', action='store_true')
    
    # Add an optional argument to specify files to be ingested
    parser.add_argument('--files', nargs='+')
    
    # Determine the current directory where the script is located and define the configuration file path
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    script_dir = os.path.join(current_dir, "pir_ingestion")
    script_path = os.path.join(script_dir, "ingest_data.R")
    schedule_command = 'schtasks /CREATE /TN {} /TR "{}" /SC ONCE /SD {} /ST 01:00'
    
    args = parser.parse_args()
    # Determine the files to be ingested based on arguments or default to scanning a configured directory
    if args.files:
        files = args.files
    else:
        files = glob.glob(config["Raw"] + "/*")
    # Check if immediate ingestion is requested
    if args.now:
        subprocess.call([config["R_Path"], script_path, *files], cwd = current_dir)
    else:
        from .pir_watcher import watcher
        watcher.FolderWatcher(config, schedule_command)