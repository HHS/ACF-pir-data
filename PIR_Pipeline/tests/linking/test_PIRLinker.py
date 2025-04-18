import hashlib

import numpy as np
import pandas as pd
import pytest


@pytest.mark.usefixtures("create_database")
class TestPIRLinker:
    def test_get_question_data(self, pir_linker, question_records):
        question_columns = {
            "question_id",
            "uqid",
            "year",
            "question_name",
            "question_number",
            "question_order",
            "question_text",
            "question_type",
            "section",
        }

        pir_linker.get_question_data()
        question_set = set(pir_linker._question.columns)
        assert (
            question_columns == question_set
        ), f"Incorrect columns: {question_columns.symmetric_difference(question_set)}"
        assert pir_linker._question.shape[0] == len(question_records)

    def test_direct_link(self, pir_linker):
        pir_linker.direct_link()
        linked_records = pir_linker._linked.shape[0]
        expected_linked_records = pir_linker._question["question_id"].nunique()
        assert (
            linked_records == expected_linked_records
        ), f"Incorrect number of records for linked: {linked_records}"
        assert pir_linker._unlinked.empty, "Unlinked should be empty"

    def test_fuzzy_link(self, pir_linker):
        with pytest.raises(AssertionError):
            pir_linker.fuzzy_link()

        matches = pir_linker.fuzzy_link(5)
        expected_len = pir_linker._question["question_id"].nunique() * 5
        actual_len = len(matches)
        assert (
            actual_len == expected_len
        ), f"Incorrect length. Expected: {expected_len}; Got: {actual_len}"

        pir_linker._unlinked = pir_linker._data.copy()
        pir_linker.join_on_type_and_section("unlinked")

        pir_linker._linked = pd.DataFrame(
            columns=[
                "question_id",
                "year",
                "category",
                "question_name",
                "question_number",
                "question_order",
                "question_text",
                "question_type",
                "section",
                "subsection",
                "linked_id",
                "uqid",
            ]
        )
        pir_linker.fuzzy_link()
        assert pir_linker._unlinked.empty, "Unlinked should be empty"
        assert (
            pir_linker._linked.shape[0] == pir_linker._question["question_id"].nunique()
        ), "Linked is the incorrect shape"

    def test_prepare_for_insertion(self, pir_linker, question_columns):
        initial_record_count = pir_linker._data.shape[0]
        pir_linker.direct_link().prepare_for_insertion()
        columns = set(pir_linker._data.columns)
        final_record_count = pir_linker._data.shape[0]
        assert (
            question_columns == columns
        ), f"Incorrect columns: {question_columns.symmetric_difference(columns)}"
        assert (
            initial_record_count == final_record_count
        ), f"Record counts differ: Initial: {initial_record_count}; Final: {final_record_count}"
        assert pir_linker._data["uqid"].notna().all(), "All uqids should be non-missing"

    def test_gen_uqid(self, pir_linker):
        index_names = ["question_id", "linked_id", "uqid"]
        uqid_dict = {"linked_id_3": "some_hash"}
        data = [
            (
                pd.Series(
                    index_names,
                    index=index_names,
                ),
                "uqid",
            ),
            (pd.Series(["question_id", np.nan, ""], index=index_names), np.nan),
            (
                pd.Series(["question_id", "linked_id_2", ""], index=index_names),
                hashlib.md5("question_idlinked_id_2".encode()).hexdigest(),
            ),
            (
                pd.Series(["question_id_2", "linked_id_3", ""], index=index_names),
                "some_hash",
            ),
        ]
        for input, output in data:
            result = pir_linker.gen_uqid(input, uqid_dict)
            assert (output == result) or (
                output is result
            ), f"Incorrect value: {output} != {result}"

    def test_update_unlinked(self, pir_linker):
        # Assert that uqids are updated in final database
        # Confirm that uqids are set to the correct value
        def check_uqid(row: pd.Series):
            expected_uqid = row["question_id"] + row["question_id"]
            assert row["uqid"] == hashlib.md5(expected_uqid.encode()).hexdigest()

        pir_linker.link().update_unlinked()
        linked = pir_linker._sql.get_records("SELECT * from linked")
        unlinked = pir_linker._sql.get_records("SELECT * from unlinked")
        assert unlinked.empty, "Unlinked should be empty"
        linked.apply(check_uqid, axis=1)

    def test_dummy(self):
        assert True is False


if __name__ == "__main__":
    pytest.main([__file__, "-s", "-vv", "-k", "test_update_unlinked"])
