# Import necessary libraries for file and directory manipulation, JSON operations, and creating a GUI
import os, json, glob, subprocess
import tkinter as tk
from tkinter import Tk, ttk
from tkinter.filedialog import askdirectory, askopenfilename

def main():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    
    # Initialize the Tkinter window
    root = Tk()
    root.title("PIR Setup")
    root.geometry("400x250")

    # Default path for PIR root directory
    pir_root = tk.StringVar(value = r"C:\Program Files\PIR")
    
    # Look for R and include as default if found
    suggested_path = glob.glob("C:/Program Files/R/*/bin/RScript.exe")
    r_on_path = subprocess.run(["where", "RScript"], capture_output=True)

    if suggested_path:
        r_path = tk.StringVar(value=suggested_path[0])
    elif r_on_path.returncode == 0:
        r_path = tk.StringVar(value=r_on_path.stdout.decode().strip())
    else:
        r_path = tk.StringVar()
    
    # Create a frame for the configuration inputs
    configure = ttk.Frame(root)
    configure.pack(padx=10, pady=10, fill='x', expand=True)
    
    # Define functions for browsing directories and files
    def browseDir():
        path = askdirectory()
        dir_entry.delete(0, tk.END)
        dir_entry.insert(0, path)
    
    # Open a file browser and update the entry with the selected path
    def browseFile():
        path = askopenfilename()
        r_entry.delete(0, tk.END)
        r_entry.insert(0, path)
    
    # Create and pack the labels, entries, and browse buttons for PIR root directory and Rscript path
    dir_label = ttk.Label(configure, text='PIR Root Directory:')
    dir_label.pack(fill='x', expand=True)
    dir_entry = ttk.Entry(configure, textvariable=pir_root)
    dir_entry.pack(fill='x', expand = True)
    dir_browse = ttk.Button(configure, text="Browse", command=browseDir)
    dir_browse.pack(fill='x', expand=True)
    
    r_label = ttk.Label(configure, text="Path to Rscript.exe:")
    r_label.pack(fill='x', expand=True)
    r_entry = ttk.Entry(configure, textvariable=r_path)
    r_entry.pack(fill='x', expand = True)
    r_browse = ttk.Button(configure, text="Browse", command=browseFile)
    r_browse.pack(fill='x', expand=True)
    
    # Check if the PIR root directory is empty and exit if true
    if dir_entry.get() == '':
        exit()

    # Define the action for the Finish button
    def finish_clicked():
        try:
            config = open(config_json)
            config = json.loads(config.read())
        except:
            config = {}
        # Create directories for PIR setup within the selected root directory and update the configuration
        for dir in ["mySQL_Logs", "mySQL_General_Logs", "mySQL_Binary_Logs", "mySQL_Query_Logs", "Installation_Logs",
                    "Automated_Pipeline_Logs", "Listener_Logs", "PIR_data_repository", "Listener_bats",
                    "PIR_data_repository\\Raw", "PIR_data_repository\\Processed", "PIR_data_repository\\Unprocessed"]:
            path = os.path.join(dir_entry.get(), dir)
            os.makedirs(path)
            config[dir.replace("PIR_data_repository\\", "")] = path
        # Update the Rscript path in the configuration     
        config["R_Path"] = r_entry.get()
        # Save the updated configuration to the JSON file
        with open(config_json, "w") as f:
            json.dump(config, f, indent=2)
        root.destroy()
    # Create and pack the Finish button
    finish_button = ttk.Button(configure, text="Finish", command=finish_clicked)
    finish_button.pack(fill='x', expand=True, pady=10)
    # Start the Tkinter event loop
    root.mainloop()