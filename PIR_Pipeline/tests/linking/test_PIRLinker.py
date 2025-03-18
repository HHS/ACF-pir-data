from unittest.mock import MagicMock

import pandas as pd
import pytest


class TestPIRLinker:
    def test_get_question_data(self):
        question_columns = [
            "question_id",
            "uqid",
            "question_name",
            "question_number",
            "question_order",
            "question_text",
            "question_type",
            "section",
        ]

        # Check that correct columns are returned
        # Check that the correct number of records are returned

    def test_update_unlinked(self):
        # Assert that uqids are updated in final database
        # Confirm that uqids are set to the correct value
        pass

    def test_link(self):
        pass

    def test_fuzzy_link(self):
        pass

    def test_prepare_for_insertion(self):
        pass

    def test_gen_uqid(self):
        pass


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_insert_data"])
