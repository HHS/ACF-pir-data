def main():
    import mysql.connector, os, json, glob, re, time
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())

    db_config = {
        'host' : config["dbhost"],
        'port' : config["dbport"],
        'user' : config["dbusername"],
        'password' : config["dbpassword"]
    }

    # Get all sql files
    sql_dir = os.path.join(current_dir, "pir_sql")
    schemas = [file for file in glob.glob(sql_dir + "/**/*") if os.path.isfile(file)]

    # Establish db connection

    for schema in schemas:
        with open(schema, 'r') as f:
            conn = mysql.connector.connect(**db_config)
            cursor = conn.cursor(buffered=True)
            content = f.read()
            cursor.execute(content)
            cursor.close()
            conn.close()
            
    files = [file for file in glob.glob(sql_dir + "/**/**/*") if os.path.isfile(file) and not file in schemas]

    retries = 0
    while files:

        try:
            with open(files[0], 'r') as f:
                conn = mysql.connector.connect(**db_config)
                cursor = conn.cursor(buffered=True)
                content = f.read()
                delimiters = re.compile('DELIMITER (//|;)')
                content = re.sub(delimiters, "", content)
                content = re.sub("//", "", content)
                cursor.execute(content)
                cursor.close()
                conn.close()
                files.pop(0)
        except Exception as e:
            print("command '{}' returned with error (code {}): {}\n".format(e.msg, e.errno, e.errno))
            files.append(files.pop(0))
            retries += 1
            if retries > 10:
                exit()

    cursor.close()
    conn.close()