"""Paths to PIR files"""

import os

USER = os.getenv("username")
if os.getenv("OneDrive"):
    ROOT = f"{os.getenv("OneDrive")}/OHS PIR Migration"
else:
    ROOT = f"C:/Users/{USER}/Documents/OHS PIR Migration"
INPUT_DIR = f"{ROOT}/input"
INTER_DIR = f"{ROOT}/intermediate"
OUT_DIR = f"{ROOT}/output"
SCRAP_DIR = f"{ROOT}/scrap"
DIAGNOSTICS_DIR = f"{ROOT}/diagnostics"
TABLEAU_DIR = f"{ROOT}/tableau"
TEST_DIR = f"{ROOT}/tests"
