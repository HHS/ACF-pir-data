def main():
    # Import necessary Python modules for executing subprocesses,
    # working with JSON data, and handling file and directory paths.
    import subprocess, json, os, glob
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    script_dir = os.path.join(current_dir, "pir_question_links")
    script_path = os.path.join(script_dir, "linkQuestions.R")
    # Execute the R script using the path to the R executable and the script path specified in the configuration.
    # The working directory is set to the current directory of the Python script to ensure relative paths in the R script run correctly.
    subprocess.call([config["R_Path"], script_path], cwd = current_dir)