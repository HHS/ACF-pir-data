"""Dashboard utilities for interfacing with the database"""

__all__ = ["get_matches"]

import re
from collections import OrderedDict, namedtuple

from sqlalchemy import (
    BinaryExpression,
    String,
    Subquery,
    TableClause,
    and_,
    bindparam,
    func,
    or_,
    select,
    union,
)

from pir_pipeline.linking.PIRLinker import PIRLinker
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils
from pir_pipeline.utils.utils import clean_name, nan_or_none, new_uqid


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
    if payload["record"].get("uqid"):
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
    years: list[int] = [],
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

    # Escape keyword (https://stackoverflow.com/questions/4202538/escape-special-characters-in-a-python-string)
    keyword = re.escape(keyword)

    # Create regex match query
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
        table.c["uqid"], table.c["year"].desc()
    )
    if years:
        keyword_query = keyword_query.where(and_(table.c["year"].in_(years)))

    # Put column headers in search results dictionary
    search_dict = {}
    search_dict["columns"] = [clean_name(col, "title") for col in columns]

    with db.engine.connect() as conn:
        # Get all search results
        question_ids = conn.execute(
            select(keyword_query.c["question_id"])
            .distinct()
            .where(keyword_query.c["question_id"].is_not(None)),
            {"keyword": keyword},
        ).scalars()
        uqids = conn.execute(
            select(keyword_query.c["uqid"])
            .distinct()
            .where(keyword_query.c["uqid"].is_not(None)),
            {"keyword": keyword},
        ).scalars()
        search_query = (
            select(table.c[columns])
            .where(
                or_(
                    table.c["question_id"].in_(question_ids), table.c["uqid"].in_(uqids)
                )
            )
            .order_by(table.c["uqid"], table.c["year"].desc())
        )
        result = conn.execute(search_query)

        # Group every matched row by its identifier (uqid when present, else
        # question_id). Rows arrive ordered by (uqid, year desc), so the first
        # row seen for an identifier is its most-recent year. The query returns
        # every year for each matched identifier, so the header row and full
        # year range can both be derived in memory -- no per-question queries.
        for res in result.all():
            result_dict = db.to_dict([res], columns)[0]
            id_column = (
                "uqid" if not nan_or_none(result_dict.get("uqid")) else "question_id"
            )
            ident = result_dict[id_column]

            # Append instances of the same identifier to an existing list
            if ident in search_dict:
                search_dict[ident].append(result_dict)
            # Otherwise seed the group with a summary header row (a copy of the
            # most-recent-year row); its year cell is filled in below.
            else:
                header_row = dict(result_dict)
                search_dict[ident] = [header_row, result_dict]

    # Replace each header row's year with the collapsed range built from the
    # group's own rows (matching get_year_range, but without extra queries).
    for ident, rows in search_dict.items():
        if ident == "columns":
            continue
        header_row, *data_rows = rows
        header_row["year"] = _format_year_range([row["year"] for row in data_rows])

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


def search_matches(matches: dict, db: SQLAlchemyUtils) -> dict:
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
        id_column = "uqid" if not nan_or_none(match.get("uqid")) else "question_id"
        output.update(get_search_results(match[id_column], db, id_column))

    return output


def _format_year_range(years: list[int]) -> str:
    """Collapse a list of years into a compact range string.

    Consecutive years are collapsed into ``start-end`` spans; non-consecutive
    years are listed individually, e.g. ``[2019, 2020, 2021, 2023]`` ->
    ``"2019-2021, 2023"``.

    Args:
        years (list[int]): Years to collapse (may contain duplicates/unsorted).

    Returns:
        str: Year range as a string.
    """
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

    if _id[0] == "uqid":
        query = select(table.c["year"]).where(table.c[_id[0]] == _id[1])
    else:
        query = select(table.c["year"]).where(
            and_(table.c["question_id"] == _id[1], table.c["uqid"] == None)
        )
    with db.engine.connect() as conn:
        result = conn.execute(query)
        years = result.scalars().all()

    return _format_year_range(years)


class QuestionLinker:
    """QuestionLinker class to handle linking and unlinking of questions"""

    def __init__(self, data: list[dict], db: SQLAlchemyUtils, log: bool = True):
        """QuestionLinker object to handle linking and unlinking of questions

        Args:
            data (dict): A series of instructions for linking/unlinking questions.
                Should be of the form:
                [
                    {
                        "link_type": link or unlink,
                        "base_question_id": qid_1,
                        "base_uqid": uqid_1,
                        "match_question_id": qid_2,
                        "match_uqid": uqid_2
                    },
                    ...
                    {
                        ...
                    }
                ]
            db (SQLAlchemyUtils): SQLAlchemyUtils object for database interactions
            log (bool): Boolean to determin whether to write to changelog. Defaults to True.
        """

        self._data = data
        self._db = db
        self._log = log
        self._changes = namedtuple("Changes", ["base", "match"])

    def get_ids(self):
        """Return the ids from the present record.

        When the record carries a ``base_year``/``match_year``, the uqid lookup
        is narrowed to that ``(question_id, year)`` row. This matters under a
        ``question_id`` collision, where the same question_id can sit under
        different uqids across years and a lookup by question_id alone would
        return an arbitrary one.
        """
        question = self._db.tables["question"]

        base_qid = self._record.get("base_question_id")
        match_qid = self._record.get("match_question_id")
        base_year = self._record.get("base_year")
        match_year = self._record.get("match_year")

        def lookup_uqid(qid, year):
            stmt = select(question.c["uqid"]).where(
                question.c["question_id"] == bindparam("question_id")
            )
            params = {"question_id": qid}
            if year is not None:
                stmt = stmt.where(question.c["year"] == bindparam("year"))
                params["year"] = year
            return self._db.get_scalar(stmt, params)

        base_uqid = lookup_uqid(base_qid, base_year)
        match_uqid = lookup_uqid(match_qid, match_year)

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

        # Matching two questions with existing uqids
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
        else:
            if not match_uqid and not base_uqid:
                match_uqid = new_uqid()
            elif base_uqid or match_uqid:
                if match_uqid:
                    pass
                elif base_uqid:
                    match_uqid = base_uqid
                    base_qid = match_qid

            changes.base["new_uqid"] = match_uqid
            changes.match["new_uqid"] = match_uqid

            self._db.update_records(
                question,
                {"uqid": bindparam("match_uqid")},
                question.c["question_id"] == bindparam("base_qid"),
                [{"base_qid": base_qid, "match_uqid": match_uqid}],
            )

        self.log(changes)

    def unlink(self):
        """Unlink a question (or a single question-year) from its group.

        When the record carries a ``match_year`` the peel targets only that
        ``(question_id, year)`` row; otherwise every year of ``match_qid`` is
        peeled out (the prior whole-question behavior). A peeled set of one row
        becomes unlinked (``uqid`` None); a multi-row set stays together under a
        fresh uqid. The group being unlinked from is dissolved if a single row
        is left behind, since a uqid should never group a lone question-year.
        """
        question = self._db.tables["question"]
        base_qid, base_uqid, match_qid, _ = self.get_ids()
        match_year = self._record.get("match_year")

        assert (
            base_qid and match_qid
        ), f"Base ({base_qid}) or match ({match_qid}) missing"

        changes = self._changes(
            {
                "question_id": base_qid,
                "original_uqid": base_uqid,
                "new_uqid": base_uqid,
            },
            {
                "question_id": match_qid,
                "original_uqid": base_uqid,
            },
        )

        # Predicate selecting the row(s) to peel out of base_uqid. A match_year
        # narrows this to a single (question_id, year) row, which is what makes
        # it possible to separate questions that share a question_id.
        match_pred = question.c["question_id"] == bindparam("match_qid")
        match_params = {"match_qid": match_qid}
        if match_year is not None:
            match_pred = and_(match_pred, question.c["year"] == bindparam("match_year"))
            match_params["match_year"] = match_year

        # One row peeled -> unlinked (None); multiple -> keep as their own group.
        peel_count = self._db.get_scalar(
            select(func.count(question.c["question_id"])).where(match_pred),
            match_params,
        )
        if not peel_count:
            raise Exception("No matching question_id!")
        match_uqid = None if peel_count == 1 else new_uqid()

        self._db.update_records(
            question,
            {"uqid": bindparam("uqid")},
            match_pred,
            [{**match_params, "uqid": match_uqid}],
        )
        changes.match["new_uqid"] = match_uqid

        # Dissolve base_uqid if only a single row now remains in it.
        if base_uqid is not None:
            remaining = self._db.get_scalar(
                select(func.count(question.c["question_id"])).where(
                    question.c["uqid"] == bindparam("base_uqid")
                ),
                {"base_uqid": base_uqid},
            )
            if remaining is not None and remaining <= 1:
                self._db.update_records(
                    question,
                    {"uqid": bindparam("uqid")},
                    question.c["uqid"] == bindparam("base_uqid"),
                    [{"uqid": None, "base_uqid": base_uqid}],
                )
                changes.base["new_uqid"] = None

        self.log(changes)

    def confirm(self):
        """Mark a question as confirmed"""
        base_qid, base_uqid, match_qid, match_uqid = self.get_ids()
        changes = {
            "question_id": base_qid,
            "original_uqid": base_uqid,
            "new_uqid": match_uqid,
            "complete_series_flag": True,
        }
        self.log(changes)

    def log(self, changes: dict):
        if self._log:
            self._db.insert_records(changes, "uqid_changelog")

        return self

    def update_links(self):
        """Update links

        Makes calles to QuestionLinker.link and QuestionLinker.unlink as needed
        """
        for value in self._data:
            try:
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
            except Exception as e:
                print(f"Error inserting {value}: {e}")
                continue


def pending(db: SQLAlchemyUtils):
    question = db.tables["question"]
    proposed_changes = db.tables["proposed_changes"]
    # First subquery
    subquery1 = select(
        (
            func.jsonb_array_elements(proposed_changes.c.link_dict).op("->")(
                "base_question_id"
            )
        ).label("question_id")
    )

    # Second subquery
    subquery2 = select(
        (
            func.jsonb_array_elements(proposed_changes.c.link_dict).op("->")(
                "match_question_id"
            )
        ).label("question_id")
    )

    # Union them together
    query = union(subquery1, subquery2)
    with db.engine.connect() as conn:
        result = conn.execute(query)
        proposed_ids = result.scalars().fetchall()

    query = select(question.c["uqid"]).where(
        question.c["question_id"].in_(proposed_ids)
    )
    with db.engine.connect() as conn:
        result = conn.execute(query)
        proposed_ids.extend(result.scalars().fetchall())

    proposed_ids = list(set(proposed_ids))
    proposed_ids.remove(None)

    return proposed_ids


def confirmed(db: SQLAlchemyUtils):
    confirmed = db.get_records("SELECT DISTINCT question_id FROM confirmed")
    return confirmed["question_id"].unique().tolist()


def all_years(db: SQLAlchemyUtils):
    question = db.tables["question"]
    years = db.get_scalar(select(func.count(question.c.year.distinct())), {})
    all_years = db.get_records(
        f"SELECT DISTINCT uqid FROM question GROUP BY uqid HAVING COUNT(uqid) = {years}"
    )

    return all_years["uqid"].unique().tolist()


if __name__ == "__main__":
    from pir_pipeline.config import DB_CONFIG

    db = SQLAlchemyUtils(**DB_CONFIG, database="pir")
    QuestionLinker(
        [
            {
                "link_type": "unlink",
                "base_question_id": "ce1ef764997fee8b182fadc446fce30a683c5477",
                "match_question_id": "ce1ef764997fee8b182fadc446fce30a683c5477",
            },
            {
                "link_type": "confirm",
                "base_question_id": "ce1ef764997fee8b182fadc446fce30a683c5477",
                "match_question_id": None,
            },
        ],
        db,
    ).update_links()
