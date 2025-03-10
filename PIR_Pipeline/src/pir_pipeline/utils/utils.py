import re


def get_searchable_columns(columns: list[str]):
    keep_columns = []
    for column in columns:
        if not column.endswith("id") and column not in ["year"]:
            name = re.sub(r"\W|_", " ", column).title()
            keep_columns.append(name)

    return keep_columns
