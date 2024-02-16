import os, json

current_dir = os.path.dirname(os.path.abspath(__file__))
rproj = os.path.join(current_dir, 'pir_pipeline.Rproj')

with open(rproj, 'a') as f:
    for line in [
        "Version: 1.0", "RestoreWorkspace: Default",
        "SaveWorkspace: Default", "AlwaysSaveHistory: Default",
        "EnableCodeIndexing: Yes", "UseSpacesForTab: Yes", "NumSpacesForTab: 2",
        "Encoding: UTF-8", "RnwWeave: Sweave", "LaTeX: pdfLaTex"
    ]:
        f.write(line)
    f.write("\n")