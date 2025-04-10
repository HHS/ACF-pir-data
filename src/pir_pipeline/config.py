"""Configuration"""

import os

from dotenv import load_dotenv

load_dotenv()

if os.getenv("ON_RUNNER"):
    db_config = {
        "user": os.getenv("POSTGRES_USER"),
        "password": os.getenv("POSTGRES_PASSWORD"),
        "host": os.getenv("POSTGRES_HOST"),
        "port": os.getenv("POSTGRES_PORT"),
    }
else:
    db_config = {
        "user": os.getenv("dbusername"),
        "password": os.getenv("dbpassword"),
        "host": os.getenv("dbhost"),
        "port": os.getenv("dbport"),
    }
