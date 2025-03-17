from unittest.mock import MagicMock

import pandas as pd
import pytest


class TestPIRLinker:
    def test_get_question_data(self, dummy_ingestor, mock_question_data):
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

        question = pd.DataFrame.from_dict(mock_question_data["db"])

        dummy_ingestor._sql.get_columns = MagicMock(return_value=question_columns)
        dummy_ingestor._sql.get_records = MagicMock(return_value=question)
        dummy_ingestor._year = 2008

        dummy_ingestor.get_question_data()

        dummy_ingestor._sql.get_columns.assert_called_once()
        dummy_ingestor._sql.get_records.assert_called_once()

        assert not dummy_ingestor._question["question_id"].duplicated().any()
        assert dummy_ingestor._question.shape == (5, 8)

    def test_update_unlinked(self, data_ingestor, mock_question_data):
        question = pd.DataFrame.from_dict(mock_question_data["linked"])
        data_ingestor._sql.get_records = MagicMock(
            return_value=question[["question_id"]]
        )
        data_ingestor._data["question"] = question

        data_ingestor.update_unlinked()

        data_ingestor._sql.get_records.assert_called_once()
        assert data_ingestor._unlinked.shape == (2, 3)


if __name__ == "__main__":
    pytest.main([__file__, "-sk", "test_insert_data"])
