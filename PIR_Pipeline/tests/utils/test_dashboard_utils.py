from collections import namedtuple
from hashlib import md5

import pytest
from sqlalchemy import text

from pir_pipeline.utils.dashboard_utils import (
    QuestionLinker,
    get_matches,
    get_review_data,
    get_search_results,
)


@pytest.fixture(scope="class")
def insert_question_records(sql_utils, question_linker_records):
    sql_utils.insert_records(question_linker_records, "question")


payload = {
    "1": {
        "link_type": "unlink",
        "base_question_id": "42d3b624c74d07c3a574a4f26fa3c686",
        "base_uqid": "194ed0fc57877f9ee8eee0fc5927b148",
        "match_question_id": "0686c2ad4d3041b580a1d4015b9f0c80",
        "match_uqid": "194ed0fc57877f9ee8eee0fc5927b148",
    },
    "2": {
        "link_type": "unlink",
        "base_question_id": "7bfb25407153bbbb171e5d2280c1194f",
        "base_uqid": "00517751cc2f7920185e52926ce7a0c9",
        "match_question_id": "4167b6decdcd59db40b69e0fba43e7f0",
        "match_uqid": "00517751cc2f7920185e52926ce7a0c9",
    },
    "3": {
        "link_type": "link",
        "base_question_id": "6b2522aa7ff248ca4d80ac299104ca2e",
        "base_uqid": "5ff5919440ca5dcd4c9dbda1eff168d4",
        "match_question_id": "3dc2c6572e8b64ffd64231c43ccd95d6",
        "match_uqid": "0b19c17c60bfce95f963a1ddc0575588",
    },
    "4": {
        "link_type": "link",
        "base_question_id": "83e32d72b46030e1abf5109b8b506fb8",
        "base_uqid": "",
        "match_question_id": "87fe124509e4e9e48b26a65b78c87acd",
        "match_uqid": "8cfa414fcd9b593e45bee4dd68080ae8",
    },
}


@pytest.fixture
def question_linker(sql_utils):
    question_linker = QuestionLinker(payload, sql_utils)
    return question_linker


@pytest.mark.usefixtures("create_database", "insert_question_records")
class TestGetDataMethods:
    def test_get_review_data(self, sql_utils):
        Check = namedtuple("Check", ["review_type", "id_var", "ids"])
        checks = [
            Check("unlinked", "question_id", ["83e32d72b46030e1abf5109b8b506fb8"]),
            Check(
                "intermittent",
                "uqid",
                [
                    "194ed0fc57877f9ee8eee0fc5927b148",
                    "0b19c17c60bfce95f963a1ddc0575588",
                    "00517751cc2f7920185e52926ce7a0c9",
                    "5ff5919440ca5dcd4c9dbda1eff168d4",
                    "8cfa414fcd9b593e45bee4dd68080ae8",
                ],
            ),
            Check(
                "inconsistent",
                "uqid",
                [
                    "194ed0fc57877f9ee8eee0fc5927b148",
                    "00517751cc2f7920185e52926ce7a0c9",
                ],
            ),
        ]
        for check in checks:
            data = get_review_data(check.review_type, sql_utils)
            ids = [d[check.id_var] for d in data if isinstance(d, dict)]
            set_diff = set(ids).symmetric_difference(set(check.ids))
            assert not set_diff, f"IDs do not align: {set_diff}"

    def test_get_matches(self, sql_utils):
        # Fields, num_records in each case. Not ids, cause algorithm might change
        Check = namedtuple("Check", ["payload", "fields", "num_records"])
        checks = [
            Check(
                {
                    "review-type": "unlinked",
                    "record": {
                        "question_id": "83e32d72b46030e1abf5109b8b506fb8",
                        "year": 2011,
                    },
                },
                {"question_id", "year"},
                1,
            ),
            Check(
                {
                    "review-type": "intermittent",
                    "record": {
                        "uqid": "194ed0fc57877f9ee8eee0fc5927b148",
                        "question_name": "Of the number of education and child development staff that left, the number that left for the following primary reason - Other - Specify Text",
                        "question_number": "B.18.d-1",
                        "question_text": "Other (e.g., change in job field, reason not provided)",
                    },
                },
                {"uqid", "question_number", "question_name", "question_text"},
                1,
            ),
            Check(
                {
                    "review-type": "inconsistent",
                    "record": {"uqid": "00517751cc2f7920185e52926ce7a0c9"},
                },
                {"question_id", "question_name", "question_number", "question_text"},
                3,
            ),
        ]
        for check in checks:
            matches = get_matches(check.payload, sql_utils)
            matches.pop(0)
            assert (
                len(matches) == check.num_records
            ), f"Incorrect record count. Expected: {check.num_records}; got: {len(matches)}"
            column_check = [
                m in check.fields for match in matches for m in match.keys()
            ]
            assert all(
                column_check
            ), f"Incorrect columns in one or more matches\n: {matches}"

    def test_get_search_results(self, sql_utils):
        Check = namedtuple("Check", ["kwargs", "ids"])
        checks = [
            Check(
                {
                    "column": "category",
                    "keyword": "^Staff$",
                    "qtype": "all",
                },
                ["83e32d72b46030e1abf5109b8b506fb8"],
            ),
            Check(
                {
                    "column": "subsection",
                    "keyword": "child development staff - qualifications",
                    "qtype": "all",
                },
                [
                    "83e32d72b46030e1abf5109b8b506fb8",
                    "87fe124509e4e9e48b26a65b78c87acd",
                ],
            ),
        ]
        for check in checks:
            data = get_search_results(**check.kwargs, db=sql_utils)
            ids = [key for key in data.keys() if key != "columns"]
            set_diff = set(ids).symmetric_difference(set(check.ids))
            assert not set_diff, f"IDs do not align: {set_diff}"


@pytest.mark.usefixtures("create_database", "insert_question_records")
class TestQuestionLinker:
    def test_update_links(self, question_linker, sql_utils):
        question_linker.update_links()

        # In case 1, both uqids should be totally removed from the database
        with sql_utils.engine.connect() as conn:
            result = conn.execute(
                text(
                    f"SELECT * FROM question WHERE uqid = '{payload["1"]["base_uqid"]}'"
                )
            )
            record = result.all()
            assert not record, f"Base UQID still exists: {record}"
            result = conn.execute(
                text(
                    f"SELECT * FROM question WHERE uqid = '{payload["1"]["match_uqid"]}'"
                )
            )
            assert not result.all(), "Match UQID still exists"
            result = conn.execute(
                text(
                    f"SELECT question_id, uqid FROM question WHERE question_id = '{payload["1"]["base_question_id"]}'"
                )
            )
            record = result.one_or_none()
            assert not record[1], "Base question_id has a uqid"
            result = conn.execute(
                text(
                    f"SELECT question_id, uqid FROM question WHERE question_id = '{payload["1"]["match_question_id"]}'"
                )
            )
            record = result.one_or_none()
            assert not record[1], "Base question_id has a uqid"

        # In case 2, uqid for match_qid should remain the same, uqid for base_qid should change
        with sql_utils.engine.connect() as conn:
            result = conn.execute(
                text(
                    f"SELECT DISTINCT uqid FROM question WHERE question_id = '{payload["2"]["match_question_id"]}'"
                )
            )
            record = result.one_or_none()
            assert (
                record[0] == payload["2"]["match_uqid"]
            ), f"Incorrect match_uqid: {record[0]}"

            result = conn.execute(
                text(
                    f"SELECT DISTINCT uqid FROM question WHERE question_id = '{payload["2"]["base_question_id"]}'"
                )
            )
            record = result.one_or_none()

            expected_uqid = payload["2"]["base_question_id"]
            expected_uqid = (expected_uqid + expected_uqid).encode()
            expected_uqid = md5(expected_uqid).hexdigest()
            assert record[0] == expected_uqid, f"Incorrect base_uqid: {record[0]}"


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_get_matches"])
