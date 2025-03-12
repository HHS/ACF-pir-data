__all__ = ["get_searchable_columns", "clean_name"]

import re


def get_searchable_columns(columns: list[str]) -> list[str]:
    keep_columns = []
    for column in columns:
        if not column.endswith("id") and column not in ["year"]:
            name = re.sub(r"\W|_", " ", column).title()
            keep_columns.append(name)

    return keep_columns


def clean_name(name: str, how: str = "snake") -> str:
    """Convert a name to a new case

    Args:
        name (str): A name to convert
        how (str): What method to use to convert.\n
            "snake": Converts to snake case.\n
            "title": Converts to title case (can un-snake).

    Returns:
        str: Converted name
    """
    if how == "snake":
        new_name = re.sub(r"\W", "_", name.lower())
        new_name = re.sub(r"_+", "_", new_name)
    elif how == "title":
        new_name = re.sub(r"_", " ", name)
        new_name = new_name.title()

    return new_name
