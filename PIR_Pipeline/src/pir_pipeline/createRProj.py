def main():
    # Import necessary modules for file path manipulation and JSON operations
    import os, json
    # Determine the directory where the script is located
    current_dir = os.path.dirname(os.path.abspath(__file__))
    # Define the path to the R project file within the current directory
    rproj = os.path.join(current_dir, 'pir_pipeline.Rproj')
    # Open the R project file in append mode. This allows adding new content without deleting existing content.
    with open(rproj, 'a') as f:
        for line in [
            "Version: 1.0", "RestoreWorkspace: Default",
            "SaveWorkspace: Default", "AlwaysSaveHistory: Default",
            "EnableCodeIndexing: Yes", "UseSpacesForTab: Yes", "NumSpacesForTab: 2",
            "Encoding: UTF-8", "RnwWeave: Sweave", "LaTeX: pdfLaTex"
        ]:
            f.write(line)
            f.write("\n")
        f.write("\n")