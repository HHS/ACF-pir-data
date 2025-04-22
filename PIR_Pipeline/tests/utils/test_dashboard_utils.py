from collections import namedtuple
from hashlib import md5

import pytest
from sqlalchemy import null, select

from pir_pipeline.utils.dashboard_utils import (
    QuestionLinker,
    get_matches,
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
        "base_uqid": None,
        "match_question_id": "87fe124509e4e9e48b26a65b78c87acd",
        "match_uqid": "8cfa414fcd9b593e45bee4dd68080ae8",
    },
    "5": {
        "link_type": "confirm",
        "base_question_id": None,
        "base_uqid": "5512c4f54e3ace4484e59cdc48976761",
        "match_question_id": None,
        "match_uqid": None,
    },
}


@pytest.fixture
def question_linker(sql_utils):
    question_linker = QuestionLinker(payload, sql_utils)
    return question_linker


@pytest.mark.usefixtures("create_database", "insert_question_records")
class TestGetDataMethods:
    def test_get_matches(self, sql_utils):
        # Fields, num_records in each case. Not ids, cause algorithm might change
        Check = namedtuple("Check", ["payload", "fields", "num_records"])
        checks = [
            Check(
                {
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
                    "record": {
                        "question_id": "6b2522aa7ff248ca4d80ac299104ca2e",
                        "uqid": "5ff5919440ca5dcd4c9dbda1eff168d4",
                        "year": 2017,
                    },
                },
                {"question_id", "uqid", "year"},
                2,
            ),
            Check(
                {
                    "record": {
                        "uqid": "00517751cc2f7920185e52926ce7a0c9",
                        "question_id": "4167b6decdcd59db40b69e0fba43e7f0",
                    },
                },
                {"uqid", "question_id"},
                2,
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
                    "keyword": "^Staff$",
                },
                ["83e32d72b46030e1abf5109b8b506fb8"],
            ),
            Check(
                {
                    "keyword": "child development staff - qualifications",
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
        def get_ids(payload: dict):
            return (
                payload["base_question_id"],
                payload["base_uqid"],
                payload["match_question_id"],
                payload["match_uqid"],
            )

        question_linker.update_links()
        question_table = sql_utils.tables["question"]
        uqid_changelog = sql_utils.tables["uqid_changelog"]
        query_template = select(question_table.c["uqid"])

        # In case 1, both uqids should be totally removed from the database
        with sql_utils.engine.connect() as conn:
            base_qid, base_uqid, match_qid, match_uqid = get_ids(payload["1"])
            result = conn.execute(
                select(question_table).where(question_table.c["uqid"] == base_uqid)
            )
            record = result.all()
            assert not record, f"Base UQID still exists: {record}"
            result = conn.execute(
                select(question_table).where(question_table.c["uqid"] == match_uqid)
            )
            assert not result.all(), "Match UQID still exists"
            result = conn.execute(
                select(question_table.c[("question_id", "uqid")]).where(
                    question_table.c["question_id"] == base_qid
                )
            )
            record = result.one_or_none()
            assert not record[1], "Base question_id has a uqid"
            result = conn.execute(
                select(question_table.c[("question_id", "uqid")]).where(
                    question_table.c["question_id"] == match_qid
                )
            )
            record = result.one_or_none()
            assert not record[1], "Base question_id has a uqid"

            # Rows are logged in changelog
            result = conn.execute(
                select(uqid_changelog).where(
                    uqid_changelog.c["original_uqid"] == base_uqid
                )
            )
            record = result.all()
            assert record[0][2] == base_qid, f"Incorrect question_id: {record[0][2]}"
            assert record[0][4] is None, f"Incorrect uqid: {record[0][4]}"

            assert record[1][2] == match_qid, f"Incorrect question_id: {record[1][1]}"
            assert record[1][4] is None, f"Incorrect question_id: {record[1][4]}"

        # In case 2, uqid for match_qid should remain the same, uqid for base_qid should change
        with sql_utils.engine.connect() as conn:
            base_qid, base_uqid, match_qid, match_uqid = get_ids(payload["2"])
            result = conn.execute(
                select(question_table.c["uqid"])
                .where(question_table.c["question_id"] == match_qid)
                .distinct()
            )
            record = result.scalar_one()
            assert record == match_uqid, f"Incorrect match_uqid: {record}"

            result = conn.execute(
                select(question_table.c["uqid"])
                .where(question_table.c["question_id"] == base_qid)
                .distinct()
            )
            record = result.scalar_one()

            expected_uqid = base_qid
            expected_uqid = (expected_uqid + expected_uqid).encode()
            expected_uqid = md5(expected_uqid).hexdigest()
            assert record == expected_uqid, f"Incorrect base_uqid: {record}"

            # Rows are logged in changelog
            result = conn.execute(
                select(uqid_changelog).where(
                    uqid_changelog.c["original_uqid"] == base_uqid
                )
            )
            record = result.all()
            assert record[0][2] == base_qid, f"Incorrect question_id: {record[0][2]}"
            assert record[0][4] == expected_uqid, f"Incorrect uqid: {record[0][4]}"

            assert record[1][2] == match_qid, f"Incorrect question_id: {record[1][2]}"
            assert record[1][4] == match_uqid, f"Incorrect question_id: {record[1][4]}"

        # In case 3, base uqid should be kept the other should be removed
        with sql_utils.engine.connect() as conn:
            base_qid, base_uqid, match_qid, match_uqid = get_ids(payload["3"])
            # Base question has base uqid
            result = conn.execute(
                query_template.where(
                    question_table.c["question_id"] == base_qid
                ).distinct()
            )

            record = result.scalar()

            expected_uqid = base_uqid
            assert record == expected_uqid, f"Incorrect base_uqid: {record}"

            # Match question has match uqid
            result = conn.execute(
                query_template.where(
                    question_table.c["question_id"] == match_qid
                ).distinct()
            )
            record = result.scalar()

            assert record == expected_uqid, f"Incorrect match_uqid: {record}"

            # Match uqid no longer exists
            result = conn.execute(
                query_template.where(question_table.c["uqid"] == match_uqid).distinct()
            )
            record = result.one_or_none()
            assert record is None, f"UQID still exists: {record}"

            # Rows are logged in changelog
            result = conn.execute(
                select(uqid_changelog).where(
                    uqid_changelog.c["original_uqid"] == base_uqid
                )
            )
            record = result.one()
            assert record[2] == base_qid, f"Incorrect question_id: {record[2]}"
            assert record[4] == base_uqid, f"Incorrect uqid: {record[4]}"

            result = conn.execute(
                select(uqid_changelog).where(
                    uqid_changelog.c["original_uqid"] == match_uqid
                )
            )
            record = result.one()

            assert record[2] == match_qid, f"Incorrect question_id: {record[2]}"
            assert record[4] == base_uqid, f"Incorrect question_id: {record[4]}"

        # In case 4 match keeps uqid, base gets match uqid
        with sql_utils.engine.connect() as conn:
            base_qid, base_uqid, match_qid, match_uqid = get_ids(payload["4"])

            # Base question has match uqid
            result = conn.execute(
                query_template.where(
                    question_table.c["question_id"] == base_qid
                ).distinct()
            )
            record = result.scalar()

            assert record == match_uqid, f"Incorrect uqid: {record}"

            # Match question has match uqid
            result = conn.execute(
                query_template.where(
                    question_table.c["question_id"] == base_qid
                ).distinct()
            )
            record = result.scalar()

            assert record == match_uqid, f"Incorrect uqid: {record}"

            # Rows are in the changelog
            result = conn.execute(
                select(uqid_changelog).where(
                    uqid_changelog.c["original_uqid"] == null()
                )
            )
            record = result.one()
            assert record[2] == base_qid, f"Incorrect question_id: {record[2]}"
            assert record[4] == match_uqid, f"Incorrect uqid: {record[4]}"

            result = conn.execute(
                select(uqid_changelog).where(
                    uqid_changelog.c["original_uqid"] == match_uqid
                )
            )
            record = result.one()

            assert record[2] == match_qid, f"Incorrect question_id: {record[2]}"
            assert record[4] == match_uqid, f"Incorrect question_id: {record[4]}"

        # In case 5 record should appear as confirmed in the changelog
        with sql_utils.engine.connect() as conn:
            base_qid, base_uqid, match_qid, match_uqid = get_ids(payload["5"])

            result = conn.execute(
                select(uqid_changelog).where(
                    uqid_changelog.c["original_uqid"] == base_uqid
                )
            )
            record = result.one()

            assert record[5] == 1, f"Flag is False: {record[5]}"
            assert record[2] is None, f"Record has a question_id: {record[2]}"
            assert record[4] is None, f"Record has a new_uqid: {record[4]}"


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_get_matches"])
