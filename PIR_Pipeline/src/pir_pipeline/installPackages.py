def main():
    import subprocess, argparse, json, os, glob
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    script_dir = os.path.join(current_dir, "_common", "installation")
    script_path = os.path.join(script_dir, "installPackages.R")
    library_path = os.path.join(current_dir, "renv", "library")
    
    subprocess.call([config["R_Path"], script_path, library_path], cwd = current_dir)