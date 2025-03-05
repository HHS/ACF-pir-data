import os

import pandas as pd
import pytest

if __name__ == "__main__":
    from question import question
else:
    from .question import question

from pir_pipeline.ingestion.PIRIngestor import PIRIngestor


@pytest.fixture
def dummy_ingestor():
    return PIRIngestor(
        "", {"user": "", "password": "", "host": "", "port": ""}, database="pir"
    )


class TestPIRIngestor:
    def test_duplicate_question_error(self, dummy_ingestor):
        columns = ["question_name", "question_number"]
        df = pd.DataFrame.from_dict(question)
        df = dummy_ingestor.duplicated_question_error(df, columns)
        question_order = [1, 3, 4, 5]
        assert df["question_order"].tolist() == question_order
        assert not df[columns].duplicated().any()


if __name__ == "__main__":
    pytest.main([__file__, "-s"])
