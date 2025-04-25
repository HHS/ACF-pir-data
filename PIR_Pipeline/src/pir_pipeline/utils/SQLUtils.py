"""Abstract SQL class"""

from abc import ABC, abstractmethod


class SQLUtils(ABC):
    """Parent class for SQL utility classes"""

    def __init__(self, user: str, password: str, host: str, port: int):
        """Instantiate a SQL utility object

        Args:
            user (str): Database username
            password (str): Database password
            host (str): Database host
            port (int): Database port
        """

        self._DB_CONFIG = {
            "user": user,
            "password": password,
            "host": host,
            "port": port,
        }

    @property
    def DB_CONFIG(self):
        """Database configuration attribute"""

        ...

    @abstractmethod
    def make_connection(self, databases: list[str]):
        """Make a connection to the target database(s)"""

        ...

    def close_connection(self):
        """Close database connection(s)"""

        ...

    @abstractmethod
    def get_records(self, query):
        """Execute a select query and return records"""

        ...

    @abstractmethod
    def get_columns(self, table: str, query: str = None):
        "Get column names from the specified table"

        ...

    @abstractmethod
    def insert_records(self):
        """Insert records in the target table"""

        ...

    @abstractmethod
    def update_records(self):
        """Update records in the target table"""

        ...
