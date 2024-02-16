import os, json
import tkinter as tk
from tkinter import ttk
from tkinter.messagebox import showinfo

def main():

    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")

    root = tk.Tk()
    root.geometry("500x250")
    root.resizable(False, False)
    root.title("Configure Database Credentials")

    username = tk.StringVar()
    password = tk.StringVar()
    host = tk.StringVar(value='localhost')
    port = tk.IntVar(value=0)

    # Configuration Frame
    configure = ttk.Frame(root)
    configure.pack(padx=10, pady=10, fill='x', expand=True)

    # username
    username_label = ttk.Label(configure, text='Database Username:')
    username_label.pack(fill='x', expand=True)

    username_entry = ttk.Entry(configure, textvariable = username)
    username_entry.pack(fill="x", expand = True)
    username_entry.focus()

    # password
    password_label = ttk.Label(configure, text='Database Password:')
    password_label.pack(fill='x', expand=True)

    password_entry = ttk.Entry(configure, textvariable = password, show="*")
    password_entry.pack(fill="x", expand = True)

    # host
    host_label = ttk.Label(configure, text='Database Host:')
    host_label.pack(fill='x', expand=True)

    host_entry = ttk.Entry(configure, textvariable = host)
    host_entry.pack(fill="x", expand = True)

    # port
    port_label = ttk.Label(configure, text='Database Port:')
    port_label.pack(fill='x', expand=True)

    port_entry = ttk.Entry(configure, textvariable = port)
    port_entry.pack(fill="x", expand = True)

    # Finish button
    def finish_clicked():
        dbusername = username.get()
        dbpassword = password.get()
        dbhost = host.get()
        dbport = port.get()
        try:
            config = open(config_json)
            config = json.loads(config.read())
        except:
            config = {}
        for c in ["dbusername", "dbpassword", "dbhost", "dbport"]:
            config[c] = locals()[c]
        with open(config_json, 'w') as f:
            json.dump(config, f)
        root.destroy()
        

    finish_button = ttk.Button(configure, text="Finish", command=finish_clicked)
    finish_button.pack(fill='x', expand=True, pady=10)

    root.mainloop()
    
if __name__ == "__main__":
    main()
