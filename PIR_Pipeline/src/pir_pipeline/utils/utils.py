__all__ = ["get_searchable_columns", "clean_name", "get_logger"]

import logging
import re


def error_thrower(logger: logging.Logger, message: str, error_type: Exception):
    """_summary_

    Args:
        logger (logging.Logger): _description_
        message (str): _description_
        error_type (Exception): _description_

    Raises:
        error_type: _description_
    """

    logger.error(message)
    raise error_type(message)


def get_searchable_columns(columns: list[str]) -> list[str]:
    """Return non-identifying columns formatted for external audiences

    Args:
        columns (list[str]): A list of column names

    Returns:
        list[str]: Formatted column names
    """

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
        how (str): What method to use to convert.\n\n\t"snake": Converts to snake case.\n\n\t"title": Converts to title case (can un-snake).

    Returns:
        str: Converted name
    """
    if how == "snake":
        new_name = re.sub(r"\W", "_", name.lower())
        new_name = re.sub(r"_+", "_", new_name)
    elif how == "title":
        new_name = re.sub(r"_", " ", name)
        new_name = new_name.title()
        new_name = re.sub(r"\bId\b", "ID", new_name)
        if new_name in ["Uqid", "Uid"]:
            new_name = new_name.upper()

    return new_name


def get_logger(name: str) -> logging.Logger:
    """Return a logger

    Args:
        name (str): Name of the logger

    Returns:
        logging.Logger: Logger
    """

    logging.basicConfig(
        format="%(asctime)s|%(name)s|%(levelname)s|%(message)s",
        level=logging.DEBUG,
        datefmt="%Y-%m-%d %I:%M:%S",
    )
    return logging.getLogger(name)
