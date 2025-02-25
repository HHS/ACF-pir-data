__all__ = ["get_schemas", "make_db_connections"]

import mysql.connector


def make_db_connections(
    user: str, password: str, host: str, port: int, databases: list[str]
) -> dict[mysql.connector.MySQLConnection]:
    connections = {}
    for database in databases:
        connection = mysql.connector.connect(
            user=user, password=password, host=host, port=port, database=database
        )
        connections[database] = connection

    return connections


def get_schemas(
    connection: mysql.connector.MySQLConnection, tables: list[str]
) -> dict[list | tuple]:
    cursor = connection.cursor(buffered=True)
    schemas = {}
    for table in tables:
        query = "SHOW COLUMNS FROM %s" % (table)
        cursor.execute(query)
        description = cursor.description
        header = [row[0] for row in description]
        values = cursor.fetchall()
        values.insert(0, header)
        schemas[table] = values

    return schemas
