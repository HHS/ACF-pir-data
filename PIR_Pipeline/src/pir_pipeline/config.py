import os

from dotenv import load_dotenv

load_dotenv()

db_config = {
    "user": os.getenv("dbusername"),
    "password": os.getenv("dbpassword"),
    "host": os.getenv("dbhost"),
    "port": os.getenv("dbport"),
}
