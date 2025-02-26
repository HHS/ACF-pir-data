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
    def make_db_connections(self, databases: list[str]): ...

    def close_db_connections(self):
        for connection in self._connections.values():
            connection.close()

        return self

    @abstractmethod
    def get_schemas(self, connection, tables: list[str]) -> dict[list | tuple]: ...

    @abstractmethod
    def get_records(self, connection, query): ...

    @abstractmethod
    def get_columns(self, connection: str, table: str, query: str = None): ...
