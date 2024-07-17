def main():
    import subprocess, os, json
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    
    script_dir = os.path.join(current_dir, "pir_question_links", "dashboard")
    # Use subprocess.run to execute the R script that runs the Shiny application.
    # The R executable path is retrieved from the configuration file.
    # "-e" flag is used to execute the given expression in R.
    try:
        subprocess.run([config['R_Path'], "-e", "{}".format("shiny::runApp('pir_question_links/dashboard/questionLinkDashboard.R', launch.browser = TRUE)")], check=True, cwd=current_dir)
    except Exception as e:
        # In case of an exception, print the traceback information for debugging.
        print(dir(e.__traceback__))
        traceback = e.__traceback__
        while traceback:
            print(traceback.tb_frame)
            print(traceback.tb_lasti)
            print(traceback.tb_lineno)
            # Move to the next traceback object if it exists.
            try:
                traceback = traceback.tb_next
            except:
                traceback = None
        # Finally, print the command that was attempted to run, along with any output and the return code.
        # This will help in diagnosing what went wrong with the subprocess call.
        print([e.cmd, e.output, e.returncode])