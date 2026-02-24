import json
import os
from datetime import datetime, timedelta

from sqlalchemy import func, select

from instance.config import DB_CONFIG, DB_NAME
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils

if __name__ == "__main__":
    sql = SQLAlchemyUtils(**DB_CONFIG, database=DB_NAME)
    path = os.path.join(
        os.path.dirname(__file__), "..", "static", "data", "daily_confirmed_count.json"
    )
    uqid_changelog = sql.tables["uqid_changelog"]
    confirmed = sql.tables["confirmed"]

    # Confirmed uqids
    confirmations = (
        select(uqid_changelog.c["original_uqid"])
        .where(uqid_changelog.c["timestamp"] > datetime.today() - timedelta(hours=24))
        .group_by(uqid_changelog.c["original_uqid"])
        .having(func.max(uqid_changelog.c["complete_series_flag"]) == 1)
        .scalar_subquery()
    )

    # Number of confirmed questions
    confirmed_count = select(func.count(confirmed.table_valued())).where(
        confirmed.c.uqid.in_(confirmations)
    )

    try:
        fp = open(path, "r+")
        confirmed = json.load(fp)
    except FileNotFoundError:
        fp = open(path, "w+")
        confirmed = {}

    fp.seek(0)

    confirmed[datetime.today().strftime("%Y-%m-%d")] = (
        sql.get_scalar(confirmed_count, {}) or 0
    )
    json.dump(confirmed, fp, indent=2)
    fp.close()
