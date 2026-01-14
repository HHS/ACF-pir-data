import json
from collections.abc import Sequence
from math import ceil
from typing import Iterable, Optional

from flask import Blueprint, render_template, request, session
from sqlalchemy import select, text

from pir_pipeline.dashboard.db import get_db

bp = Blueprint("finalize", __name__, url_prefix="/finalize")


class WrappedList(Sequence):
    def __init__(self, iterable: Optional[Iterable]):
        if isinstance(iterable, str):
            self.collection = json.loads(iterable)
        elif iterable:
            self.collection = iterable
        else:
            self.collection = tuple()

        self.loc = 0
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
        return json.dumps(self.collection)


def get_page():
    db = get_db()
    with db.engine.connect() as connection:
        record_count = connection.execute(
            text("SELECT COUNT(*) FROM proposed_changes")
        ).scalar_one()
        session["max_page"] = ceil(record_count / 10)

    return WrappedList(list(range(session["max_page"]))).to_json()


@bp.route("/", methods=["GET"])
def index():
    session["finalize_page"] = 0
    session["number_displayed"] = 10
    session["page"] = get_page()

    return render_template("finalize/finalize.html")


@bp.route("/data", methods=["POST"])
def data():
    db = get_db()

    number_displayed = session.get("number_displayed")
    page: WrappedList = WrappedList(session.get("page", get_page()))

    response = request.get_json()
    direction = response.get("direction")

    if direction is None:
        pass
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
