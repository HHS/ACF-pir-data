import os

import pandas as pd

from pir_pipeline.hses.HSES import HSES
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils

if os.getenv("IN_AWS_LAMBDA"):
    DB_CONFIG = {
        "user": os.getenv("DB_USER"),
        "password": os.getenv("DB_PASSWORD"),
        "host": os.getenv("DB_HOST"),
        "port": os.getenv("DB_PORT"),
        "database": os.getenv("DB_NAME"),
    }
else:
    DB_CONFIG = {
        "user": os.getenv("dbusername"),
        "password": os.getenv("dbpassword"),
        "host": os.getenv("dbhost"),
        "port": os.getenv("dbport"),
        "database": "pir",
    }


def main():
    sql_utils = SQLAlchemyUtils(**DB_CONFIG)
    hses = HSES().get_data().unzip()
    for file in os.scandir(hses.tempdir):
        if not file.name.startswith("grant_master"):
            continue

        grant_master = pd.read_csv(file.path)
        agency_id = grant_master.drop_duplicates(["grant_number"])[
            ["grant_number", "agency_id"]
        ]

    sql_utils.create_db()
    sql_utils.insert_records(agency_id.to_dict(orient="records"), "agency_id")


if __name__ == "__main__":
    main()
