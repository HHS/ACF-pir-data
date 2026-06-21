import argparse
import json
import sys
from io import StringIO
from typing import Self

import boto3
import numpy as np
import pandas as pd

from pir_pipeline.query import helpers
from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils

s3 = boto3.client("s3")


class PirQuery:
    def __init__(self):
        self.parser: argparse.Namespace
        self.data: dict[str, dict | list[dict]] | list[dict[str, dict | list[dict]]]
        self.records: list[dict] = []

        self.parse_args(sys.argv[1:]).setup()

    def parse_args(self, args: list[str]) -> Self:
        parser = argparse.ArgumentParser(
            prog="pir-query", description="Query the PIR database"
        )
        parser.add_argument(
            "file", type=str, help="JSON file containing query instructions"
        )
        parser.add_argument(
            "credentials", type=str, help="JSON file containing database credentials"
        )

        self.parser = parser.parse_args(args)

        return self

    def setup(self) -> Self:
        with open(self.parser.file, "rb") as f:
            self.data = json.load(f)

        with open(self.parser.credentials, "rb") as f:
            self.sql_utils: SQLAlchemyUtils = SQLAlchemyUtils(**json.load(f))

        return self

    def query(self, data: dict) -> Self:
        aggregate_by: list[str] = data.pop("aggregate_by")
        records = helpers.get_responses(self.sql_utils, data)

        AGG = helpers.AGG_DEFAULTS
        pop_keys = set()

        df = pd.DataFrame.from_records(records).replace("nan", np.nan)

        if not aggregate_by:
            records = df.to_dict(orient="records")
            self.records.extend(records)
            return self
        else:
            for var in aggregate_by:
                try:
                    AGG.pop(var)
                except KeyError:
                    continue

            aggregate_by.extend(["uqid", "year"])

        df["answer"] = df["answer"].astype("float64")

        if "grant_number" not in aggregate_by:
            for key in AGG:
                if key.startswith("grant"):
                    pop_keys.add(key)

        if (
            not any([var.startswith("program") for var in aggregate_by])
            and "grant_number" not in aggregate_by
            and "agency_id" not in aggregate_by
        ):
            for key in AGG:
                if (
                    key.startswith("program")
                    or key.startswith("grant")
                    or key == "agency_id"
                ):
                    pop_keys.add(key)
        elif (
            any([var.startswith("program") for var in aggregate_by])
            and "grant_number" not in aggregate_by
            and "agency_id" not in aggregate_by
        ):
            for key in AGG:
                if (
                    key.startswith("program")
                    or key.startswith("grant")
                    or key == "agency_id"
                ) and key not in aggregate_by:
                    pop_keys.add(key)

        for key in pop_keys:
            AGG.pop(key)

        df["uqid"] = df["uqid"].combine_first(df["question_id"])
        df = df.groupby(aggregate_by).agg(**AGG).reset_index().drop(columns=["uqid"])
        records = df.to_dict(orient="records")

        self.records.extend(records)

        return self

    def disaggregate_queries(self, data: dict) -> Self:
        for question in data["question"]:
            datum = {
                "program": data["program"].copy(),
                "question": [question],
                "aggregate_by": data["aggregate_by"].copy(),
            }
            self.query(datum)

        return self

    def write(self, data: dict):
        csv = StringIO()
        pd.DataFrame.from_records(self.records).to_csv(csv, index=False)
        csv.seek(0)
        s3.put_object(
            Body=csv.read().encode(),
            Bucket=data["bucket"],
            Key=data["key"],
        )

    def main(self):
        if isinstance(self.data, list):
            for datum in self.data:
                self.disaggregate_queries(datum)
                self.write(datum)
        elif isinstance(self.data, dict):
            self.disaggregate_queries(self.data)
            self.write(self.data)
        else:
            raise TypeError(f"self.data is of invalid type: {type(self.data)}")
