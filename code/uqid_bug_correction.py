from sqlalchemy import func, or_, select

from pir_pipeline.config import DB_CONFIG, DB_NAME
from pir_pipeline.linking.PIRLinker import PIRLinker
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils

sql_utils = SQLAlchemyUtils(**DB_CONFIG, database="pir_data")

# Get duplicated uqids
question = sql_utils.tables["question"]
duplicate_uqid_query = (
    select(question.c["uqid"])
    .group_by(question.c[("uqid", "year")])
    .having(func.count(question.c["uqid"]) > 1)
)

duplicate_uqids = sql_utils.get_records(duplicate_uqid_query)["uqid"].tolist()
print(duplicate_uqids)

# Set duplicated uqids to null
sql_utils.update_records(
    question, {"uqid": None}, question.c["uqid"].in_(duplicate_uqids)
)

# Re-run linking
records = sql_utils.get_records("SELECT * FROM unlinked").to_dict(orient="records")
linker = PIRLinker(records, sql_utils).link().update_unlinked()

# Re-apply changelog changes
duplicate_uqid_query = duplicate_uqid_query.subquery()
changelog = sql_utils.tables["uqid_changelog"]
changelog_query = select(changelog).join(
    duplicate_uqid_query,
    or_(
        changelog.c["original_uqid"] == duplicate_uqid_query.c["uqid"],
        changelog.c["new_uqid"] == duplicate_uqid_query.c["uqid"],
    ),
)
changelog_entries = sql_utils.get_records(changelog_query)

print(changelog_entries)
