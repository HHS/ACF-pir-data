"""General utilities"""

__all__ = ["get_searchable_columns", "clean_name", "get_logger", "new_uqid"]

import logging
import re
import sys
from typing import Any
from uuid import uuid4

import numpy as np


def new_uqid() -> str:
    """Mint a fresh, opaque unique question id (uqid).

    The uqid is a surrogate key used to group a question across years. It is
    intentionally *not* derived from ``question_id`` (a content hash of question
    number + name): deriving it meant two distinct questions that hashed to the
    same ``question_id`` could never be given distinct uqids, making them
    impossible to unlink. Minting an opaque value guarantees uniqueness
    regardless of content collisions.

    Returns:
        str: A fresh uqid (32-char hex), small enough for the existing
        ``uqid`` column and never equal to any pre-existing uqid.
    """
    return uuid4().hex


def error_thrower(logger: logging.Logger, message: str, error_type: Exception):
    """Log and throw an error

    Args:
        logger (logging.Logger): Logger
        message (str): Message to log
        error_type (Exception): Error to throw
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


def get_logger(name: str):
    """Create a logger

    Args:
        name (str): Name of the logger

    Returns:
        logging.Logger: A logger
    """
    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)
    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setLevel(logging.DEBUG)
    formatter = logging.Formatter(
        fmt="%(asctime)s|%(name)s|%(levelname)s|%(message)s",
        datefmt="%Y-%m-%d %I:%M:%S",
    )
    stream_handler.setFormatter(formatter)
    logger.addHandler(stream_handler)

    return logger


def close_logger(logger: logging.Logger):
    """Close a logger

    Args:
        logger (logging.Logger): Logger
    """
    for handler in logger.handlers:
        handler.close()
        logger.removeHandler(handler)


def nan_or_none(value: Any) -> bool:
    if value is None or value is np.nan or value == "":
        return True
    else:
        return False
