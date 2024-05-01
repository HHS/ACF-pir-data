def main():
    # Import necessary modules for running subprocesses, parsing command-line arguments, working with JSON, and file path manipulation
    import subprocess, json, os

    # Determine the current directory where the script is located and define the configuration file path
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    
    # Open index.html in the default browser
    index_loc = os.path.join(current_dir, "documentation", "training", "_book", "index.html")
    subprocess.call(["start", index_loc], shell=True)

if __name__ == "__main__":
    main()