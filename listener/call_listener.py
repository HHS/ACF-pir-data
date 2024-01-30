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
#python "C:/OHS-Project-1/ACF-pir-data/listener/call_listener.py"  "C:/OHS-Project-1/watcher_obj/test_listener_r.r"

# ###################################################
# ##  Created by: Dr. Rigoberto Garcia
# ##  Description: ingest powershell
# ##
# ####################################################
# import subprocess
# import sys
# 
# def call_powershell_script(powershell_script_path, args=[]):
#     # Construct the PowerShell command
#     #command = ["powershell", "-ExecutionPolicy", "Unrestricted", powershell_script_path] + args
#     command = ["powershell.exe", "-File", powershell_script_path]
#     try:
#         # Run the command and wait for it to complete
#         # process = subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
#         process = subprocess.run(command, check=True)
#         # Print the output from PowerShell
#         print("PowerShell Script Output:", process.stdout)
#     except subprocess.CalledProcessError as e:
#         print("Error occurred in PowerShell script:", e.stderr, file=sys.stderr)
# 
# # Path to your PowerShell script
# ps_script_path = "C:\\OHS-Project-1\\listener_module\\polina_powershell.ps1"
# 
# # Call the function with the path to the PowerShell script
# # Add any arguments if your PowerShell script requires them
# call_powershell_script(ps_script_path)
