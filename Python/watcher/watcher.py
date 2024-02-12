##################################################################
##  Created by: Sankar Kalaga
##  Description: This python script gets the changes happening in the PIR directory
##  It will logs the file details to text file
##  In addition it uses OOP
##  It is an alternative script for powershell script 
##################################################################

import time
import os
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import subprocess
from . import listener
# import listener

class FolderWatcher(FileSystemEventHandler):
    def __init__(self, folder_path, log_file, log_path, r_path, script_path):
        super().__init__()
        self.folder_path = folder_path
        self.log_file = log_file
        self.log_path = log_path
        self.r_path = r_path
        self.script_path = script_path
        self.start_watching(self.folder_path, self.log_file)

    def on_created(self, event):
        self.log_event("Created", event.src_path)

    def on_deleted(self, event):
        self.log_event("Deleted", event.src_path)

    # def on_modified(self, event):
    #     self.log_event("Modified", event.src_path)

    def on_moved(self, event):
        if event.is_directory:
            self.log_event("Moved (Dir)", event.src_path)
        else:
            self.log_event("Moved", event.src_path)

    def on_renamed(self, event):
        if event.is_directory:
            self.log_event("Renamed (Dir)", event.src_path)
        else:
            self.log_event("Renamed", event.src_path)

    def log_event(self, change_type, path):
        log_line = f"{time.strftime('%Y-%m-%d %H:%M:%S')}, {change_type}, {path}"
        self.log_to_file(log_line)
        print(f"Logged event: {log_line}")
        self.alert_listener()

    def log_to_file(self, log_line):
        try:
            with open(self.log_file, "a") as f:
                f.write(log_line + "\n")
        except Exception as e:
            print(f"Error logging event: {e}")
            
    def alert_listener(self):
        listener.main(self.file_info, self.log_path, self.r_path, self.script_path)

    def start_watching(self, folder_path, log_file):
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
            # with open(log_file, 'w') as f:
            #     f.write(str(file_info))
            self.file_info = file_info
            self.alert_listener()

if __name__ == "__main__":
    # Path for PIR directory to monitor
    folder_path_to_monitor = r"C:\OHS-Project-1\ACF-pir-data\tests\data\unprocessed"
    # Path for log file to log the file details
    log_file_path = r"C:\OHS-Project-1\ACF-pir-data\tests\logs\watcher.txt"
    log_path = r"C:\OHS-Project-1\ACF-pir-data\tests\logs"
    r_path = r"C:\OHS-Project-1\R-4.3.2\bin\Rscript.exe"
    script_path = r"C:\OHS-Project-1\ACF-pir-data\ingestion\ingest_data.R"
    # Check if the log file exists, and create a new file if it doesn't
    if not os.path.exists(log_file_path):
        open(log_file_path, "w").close()

    # Start monitoring the folder
    FolderWatcher(folder_path_to_monitor, log_file_path, log_path, r_path, script_path)
