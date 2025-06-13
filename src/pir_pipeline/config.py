"""Configuration"""

import os

from dotenv import load_dotenv

load_dotenv()

DB_NAME = "pir"

if os.getenv("ON_RUNNER"):
    DB_CONFIG = {
        "user": os.getenv("POSTGRES_USER"),
        "password": os.getenv("POSTGRES_PASSWORD"),
        "host": os.getenv("POSTGRES_HOST"),
        "port": os.getenv("POSTGRES_PORT"),
    }
elif os.getenv("RDS_CREDENTIALS"):
    DB_CONFIG = {
        "user": os.getenv("RDS_USER"),
        "password": os.getenv("RDS_PASSWORD"),
        "host": os.getenv("RDS_HOST"),
        "port": os.getenv("RDS_PORT"),
    }
else:
    DB_CONFIG = {
        "user": os.getenv("dbusername"),
        "password": os.getenv("dbpassword"),
        "host": os.getenv("dbhost"),
        "port": os.getenv("dbport"),
    }
