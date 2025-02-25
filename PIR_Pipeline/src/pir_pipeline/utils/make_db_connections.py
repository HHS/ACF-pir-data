import mysql.connector


def make_db_connections(
    user: str, password: str, host: str, port: int, databases: list[str]
):
    connections = {}
    query = "USE %s"
    for database in databases:
        connection = mysql.connector.connect(
            user=user, password=password, host=host, port=port, database=database
        )
        cursor = connection.cursor(buffered=True)
        connections[database] = cursor.execute(query, database)

    return connections
