"""PirLinker: link any unlinked questions (runs daily on a schedule)"""

from sqlalchemy import select

from handlers.common import get_sql_utils
from pir_pipeline.linking.PIRLinker import PIRLinker

sql_utils = get_sql_utils()


def lambda_handler(event, context):
    try:
        records = sql_utils.get_records(select(sql_utils.tables["unlinked"])).to_dict(
            orient="records"
        )
        if not records:
            message = "No unlinked records."
        else:
            PIRLinker(records, sql_utils).link().update_unlinked()
            message = "Records linked successfully."

        return {"message": message}
    except Exception as e:
        print(e)
        print("Failed to link records")
        raise e
