##################################################################
##  Created by: Sankar Kalaga
##  Description: This python script gets the changes happening in the PIR directory
##  It will logs the file details to text file
##  In addition it uses OOP
##  It is an alternative script for powershell script 
##################################################################

import time
import os
import subprocess
import mysql.connector

class FolderWatcher():
    def __init__(self, config):
        super().__init__()
        self.config = config
        self.start_watching(self.config['Raw'])
            
    def alert_listener(self):
        listener.main(self.file_info, self.config)

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

if __name__ == "__main__":
    import listener, json
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "..", "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    
    # Start monitoring the folder
    FolderWatcher(config)
elif __name__.find("pir_pipeline.pir_watcher") + 1:
    from . import listener
else:
    import listener