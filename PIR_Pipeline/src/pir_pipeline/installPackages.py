def main():
    # Import necessary Python modules for running external commands,
    # handling command-line arguments, parsing JSON files, manipulating file paths, and globbing patterns.
    import subprocess, argparse, json, os, glob
    # Determine the directory where the current script is located.
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    script_dir = os.path.join(current_dir, "_common", "installation")
    script_path = os.path.join(script_dir, "installPackages.R")
    renv_path = os.path.join(current_dir, "renv")
    # Execute the R script to install packages, specifying the path to the R executable and the renv directory as arguments.
    # The working directory is set to the current directory of the Python script.
    subprocess.call([config["R_Path"], script_path, renv_path], cwd = current_dir)