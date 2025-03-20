__all__ = ["get_review_data"]

import json

from sqlalchemy import func, select

from pir_pipeline.linking.PIRLinker import PIRLinker
from pir_pipeline.models.pir_models import QuestionModel
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils
from pir_pipeline.utils.utils import clean_name


def get_review_data(review_type: str, db: SQLAlchemyUtils):
    if review_type == "unlinked":
        table = db._tables["unlinked"]
        query = select(table)
    elif review_type == "intermittent":
        table = db._tables["question"]
        year_query = select(func.count(func.distinct(table.c.year))).scalar_subquery()
        uqid_query = (
            select(table.c.uqid)
            .group_by(table.c.uqid)
            .having(func.count(table.c.uqid) < year_query)
            .subquery()
        )
        query = (
            select(
                table.c.uqid,
                table.c.question_name,
                table.c.question_number,
                table.c.question_text,
                table.c.section,
                table.c.question_type,
            )
            .where(table.c.uqid.in_(uqid_query))
            .distinct()
        )
    else:
        table = db._tables["linked"]
        subquery = select(table.c.question_id, table.c.uqid).distinct().subquery()
        right = (
            select(subquery.c.uqid)
            .group_by(subquery.c.uqid)
            .having(func.count(subquery.c.question_id) > 1)
            .subquery()
        )
        query = (
            select(
                table.c.uqid,
                table.c.question_name,
                table.c.question_number,
                table.c.question_text,
                table.c.section,
                table.c.question_type,
            )
            .join(right, table.c.uqid == right.c.uqid)
            .distinct()
        )

    with db.engine.connect() as conn:
        result = conn.execute(query)
        data = db.to_dict(result.all(), query.c.keys())

    columns = [clean_name(col, "title") for col in query.c.keys()]
    data.insert(0, columns)

    return data


def get_matches(payload: dict, db: SQLAlchemyUtils) -> list:
    review_type = payload["review-type"]

    if review_type == "unlinked":
        record = QuestionModel.model_validate(payload["record"]).model_dump_json()
        record = json.loads(record)
        records = [record]
        matches = PIRLinker(records, db).fuzzy_link(5)
    elif review_type == "intermittent":
        records = [payload["record"]]
        year_coverage = db.get_records(
            f"SELECT `year` FROM question WHERE uqid = '{payload["record"]["uqid"]}'"
        )["year"].tolist()
        year_coverage = ", ".join([str(yr) for yr in year_coverage])
        year_coverage = f"({year_coverage})"
        matches = (
            PIRLinker(records, db)
            .get_question_data(
                f"SELECT * FROM linked WHERE `year` NOT IN {year_coverage}"
            )
            .fuzzy_link(5)
        )
    elif review_type == "inconsistent":
        pass

    records = matches.to_dict(orient="records")
    columns = [clean_name(col, "title") for col in matches.columns.tolist()]
    records.insert(0, columns)
    return records
