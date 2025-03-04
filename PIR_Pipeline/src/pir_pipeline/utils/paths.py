"""Paths to TANF files"""

import getpass

USER = getpass.getuser()
ROOT = f"C:/Users/{getpass.getuser()}/OneDrive - HHS Office of the Secretary/OHS PIR Migration"
INPUT_DIR = f"{ROOT}/input"
INTER_DIR = f"{ROOT}/intermediate"
OUT_DIR = f"{ROOT}/output"
SCRAP_DIR = f"{ROOT}/scrap"
DIAGNOSTICS_DIR = f"{ROOT}/diagnostics"
TABLEAU_DIR = f"{ROOT}/tableau"
TEST_DIR = f"{ROOT}/tests"
