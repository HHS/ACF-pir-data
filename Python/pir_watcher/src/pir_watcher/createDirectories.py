import os, json
from tkinter import Tk
from tkinter.filedialog import askdirectory

def main():
    Tk().withdraw()
    parent_dir = askdirectory()
    if parent_dir == '':
        exit()
    current_dir = os.path.dirname(os.path.abspath(__file__))

    path_dict = {}
    for dir in ["Raw_Data", "Unprocessed_Data", "Processed_Data", "Scheduled_Data", "Logs",
                "Logs\\Ingestion_Logs", "Logs\\Listener_Logs"]:
        path = os.path.join(parent_dir, dir)
        os.makedirs(path)
        path_dict[dir.replace("Logs\\", "")] = path

    out_json = os.path.join(current_dir, "config.json")
    with open(out_json, "w") as f:
        json.dump(path_dict, f)