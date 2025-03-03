from abc import ABC, abstractmethod


class SQLUtils(ABC):
    def __init__(self, user: str, password: str, host: str, port: int):
        self._db_config = {
            "user": user,
            "password": password,
            "host": host,
            "port": port,
        }

    @property
    def db_config(self):
        pass

    @abstractmethod
    def make_connection(self, databases: list[str]): ...

    def close_connection(self):
        self._connection.close()

        return self

    @abstractmethod
    def get_schemas(self, tables: list[str]) -> dict[list | tuple]: ...

    @abstractmethod
    def get_records(self, query): ...

    @abstractmethod
    def get_columns(self, table: str, query: str = None): ...

    @abstractmethod
    def insert_records(self): ...

    @abstractmethod
    def update_records(self): ...
