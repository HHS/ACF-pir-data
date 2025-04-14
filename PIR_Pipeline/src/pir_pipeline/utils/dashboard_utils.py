"""Dashboard utilities for interfacing with the database"""

__all__ = ["get_review_data", "get_matches"]

from collections import OrderedDict, namedtuple
from hashlib import md5

from sqlalchemy import and_, bindparam, distinct, func, select

from pir_pipeline.linking.PIRLinker import PIRLinker
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils
from pir_pipeline.utils.utils import clean_name


def get_review_data(review_type: str, db: SQLAlchemyUtils) -> list:
    """Return data for unlinked, intermittently, and inconsistenly linked questions

    Args:
        review_type (str): The type of question being reviewed
        db (SQLAlchemyUtils): SQLAlchemyUtils object for database interactions

    Returns:
        list: [column_names, record, ..., record]
    """
    qid_columns = ("question_id", "question_name", "question_number", "question_text")
    uqid_columns = ("uqid", "question_name", "question_number", "question_text")

    # Questions missing a uqid
    if review_type == "unlinked":
        table = db._tables["unlinked"]
        query = select(table.c[qid_columns])
    # Questions without a link covering the full time period
    elif review_type == "intermittent":
        table = db._tables["intermittent"]
        query = select(table.c[uqid_columns]).distinct()

    # uqids containing variable question_ids
    elif review_type == "inconsistent":
        table = db._tables["inconsistent"]
        query = select(table.c[uqid_columns]).distinct()

    with db.engine.connect() as conn:
        result = conn.execute(query)
        columns = query.selected_columns.keys()
        data = db.to_dict(result.all(), columns)

    columns = [clean_name(col, "title") for col in columns]
    data.insert(0, columns)

    return data


def get_matches(payload: dict, db: SQLAlchemyUtils) -> list:
    """Return potential matches for a given question or return question_ids
    within an inconsistent question

    Args:
        payload (dict): Dictionary containing the review-type and the record to find
            matches for.\n
            {"review-type": review-type, "record": record}
        db (SQLAlchemyUtils): SQLAlchemyUtils object for database interactions

    Returns:
        list: [column_names, match, ..., match]
    """
    review_type = payload["review-type"]
    question_table = db.tables["question"]

    if review_type == "unlinked":
        # Return the relevant record
        query = select(question_table).where(
            question_table.c.question_id == bindparam("question_id")
        )
        records = db.get_records(query, payload["record"])

        # Get matches
        matches = PIRLinker(records, db).fuzzy_link(5)
        matches = matches[payload["record"].keys()]
    elif review_type == "intermittent":
        # Return the relevant record
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

        # Get the years covered by the record
        year_query = select(question_table.c.year).where(
            question_table.c.uqid == bindparam("uqid")
        )
        year_coverage = db.get_records(year_query, payload["record"])["year"].tolist()
        year_coverage = ", ".join([str(yr) for yr in year_coverage])
        year_coverage = f"({year_coverage})"

        # Get matches
        matches = (
            PIRLinker(records, db)
            .get_question_data(
                f"SELECT * FROM linked WHERE year NOT IN {year_coverage}"
            )
            .fuzzy_link(5)
        )
        matches = matches[payload["record"].keys()]
    elif review_type == "inconsistent":
        # Return the relevant records
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
    qtype: str,
    column: str,
    keyword: str,
    db: SQLAlchemyUtils,
    id_column: str = "question_id",
) -> dict:
    """Return results for the search page

    Args:
        column (str): The column to search on
        table (str): The table to search in
        keyword (str): The term to search for
        db (SQLAlchemyUtils): SQLAlchemyUtils object for database interactions

    Returns:
        dict: Dictionary of search results
    """
    if qtype != "all":
        table = qtype
    else:
        table = "question"

    table = db.tables[table]

    column = clean_name(
        column
    )  # But why not just have the snake_name as the value for the option?
    columns = [id_column, "year", "question_number", "question_name", "question_text"]
    columns = columns + [column] if column not in columns else columns

    columns = OrderedDict([(col, None) for col in columns])
    columns = tuple(columns.keys())

    keyword_query = (
        select(table.c[columns])
        .where(table.c[column].regexp_match(bindparam("keyword")))
        .order_by(table.c[id_column], table.c["year"].desc())
    )

    # Get the maximum year
    max_year_query = (
        select(table.c[id_column], func.max(table.c.year).label("year"))
        .group_by(table.c[id_column])
        .subquery()
    )

    # Get the range of years covered
    year_range_query = (
        select(
            table.c[id_column],
            func.concat(func.min(table.c.year), "-", func.max(table.c.year)).label(
                "year_range"
            ),
        )
        .group_by(table.c[id_column])
        .subquery()
    )

    # Get data for the most recent year to create a header row
    header_row_query = (
        select(table.c[columns], year_range_query.c["year_range"])
        .join(
            max_year_query,
            and_(
                table.c[id_column] == max_year_query.c[id_column],
                table.c.year == max_year_query.c.year,
            ),
        )
        .join(year_range_query, table.c[id_column] == year_range_query.c[id_column])
        .where(table.c[id_column] == bindparam(id_column))
    )

    # Put column headers in search results dictionary
    search_dict = {}
    search_dict["columns"] = [clean_name(col, "title") for col in columns]

    with db.engine.connect() as conn:
        # Get all search results
        result = conn.execute(keyword_query, {"keyword": keyword})

        # Convert results to dictionary
        for res in result.all():
            result_dict = db.to_dict([res], columns)[0]
            ident = result_dict[id_column]

            # Append instances of the same question_id to an existing list
            if ident in search_dict:
                search_dict[ident].append(result_dict)
            # Otherwise, create a summary header row and append that and maximal year
            else:
                header = conn.execute(header_row_query, {id_column: ident})
                header_row = header.one()
                header_row = {key: header_row[i] for i, key in enumerate(header.keys())}
                header_row.update({"year": header_row["year_range"]})
                del header_row["year_range"]
                search_dict[ident] = [header_row, result_dict]

    return search_dict


def get_review_question(table: str, offset: int, db: SQLAlchemyUtils) -> str:
    if table == "unlinked":
        id_column = "question_id"
        columns = ["question_id", "year"]
    else:
        id_column = "uqid"
        columns = ["uqid"]

    columns += [
        "question_name",
        "question_number",
        "question_text",
        "question_type",
        "section",
    ]  # common columns
    columns = tuple(columns)
    table = db.tables[table]

    if table.name in ["inconsistent", "intermittent"]:
        subquery = select(
            table.c[columns],
            func.row_number().over(partition_by=id_column).label("row_num"),
        ).subquery()
        query = (
            select(subquery.c[columns])
            .where(subquery.c["row_num"] == 1)
            .order_by(subquery.c[id_column])
            .limit(1)
            .offset(offset)
            .distinct()
        )
    else:
        query = (
            select(table.c[columns])
            .order_by(table.c[id_column])
            .limit(1)
            .offset(offset)
            .distinct()
        )

    with db.engine.connect() as conn:
        result = conn.execute(query)
        next_id = result.one()

    next_id = {key: next_id[i] for i, key in enumerate(query.selected_columns.keys())}

    return (id_column, next_id)


class QuestionLinker:
    def __init__(self, data: dict, db: SQLAlchemyUtils):
        """QuestionLinker object to handle linking and unlinking of questions

        Args:
            data (dict): A series of instructions for linking/unlinking questions.
                Should be of the form:
                {
                    record_id_1: {
                        "link_type": link or unlink,
                        "base_question_id": qid_1,
                        "base_uqid": uqid_1,
                        "match_question_id": qid_2,
                        "match_uqid": uqid_2
                    },
                    ...
                    record_id_n: {
                        ...
                    }
                }
            db (SQLAlchemyUtils): SQLAlchemyUtils object for database interactions
        """
        self._data = data
        self._db = db
        self._changes = namedtuple("Changes", ["base", "match"])

    def get_ids(self):
        base_uqid = self._record.get("base_uqid")
        base_qid = self._record.get("base_question_id")
        match_uqid = self._record.get("match_uqid")
        match_qid = self._record.get("match_question_id")

        return base_qid, base_uqid, match_qid, match_uqid

    def link(self):
        """Link two questions"""
        question = self._db.tables["question"]
        distinct_year_query = (
            select(question.c["year"])
            .where(question.c["uqid"] == bindparam("uqid"))
            .distinct()
        )
        base_qid, base_uqid, match_qid, match_uqid = self.get_ids()

        changes = self._changes(
            {
                "question_id": base_qid,
                "original_uqid": base_uqid,
                "new_uqid": match_uqid,
            },
            {
                "question_id": match_qid,
                "original_uqid": match_uqid,
                "new_uqid": match_uqid,
            },
        )

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
                changes.base["new_uqid"] = match_uqid
                changes.match["new_uqid"] = match_uqid

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

        self._db.insert_records(changes, "uqid_changelog")

    def unlink(self):
        """Unlink two questions"""
        question = self._db.tables["question"]
        base_qid, base_uqid, match_qid, match_uqid = self.get_ids()

        changes = self._changes(
            {"question_id": base_qid, "original_uqid": base_uqid},
            {
                "question_id": match_qid,
                "original_uqid": base_uqid,
            },
        )

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
                changes.base["new_uqid"] = None

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

        changes.match["new_uqid"] = match_uqid

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

            changes.base["new_uqid"] = new_uqid

        # Update the matched uqid
        self._db.update_records(
            question,
            {"uqid": bindparam("uqid")},
            question.c["question_id"] == bindparam("match_qid"),
            [{"uqid": match_uqid, "match_qid": match_qid}],
        )

        self._db.insert_records(changes, "uqid_changelog")

    def confirm(self):
        base_qid, base_uqid, match_qid, match_uqid = self.get_ids()
        changes = {
            "question_id": base_qid,
            "original_uqid": base_uqid,
            "new_uqid": match_uqid,
            "complete_series_flag": True,
        }
        self._db.insert_records(changes, "uqid_changelog")

    def update_links(self):
        """Update links

        Makes calles to QuestionLinker.link and QuestionLinker.unlink as needed
        """
        for key, value in self._data.items():
            self._record = value
            link_type = value["link_type"]
            if link_type == "link":
                self.link()
            elif link_type == "unlink":
                self.unlink()
            elif link_type == "confirm":
                self.confirm()
            else:
                raise AttributeError("Link type should be either 'link' or 'unlink'")


if __name__ == "__main__":
    from pir_pipeline.config import DB_CONFIG

    db = SQLAlchemyUtils(**DB_CONFIG, database="pir")
    get_review_question("unlinked", 10, db)
