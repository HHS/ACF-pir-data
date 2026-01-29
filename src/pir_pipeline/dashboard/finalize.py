import json
from collections.abc import Sequence
from math import ceil
from typing import Iterable, Optional

from flask import Blueprint, render_template, request, session
from sqlalchemy import select, text

from pir_pipeline.dashboard.db import get_db

bp = Blueprint("finalize", __name__, url_prefix="/finalize")

DEFAULT_DISPLAYED = 10


class WrappedList(Sequence):
    def __init__(self, iterable: Optional[Iterable | str], loc: int = 0):
        if isinstance(iterable, str):
            self.collection = json.loads(iterable)
        elif iterable:
            self.collection = iterable
        else:
            self.collection = tuple()

        self.loc = loc
        self.max_index = self.__len__() - 1

    def __getitem__(self, key):
        return self.collection[key]

    def __len__(self):
        return self.collection.__len__()

    def __repr__(self):
        string = f"""Pages: {self.collection};\nCurrent Page: {self.loc}"""
        return string

    @property
    def current(self):
        return self[self.loc]

    def next(self):
        self.loc = self.loc + 1 if self.loc < self.max_index else 0
        return self[self.loc]

    def previous(self):
        self.loc = self.loc - 1 if self.loc != 0 else self.max_index
        return self[self.loc]

    def to_json(self):
        js = [self.collection, self.loc]
        return json.dumps(js)


def get_page(number_displayed: Optional[int] = None) -> WrappedList:
    if session.get("page") and not number_displayed:
        page_tuple = json.loads(session.get("page"))
        page_wrapped = WrappedList(*page_tuple)
    else:
        db = get_db()
        denominator = number_displayed or session.get(
            "number_displayed", DEFAULT_DISPLAYED
        )
        loc = 0
        with db.engine.connect() as connection:
            record_count = connection.execute(
                text("SELECT COUNT(*) FROM proposed_changes")
            ).scalar_one()
            session["max_page"] = ceil(record_count / denominator)
        if session.get("page") and number_displayed:
            previous_page = json.loads(session.get("page"))[1]
            offset = previous_page * session.get("number_displayed", DEFAULT_DISPLAYED)
            loc = offset // number_displayed

        page_range = range(session["max_page"])
        page_list = list(page_range)
        page_wrapped = WrappedList(page_list, loc)

    return page_wrapped


@bp.route("/", methods=["GET"])
def index():
    session["finalize_page"] = 0
    session["number_displayed"] = session.get("number_displayed", DEFAULT_DISPLAYED)
    session["page"] = get_page().to_json()

    return render_template("finalize/finalize.html")


@bp.route("/data", methods=["POST"])
def data():
    db = get_db()

    number_displayed: int = session.get("number_displayed", DEFAULT_DISPLAYED)
    page: WrappedList = get_page()

    response = request.get_json()
    direction: str = response.get("direction")

    if direction is None:
        pass
    elif direction.isdigit():
        number_displayed = int(direction)
        page = get_page(number_displayed)
        session["number_displayed"] = number_displayed
    elif direction == "next":
        page.next()
    else:
        page.previous()

    session["page"] = page.to_json()

    proposed_changes = db.tables["proposed_changes"]
    query = (
        select(proposed_changes)
        .limit(number_displayed)
        .offset(page.current * number_displayed)
    )
    records = db.get_records(query)

    return records.to_dict(orient="index")
