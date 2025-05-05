from collections import namedtuple
from hashlib import sha1

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

@pytest.fixture
def question_linker(sql_utils, question_linker_payload):
    question_linker = QuestionLinker(question_linker_payload, sql_utils)
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
                        "question_id": "0e93c25d3a95604f40d3a64e2298093b4faed6f2",
                        "year": 2011,
                    },
                },
                {"question_id", "year"},
                1,
            ),
            Check(
                {
                    "record": {
                        "question_id": "dd089009542dfd51e45f2f23826dbc7a6f6a912e",
                        "uqid": "e358fa167d3a9d5872f563ec5cfa07898a7ee186",
                        "year": 2009,
                    },
                },
                {"question_id", "uqid", "year"},
                2,
            ),
            Check(
                {
                    "record": {
                        "uqid": "6c9f2d2dcd01048e5163e12a1f50cb8e7c926e43",
                        "question_id": "443a354c772a24df0c2bba9acf568576a3b7d182",
                    },
                },
                {"uqid", "question_id"},
                0,
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
                {"0e93c25d3a95604f40d3a64e2298093b4faed6f2"},
            ),
            Check(
                {
                    "keyword": "child development staff - qualifications",
                },
                {
                    "66e92dd434dc3cccc5e14e3ad4ce710be8c7fb9d",
                    "0e93c25d3a95604f40d3a64e2298093b4faed6f2",
                },
            ),
        ]
        for check in checks:
            data = get_search_results(**check.kwargs, db=sql_utils)
            ids = [key for key in data.keys() if key != "columns"]
            set_diff = set(ids).symmetric_difference(check.ids)
            assert (
                not set_diff
            ), f"IDs do not align: Expected {check.ids}; Got {ids}; Diff {set_diff}"


@pytest.mark.usefixtures("create_database", "insert_question_records")
class TestQuestionLinker:
    def test_update_links(self, question_linker, sql_utils, question_linker_payload):
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
            base_qid, base_uqid, match_qid, match_uqid = get_ids(
                question_linker_payload["1"]
            )
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
            base_qid, base_uqid, match_qid, match_uqid = get_ids(
                question_linker_payload["2"]
            )
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
            expected_uqid = sha1(expected_uqid).hexdigest()
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
            base_qid, base_uqid, match_qid, match_uqid = get_ids(
                question_linker_payload["3"]
            )
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
            base_qid, base_uqid, match_qid, match_uqid = get_ids(
                question_linker_payload["4"]
            )

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
            record = result.first()
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
            base_qid, base_uqid, match_qid, match_uqid = get_ids(
                question_linker_payload["5"]
            )

            result = conn.execute(
                select(uqid_changelog).where(
                    uqid_changelog.c["original_uqid"] == base_uqid
                )
            )
            record = result.one()

            assert record[5] == 1, f"Flag is False: {record[5]}"
            assert record[2] == base_qid, f"Incorrect question_id: {record[2]}"
            assert record[4] is None, f"Record has a new_uqid: {record[4]}"


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_update_links"])
