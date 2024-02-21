def main():
    import subprocess, json, os, glob
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    script_dir = os.path.join(current_dir, "pir_question_links")
    script_path = os.path.join(script_dir, "linkQuestions.R")
    
    subprocess.call([config["R_Path"], script_path], cwd = current_dir)