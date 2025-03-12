__all__ = ["get_searchable_columns", "make_snake_name"]

import re


def get_searchable_columns(columns: list[str]) -> list[str]:
    keep_columns = []
    for column in columns:
        if not column.endswith("id") and column not in ["year"]:
            name = re.sub(r"\W|_", " ", column).title()
            keep_columns.append(name)

    return keep_columns


def make_snake_name(name: str) -> str:
    """Convert a name to snake case

    Args:
        name (str): A name to convert

    Returns:
        str: Snake-cased name
    """
    snake_name = re.sub(r"\W", "_", name.lower())
    snake_name = re.sub(r"_+", "_", snake_name)
    return snake_name
