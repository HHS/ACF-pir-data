import time
import os
import subprocess
import mysql.connector

# Define a class to monitor changes in a specific folder and trigger actions based on those changes.
class FolderWatcher():
    # Initialize the FolderWatcher object with configuration settings and a command to schedule tasks.
    def __init__(self, config, schedule_command):
        super().__init__()
        self.config = config
        self.schedule_command = schedule_command
        self.start_watching(self.config['Raw'])
            
    # Define a method to be called when a new file is detected.
    def alert_listener(self):
        listener.main(self.file_info, self.config, self.schedule_command)

    # Start monitoring the specified folder for new files.
    def start_watching(self, folder_path):
        files = os.listdir(folder_path)
        if files:
            files = os.scandir(folder_path)
            file_info = {}
            for file in files:
                if file.is_file():
                    file_stats = file.stat()
                    file_info[file.name] = {}
                    current_file = file_info[file.name]
                    current_file["Path"] = file.path
                    current_file["Size"] = file_stats.st_size/1000000
                    current_file["LastFileWriteTime"] = time.strftime("%Y%m%d_%H%M%S", time.localtime(file_stats.st_mtime))
                    current_file["Today"] = time.strftime("%Y%m%d_%H%M%S", time.localtime())
            self.file_info = file_info
            self.alert_listener()

# Check if the script is being run directly.
if __name__ == "__main__":
    import listener, json
    # Determine the current directory and read the configuration from a JSON file.
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "..", "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    # Define the command template for scheduling tasks.
    schedule_command = 'schtasks /CREATE /TN {} /TR "{}" /SC ONCE /SD {} /ST 01:00 /RU System'
    
    # Start monitoring the folder
    FolderWatcher(config, schedule_command)
elif __name__.find("pir_pipeline.pir_watcher") + 1:
    from . import listener
else:
    import listener