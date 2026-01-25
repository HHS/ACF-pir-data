import os
from typing import MutableSequence

from pandas import DataFrame
from sqlalchemy import func, or_, select, text, Select, bindparam

os.environ["RDS_CREDENTIALS"] = "True"

from pir_pipeline.config import DB_CONFIG
from pir_pipeline.linking.PIRLinker import PIRLinker
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils
from pir_pipeline.utils.dashboard_utils import QuestionLinker

SQL_UTILS = SQLAlchemyUtils(**DB_CONFIG, database="pir_data")
QUESTION = SQL_UTILS.tables["question"]


def copy_question_table():
    # Copy question table (Adapted from Gemini)
    with SQL_UTILS.engine.connect() as conn:
        query = text("CREATE TABLE question_temp AS TABLE question")
        conn.execute(query)
        conn.commit()


def get_duplicate_uqids():
    """Get the duplicated uqids and question_ids"""
    # Get duplicated uqids
    duplicate_uqid_query = (
        select(QUESTION.c[("uqid", "year")])
        .group_by(QUESTION.c[("uqid", "year")])
        .having(func.count(QUESTION.c["uqid"]) > 1)
    )

    duplicate_uqid_df = SQL_UTILS.get_records(duplicate_uqid_query)
    duplicate_uqids = duplicate_uqid_df["uqid"].unique().tolist()

    # Get the question IDs associated with the duplicate uqids
    duplicate_qid_query = select(QUESTION.c[("uqid", "question_id")]).where(
        QUESTION.c["uqid"].in_(duplicate_uqids)
    )
    duplicate_qid_df = SQL_UTILS.get_records(duplicate_qid_query)
    associated_question_ids = duplicate_qid_df["question_id"].unique().tolist()

    return (
        duplicate_uqids,
        associated_question_ids,
        duplicate_qid_df,
        duplicate_uqid_query,
    )


def set_duplicated_uqids_to_null(duplicate_uqids: MutableSequence):
    # Set duplicated uqids to null
    SQL_UTILS.update_records(
        QUESTION, {"uqid": None}, QUESTION.c["uqid"].in_(duplicate_uqids)
    )


def re_link():
    # Re-run linking
    SQL_UTILS.create_db()
    records = SQL_UTILS.get_records("SELECT * FROM unlinked").to_dict(orient="records")
    PIRLinker(records, SQL_UTILS).link().update_unlinked()


def re_apply_changelog_changes(duplicate_uqids: MutableSequence):
    # Re-apply changelog changes
    changelog = SQL_UTILS.tables["uqid_changelog"]

    # Get records from changelog that have uqids i
    changelog_query = select(changelog).where(
        or_(
            changelog.c["original_uqid"].in_(duplicate_uqids),
            changelog.c["new_uqid"].in_(duplicate_uqids),
        )
    )
    changelog_entries = SQL_UTILS.get_records(changelog_query)

    changelog_entries = changelog_entries.to_dict(orient="records")

    # Extract only linking actions
    changes = {}
    question_ids = []
    for i, entry in enumerate(changelog_entries):
        if entry["new_uqid"] and entry["original_uqid"] != entry["new_uqid"]:
            base_question_id = entry["question_id"]
            base_uqid = entry["original_uqid"]
            match_uqid = entry["new_uqid"]

            match_question_id_query = select(QUESTION.c["question_id"]).where(
                QUESTION.c["uqid"] == bindparam("uqid")
            )
            match_question_id = SQL_UTILS.get_scalar(
                match_question_id_query, {"uqid": match_uqid}
            )

            changes[i] = {
                "link_type": "link",
                "base_question_id": base_question_id,
                "base_uqid": base_uqid,
                "match_question_id": match_question_id,
                "match_uqid": match_uqid,
            }

            question_ids.append(base_question_id)

    # Apply the changes
    QuestionLinker(changes, SQL_UTILS, log=False).update_links()

    # Confirm that the question_ids are consistent before and after the correction
    for question_id in question_ids:
        new_uqid_query = (
            select(QUESTION.c["uqid"])
            .where(QUESTION.c["question_id"] == question_id)
            .distinct()
        )
        old_uqid_query = text(
            f"SELECT DISTINCT uqid FROM question_temp WHERE question_id = '{question_id}'"
        )
        with SQL_UTILS.engine.connect() as conn:
            result = conn.execute(old_uqid_query)
            old_uqid = result.scalar_one()
            result = conn.execute(new_uqid_query)
            new_uqid = result.scalar_one()

        if new_uqid:
            assert (
                old_uqid == new_uqid
            ), f"Old and new uqids are different: old uqid: {old_uqid}; new_uqid: {new_uqid};"


def post_correction_checks(
    duplicate_uqids: MutableSequence,
    associated_question_ids: MutableSequence,
    duplicate_df: DataFrame,
):
    # Confirm that all uqids are still present
    uqid_query = select(QUESTION.c["uqid"]).distinct()
    uqids = SQL_UTILS.get_records(uqid_query)["uqid"].tolist()
    duplicate_set = set(duplicate_uqids)
    comprehensive_set = set(uqids)
    assert duplicate_set.issubset(
        comprehensive_set
    ), f"Some UQIDs lost: {duplicate_set.difference(comprehensive_set)}"

    # Check the question_ids
    question_id_query = (
        select(QUESTION)
        .where(QUESTION.c["question_id"].in_(associated_question_ids))
        .order_by(QUESTION.c[("question_id", "year")])
    )
    results = SQL_UTILS.get_records(question_id_query)
    results = results.merge(duplicate_df, "inner", ["question_id"])


def add_unique_constraint():
    constraint_query = text("""
        ALTER TABLE question
        ADD CONSTRAINT uq_question_uqid
        UNIQUE (uqid, year)
        """)
    with SQL_UTILS.engine.begin() as conn:
        conn.execute(constraint_query)


def revert_or_drop_temp_table(revert: bool = False):
    drop_query = text("DROP TABLE question_temp")
    queries = [drop_query]
    if revert:
        # Overwrite new table with old info
        update_string = []
        for column in QUESTION.c:
            if not column.primary_key:
                update_string.append(f"{column.name} = EXCLUDED.{column.name}")
        query = text(f"""
            INSERT INTO question 
            SELECT * 
            FROM question_temp
            ON CONFLICT ON CONSTRAINT pk_question DO UPDATE
            SET {', '.join(update_string)}
            """)
        queries.insert(0, query)

        # Remove unique constraint.
        query = text("ALTER TABLE question DROP CONSTRAINT uq_question_uqid RESTRICT")
        queries.insert(0, query)

    with SQL_UTILS.engine.begin() as conn:
        for query in queries:
            conn.execute(query)


def main():
    try:
        copy_question_table()
    except Exception as e:
        print("Failed to copy question table stopping")
        raise e

    try:
        duplicate_uqids, associated_question_ids, duplicate_df, duplicate_uqid_query = (
            get_duplicate_uqids()
        )
        set_duplicated_uqids_to_null(duplicate_uqids)
        re_link()

        add_unique_constraint()

        re_apply_changelog_changes(duplicate_uqids)
        post_correction_checks(duplicate_uqids, associated_question_ids, duplicate_df)
        revert_or_drop_temp_table()
    except Exception as e:
        print("FAILED: Reverting question table")
        revert_or_drop_temp_table(revert=True)
        raise e


if __name__ == "__main__":
    main()
