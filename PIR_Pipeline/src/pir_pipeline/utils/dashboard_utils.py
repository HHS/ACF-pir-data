"""Dashboard utilities for interfacing with the database"""

__all__ = ["get_matches"]

from collections import OrderedDict, namedtuple
from hashlib import md5

from sqlalchemy import (
    BinaryExpression,
    String,
    Subquery,
    TableClause,
    and_,
    bindparam,
    distinct,
    func,
    or_,
    select,
)

from pir_pipeline.linking.PIRLinker import PIRLinker
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils
from pir_pipeline.utils.utils import clean_name


def get_matches(payload: dict, db: SQLAlchemyUtils) -> list:
    """Return potential matches for a given question or return question_ids
    within an inconsistent question

    Args:
        payload (dict): Dictionary containing the review-type and the record to find \
        matches for.\n\n\t{"review-type": review-type, "record": record}
        db (SQLAlchemyUtils): SQLAlchemyUtils object for database interactions

    Returns:
        list: [column_names, match, ..., match]
    """

    question_table = db.tables["question"]

    id_column = "question_id"

    query = select(question_table).where(
        question_table.c[id_column] == bindparam(id_column)
    )
    records = db.get_records(query, payload["record"])

    if not records[["question_type", "section"]].any().all():
        return []

    # Get matches
    linker = PIRLinker(records, db)
    if payload["record"]["uqid"]:
        linker._unique_question_id = "uqid"

    matches = linker.fuzzy_link(5)
    matches = matches[payload["record"].keys()]

    records = matches.to_dict(orient="records")
    columns = [clean_name(col, "title") for col in matches.columns.tolist()]
    records.insert(0, columns)
    return records


def get_search_results(
    keyword: str,
    db: SQLAlchemyUtils,
    id_column: str = "question_id",
) -> dict:
    """Return results for the search page

    Args:
        keyword (str): The term to search for
        db (SQLAlchemyUtils): SQLAlchemyUtils object for database interactions
        id_column (str): Column to use as the primary identifier

    Returns:
        dict: Dictionary of search results
    """
    table = "question"
    table = db.tables[table]

    columns = [
        "question_id",
        "uqid",
        "year",
        "question_number",
        "question_name",
        "question_text",
    ]

    columns = OrderedDict([(col, None) for col in columns])
    columns = tuple(columns.keys())

    keyword_query = select(table.c[columns])

    # Adapted from
    # https://stackoverflow.com/questions/34838302/sqlalchemy-adding-or-condition-with-different-filter
    conditions = []
    for column in table.c.keys():
        if db.engine.dialect.name == "mysql":
            conditions.append(table.c[column].regexp_match(bindparam("keyword")))
        else:
            conditions.append(
                func.cast(table.c[column], String).regexp_match(
                    func.cast(bindparam("keyword"), String), "i"
                )
            )

    keyword_query = keyword_query.where(or_(*conditions)).order_by(
        table.c[id_column], table.c["year"].desc()
    )

    # Get the maximum year
    max_year_query = (
        select(table.c[id_column], func.max(table.c.year).label("year"))
        .group_by(table.c[id_column])
        .subquery()
    )

    # Get data for the most recent year to create a header row
    header_row_query = (
        select(table.c[columns])
        .join(
            max_year_query,
            and_(
                table.c[id_column] == max_year_query.c[id_column],
                table.c.year == max_year_query.c.year,
            ),
        )
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

                if header_row.get("uqid"):
                    id_tuple = ("uqid", header_row["uqid"])
                else:
                    id_tuple = ("question_id", header_row["question_id"])

                header_row.update({"year": get_year_range(table, id_tuple, db)})

                if header_row["year"].find("-|,") > -1:
                    search_dict[ident] = [header_row, result_dict]
                else:
                    search_dict[ident] = [header_row]

    return search_dict


def get_review_question(
    table: str, offset: int | str, id_column: str, db: SQLAlchemyUtils
) -> tuple:
    """Get information for the header question on a flashcard page

    Args:
        table (str): The table to search in.
        offset (int | str): The question to return. If integer, return the question at that \
        position. If string return the question with corresponding ID.
        id_column (str): Column serving as the primary identifier.
        db (SQLAlchemyUtils): SQLAlchemyUtils object

    Returns:
        tuple: tuple[string, dict] containing the id_column and the record returned \
        from the searching for the offset.
    """

    def get_where_condition(
        table: TableClause | Subquery, offset: int | str
    ) -> BinaryExpression | bool:
        """Return a where condition

        Args:
            table (TableClause | Subquery): The table to be searched in
            offset (int | str): The record to search for

        Returns:
           BinaryExpression | bool: a sqlalchemy binary expression or True/False
        """

        # When offset is string, then it is an ID. Get that record
        if isinstance(offset, str):
            if isinstance(table, TableClause):
                where_condition = table.c[id_column] == offset
            else:
                where_condition = and_(
                    table.c["row_num"] == 1, table.c[id_column] == offset
                )
            offset = 0
        # When offset is not string, get the appropriate row
        else:
            if isinstance(table, TableClause):
                where_condition = 1 == 1
            else:
                where_condition = table.c["row_num"] == 1

        return where_condition, offset

    columns = [
        "question_id",
        "year",
        "uqid",
        "question_name",
        "question_number",
        "question_text",
        "question_type",
        "section",
    ]

    columns = tuple(columns)
    table = db.tables[table]

    where_condition, offset = get_where_condition(table, offset)

    query = (
        select(table.c[columns])
        .where(where_condition)
        .limit(1)
        .offset(offset)
        .order_by(table.c.year, table.c.question_number)
        .distinct()
    )

    with db.engine.connect() as conn:
        result = conn.execute(query)
        next_id = result.one()

    next_id = {key: next_id[i] for i, key in enumerate(query.selected_columns.keys())}

    return (id_column, next_id)


def search_matches(matches: dict, id_column: str, db: SQLAlchemyUtils) -> dict:
    """Iterate over matches to return all related rows

    Args:
        matches (dict): Dictionary of records
        id_column (str): Colum serving as primary identifier
        db (SQLAlchemyUtils): SQLAlchemyUtils object

    Returns:
        dict: Dictionary containing one entry for each id which itself may contain multiple records
    """
    output = {}
    for match in matches:
        output.update(get_search_results(match[id_column], db, id_column))

    return output


def get_year_range(table: TableClause, _id: tuple[str], db: SQLAlchemyUtils) -> str:
    """Return the range of years covered by the target question

    Args:
        table (TableClause): Table to search in for the year range
        _id (tuple[str]): tuple[column_name, value]. Identifies which question to find \
        the year range for.
        db (SQLAlchemyUtils): SQLAlchemyUtils object

    Returns:
        str: Year range as a string
    """

    query = select(table.c["year"]).where(table.c[_id[0]] == _id[1])
    with db.engine.connect() as conn:
        result = conn.execute(query)
        years = result.scalars().all()

    years = sorted(years)
    if len(years) == 1:
        return str(years[0])

    str_years = []
    prev_year = None
    year_list = []
    for year in years:
        if prev_year == year - 1:
            year_list.append(str(year))
        else:
            year_list = [str(year)]
            str_years.append(year_list)

        prev_year = year

    output = [
        "-".join((item[0], item[-1])) if len(item) > 1 else item[0]
        for item in str_years
    ]
    output = ", ".join(output)

    return output


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
        """Return the ids from the present record"""
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
        """Mark a question as confirmed"""
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
                raise AttributeError(
                    "Link type should be either 'link', 'unlink', 'confirm'"
                )


if __name__ == "__main__":
    from pir_pipeline.config import DB_CONFIG

    db = SQLAlchemyUtils(**DB_CONFIG, database="pir_test")
    print(
        get_year_range(
            db.tables["question"], ("uqid", "903863a832c884bdf311237ed570c44d"), db
        )
    )
