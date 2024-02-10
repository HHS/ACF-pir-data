###################################################
##  Created by: Polina Polskaia
##  Description: Takes any R script and runs it
##
###################################################

import subprocess
import sys

class RScriptExecutor:
    def __init__(self, script_path):
        self.script_path = script_path

    def execute_script(self):
        try:
            subprocess.run(["Rscript", self.script_path], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error executing R script: {e}")
            sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python r_script_executor.py <R_script_path>")
        sys.exit(1)

    r_script_path = sys.argv[1]
    executor = RScriptExecutor(r_script_path)
    executor.execute_script()
    
    

# call in command line!
#python "C:/OHS-Project-1/ACF-pir-data/listener/call_listener.py"  "C:/OHS-Project-1/ACF-pir-data/listener/listener.r"
#python "C:/OHS-Project-1/ACF-pir-data/listener/call_listener.py"  "C:/OHS-Project-1/ACF-pir-data/listener/test_listener_r.r"
