"""Tests for pir_pipeline.utils.utils"""

import numpy as np
import pandas as pd
import pytest

from pir_pipeline.utils.utils import nan_or_none


@pytest.mark.parametrize(
    "value",
    [
        None,
        "",
        np.nan,
        float("nan"),
        np.float64("nan"),
        pd.DataFrame({"uqid": [np.nan]}).to_dict("records")[0]["uqid"],
    ],
)
def test_nan_or_none_is_true_for_missing_values(value):
    assert nan_or_none(value)


@pytest.mark.parametrize("value", [0, 0.0, "uqid", "0", False, [], {}])
def test_nan_or_none_is_false_for_present_values(value):
    assert not nan_or_none(value)
