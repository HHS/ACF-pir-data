from unittest.mock import MagicMock

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

    def test_link(self):
        pass

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

    def test_prepare_for_insertion(self):
        pass

    def test_gen_uqid(self):
        pass

    def test_update_unlinked(self):
        # Assert that uqids are updated in final database
        # Confirm that uqids are set to the correct value
        pass


if __name__ == "__main__":
    pytest.main([__file__, "-s", "-vv", "-k", "test_fuzzy_link"])
