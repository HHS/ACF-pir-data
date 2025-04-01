__all__ = ["get_review_data", "get_matches"]

from hashlib import md5

from sqlalchemy import and_, bindparam, distinct, func, select

from pir_pipeline.linking.PIRLinker import PIRLinker
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils
from pir_pipeline.utils.utils import clean_name


def get_review_data(review_type: str, db: SQLAlchemyUtils):
    if review_type == "unlinked":
        table = db._tables["unlinked"]
        query = select(
            table.c.question_id,
            table.c.question_name,
            table.c.question_number,
            table.c.question_text,
        )
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
    question_table = db.tables["question"]

    if review_type == "unlinked":
        query = select(question_table).where(
            question_table.c.question_id == bindparam("question_id")
        )

        records = db.get_records(query, payload["record"])
        matches = PIRLinker(records, db).fuzzy_link(5)
        matches = matches[payload["record"].keys()]
    elif review_type == "intermittent":
        record_query = (
            select(question_table)
            .where(
                question_table.c.uqid == bindparam("uqid"),
                question_table.c.question_name == bindparam("question_name"),
                question_table.c.question_number == bindparam("question_number"),
                question_table.c.question_text == bindparam("question_text"),
            )
            .limit(1)
        )
        records = db.get_records(record_query, payload["record"])
        year_query = select(question_table.c.year).where(
            question_table.c.uqid == bindparam("uqid")
        )
        year_coverage = db.get_records(year_query, payload["record"])["year"].tolist()
        year_coverage = ", ".join([str(yr) for yr in year_coverage])
        year_coverage = f"({year_coverage})"
        matches = (
            PIRLinker(records, db)
            .get_question_data(
                f"SELECT * FROM linked WHERE year NOT IN {year_coverage}"
            )
            .fuzzy_link(5)
        )
        matches = matches[payload["record"].keys()]
    elif review_type == "inconsistent":
        match_query = (
            select(
                question_table.c.question_id,
                question_table.c.question_name,
                question_table.c.question_number,
                question_table.c.question_text,
            )
            .where(question_table.c.uqid == bindparam("uqid"))
            .order_by(question_table.c.question_id)
            .distinct()
        )
        matches = db.get_records(match_query, payload["record"])

    records = matches.to_dict(orient="records")
    columns = [clean_name(col, "title") for col in matches.columns.tolist()]
    records.insert(0, columns)
    return records


def get_search_results(
    column: str, table: str, keyword: str, db: SQLAlchemyUtils
) -> dict:
    table = db.tables[table]
    id_column = [col for col in table.primary_key.c.keys() if col.endswith("id")][0]
    column = clean_name(
        column
    )  # But why not just have the snake_name as the value for the option?

    query = (
        select(table)
        .where(table.c[column].regexp_match(bindparam("keyword")))
        .order_by(table.c[id_column], table.c["year"].desc())
    )

    search_dict = {}
    search_dict["columns"] = [clean_name(col, "title") for col in table.c.keys()]
    with db.engine.connect() as conn:
        result = conn.execute(query, {"keyword": keyword})
        for res in result.all():
            result_dict = {key: res[i] for i, key in enumerate(table.c.keys())}
            ident = result_dict[id_column]
            if ident in search_dict:
                search_dict[ident].append(result_dict)
            else:
                search_dict[ident] = [result_dict]

    return search_dict


class QuestionLinker:
    def __init__(self, data: dict, db: SQLAlchemyUtils):
        self._data = data
        self._db = db

    def link(self):
        record = self._record
        question = self._db.tables["question"]
        distinct_year_query = (
            select(question.c["year"])
            .where(question.c["uqid"] == bindparam("uqid"))
            .distinct()
        )
        base_uqid = record.get("base_uqid")
        base_qid = record.get("base_question_id")
        match_uqid = record.get("match_uqid")
        match_qid = record.get("match_question_id")

        # Matching two questions with existing uqids (intermittent)
        if base_uqid and match_uqid:
            with self._db.engine.connect() as conn:
                result = conn.execute(distinct_year_query, {"uqid": base_uqid})
                base_year_range = result.scalars().all()

            with self._db.engine.connect() as conn:
                result = conn.execute(distinct_year_query, {"uqid": match_uqid})
                match_year_range = result.scalars().all()

            if len(match_year_range) < len(base_year_range):
                base_uqid, match_uqid = match_uqid, base_uqid

            self._db.update_records(
                question,
                {"uqid": bindparam("match_uqid")},
                question.c["uqid"] == bindparam("base_uqid"),
                [{"base_uqid": base_uqid, "match_uqid": match_uqid}],
            )

        # Matching two questions with one or no uqid
        elif not base_uqid:
            if not match_uqid:
                qids_encoded = (base_qid + match_qid).encode("utf-8")
                match_uqid = md5(qids_encoded).hexdigest()

            self._db.update_records(
                question,
                {"uqid": bindparam("match_uqid")},
                question.c["question_id"] == bindparam("base_qid"),
                [{"base_qid": base_qid, "match_uqid": match_uqid}],
            )

    def unlink(self):
        record = self._record
        question = self._db.tables["question"]
        base_uqid = record.get("base_uqid")
        base_qid = record.get("base_question_id")
        match_qid = record.get("match_question_id")

        assert (
            base_qid and match_qid
        ), f"Base ({base_qid}) or match ({match_qid}) missing"

        # Get rows with question_id
        qid_count_query = select(func.count(question.c["question_id"])).where(
            question.c["question_id"] == bindparam("qid")
        )

        # Handle base
        qid_in_uqid_statement = select(distinct(question.c["question_id"])).where(
            and_(
                question.c["uqid"] == bindparam("base_uqid"),
                question.c["question_id"] != bindparam("match_qid"),
            )
        )
        with self._db.engine.connect() as conn:
            result = conn.execute(
                qid_in_uqid_statement, {"base_uqid": base_uqid, "match_qid": match_qid}
            )
            remaining_qids = result.scalars().all()
        # If only one remaining qid, ensure there is more than one occurrence otherwise
        # uqid should be removed entirely
        if len(remaining_qids) == 1:
            with self._db.engine.connect() as conn:
                result = conn.execute(qid_count_query, {"qid": remaining_qids[0]})
                qid_count = result.scalar()

            if qid_count == 1:
                self._db.update_records(
                    question,
                    {"uqid": bindparam("uqid")},
                    question.c["uqid"] == bindparam("base_uqid"),
                    [{"uqid": None, "base_uqid": base_uqid}],
                )

        # Handle match_qid
        with self._db.engine.connect() as conn:
            result = conn.execute(qid_count_query, {"qid": match_qid})
            qid_count = result.scalar()

        # If there is only one occurrence of this qid, uqid should now be none
        if qid_count == 1:
            match_uqid = None
        # Otherwise, ensure uqid is equal to what should occur if matched with self
        elif qid_count > 1:
            qids_encoded = (match_qid + match_qid).encode("utf-8")
            match_uqid = md5(qids_encoded).hexdigest()
        else:
            raise Exception("No matching question_id!")

        # If the newly generated match_uqid is the same as the base_uqid, update the base_uqid
        # Maybe something more sophisticated here to simulate what would happen in the
        # real process?
        if match_uqid == base_uqid:
            qids_encoded = (base_qid + base_qid).encode("utf-8")
            new_uqid = md5(qids_encoded).hexdigest()

            self._db.update_records(
                question,
                {"uqid": bindparam("uqid")},
                question.c["uqid"] == bindparam("base_uqid"),
                [{"uqid": new_uqid, "base_uqid": base_uqid}],
            )

        # Update the matched uqid
        self._db.update_records(
            question,
            {"uqid": bindparam("uqid")},
            question.c["question_id"] == bindparam("match_qid"),
            [{"uqid": match_uqid, "match_qid": match_qid}],
        )

    def update_links(self):
        for key, value in self._data.items():
            self._record = value
            link_type = value["link_type"]
            if link_type == "link":
                self.link()
            elif link_type == "unlink":
                self.unlink()
            else:
                raise AttributeError("Link type should be either 'link' or 'unlink'")


if __name__ == "__main__":
    from pir_pipeline.config import db_config

    # payload = {
    #     "60c274e649282ae77a614d07d39cf117": {
    #         "link_type": "link",
    #         "base_question_id": "00651687997bac132e7162c24894e8f6",
    #         "base_uqid": "",
    #         "match_question_id": "5f0d2515f94334b507e70f1548795664",
    #         "match_uqid": "39859bcb2164236ad93b499eeeaa1e01",
    #     },
    # }
    db = SQLAlchemyUtils(**db_config, database="pir")
    # linker = QuestionLinker(payload, db).update_links()
    get_search_results("question_name", "question", "children", db)
