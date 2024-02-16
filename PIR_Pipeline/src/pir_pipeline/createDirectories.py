import os, json
from tkinter import Tk
from tkinter.filedialog import askdirectory

def main():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    
    Tk().withdraw()
    parent_dir = askdirectory()
    if parent_dir == '':
        exit()

    try:
        config = open(config_json)
        config = json.loads(config.read())
    except:
        config = {}
    
    for dir in ["mySQL_Logs", "mySQL_General_Logs", "mySQL_Binary_Logs", "mySQL_Query_Logs", "Installation_Logs",
                "Automated_Pipeline_Logs", "Listener_Logs", "PIR_data_repository", "Listener_bats",
                "PIR_data_repository\\Raw", "PIR_data_repository\\Scheduled", 
                "PIR_data_repository\\Processed", "PIR_data_repository\\Unprocessed"]:
        path = os.path.join(parent_dir, dir)
        os.makedirs(path)
        config[dir.replace("PIR_data_repository\\", "")] = path

    with open(config_json, "w") as f:
        json.dump(config, f)
