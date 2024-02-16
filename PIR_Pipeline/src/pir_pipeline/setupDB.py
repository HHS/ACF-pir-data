def main():
    import mysql.connector, os, json, glob
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())

    db_config = {
        'host' : config["dbhost"],
        'port' : config["dbport"],
        'user' : config['dbusername'],
        'password' : config['dbpassword']
    }

    # Get all sql files
    sql_dir = os.path.join(current_dir, "pir_sql")
    files = [file for file in glob.glob(sql_dir + "/**/*") if os.path.isfile(file)]

    # Establish db connection

    for file in files:
        with open(file, 'r') as f:
            conn = mysql.connector.connect(**db_config)
            cursor = conn.cursor(buffered=True)
            content = f.read()
            cursor.execute(content)
            cursor.close()
            conn.close()

    cursor.close()
    conn.close()