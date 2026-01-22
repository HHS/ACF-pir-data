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
    def __init__(self, iterable: Optional[Iterable], loc: int = 0):
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


def get_page():
    db = get_db()
    with db.engine.connect() as connection:
        record_count = connection.execute(
            text("SELECT COUNT(*) FROM proposed_changes")
        ).scalar_one()
        session["max_page"] = ceil(
            record_count / session.get("number_displayed", DEFAULT_DISPLAYED)
        )

    return WrappedList(list(range(session["max_page"]))).to_json()


@bp.route("/", methods=["GET"])
def index():
    session["finalize_page"] = 0
    session["number_displayed"] = session.get("number_displayed", DEFAULT_DISPLAYED)
    session["page"] = get_page()

    return render_template("finalize/finalize.html")


@bp.route("/data", methods=["POST"])
def data():
    db = get_db()

    number_displayed: int = session.get("number_displayed", DEFAULT_DISPLAYED)
    page_tuple = json.loads(session.get("page", get_page()))
    page: WrappedList = WrappedList(*page_tuple)

    response = request.get_json()
    direction: str = response.get("direction")

    if direction is None:
        pass
    elif direction.isdigit():
        number_displayed = int(direction)
        session["number_displayed"] = number_displayed
        page_tuple = json.loads(get_page())
        page = WrappedList(*page_tuple)
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
