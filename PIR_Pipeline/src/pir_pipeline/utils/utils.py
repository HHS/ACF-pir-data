__all__ = ["get_searchable_columns", "get_logger"]

import logging
import re


def get_searchable_columns(columns: list[str]) -> list[str]:
    keep_columns = []
    for column in columns:
        if not column.endswith("id") and column not in ["year"]:
            name = re.sub(r"\W|_", " ", column).title()
            keep_columns.append(name)

    return keep_columns


def get_logger(name: str):
    logging.basicConfig(
        format="%(asctime)s|%(name)s|%(levelname)s|%(message)s",
        level=logging.DEBUG,
        datefmt="%Y-%m-%d %I:%M:%S",
    )
    return logging.getLogger(name)
