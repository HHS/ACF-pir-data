def main():
    import subprocess, os, json
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    
    script_dir = os.path.join(current_dir, "pir_question_links", "dashboard")
    
    try:
        subprocess.run([config['R_Path'], "-e", "{}".format("shiny::runApp('questionLinkDashboard.R')")], check=True, cwd=script_dir)
    except Exception as e:
        print(dir(e.__traceback__))
        traceback = e.__traceback__
        while traceback:
            print(traceback.tb_frame)
            print(traceback.tb_lasti)
            print(traceback.tb_lineno)
            try:
                traceback = traceback.tb_next
            except:
                traceback = None
        print([e.cmd, e.output, e.returncode])