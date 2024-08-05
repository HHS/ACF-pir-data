# Import necessary modules for database connection, file handling, pattern matching, and timing
import mysql.connector, os, json, glob, re, time

def main():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    # Set up database configuration using the loaded settings
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

    time.sleep(1)

    # Identify additional SQL files, excluding those already executed        
    files = [file for file in glob.glob(sql_dir + "/**/**/*") if os.path.isfile(file) and not file in schemas]

    retries = 0
    # Attempt to execute the remaining SQL files
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

                file_name = re.search(r"(?<=\\|\/)\w+\.sql$", files[0]).group(0)

                files.pop(0)
        except Exception as e:
            # On failure, print error message and rotate the problematic file to the end of the list for a retry
            file_name = re.search(r"(?<=\\|\/)\w+\.sql$", files[0]).group(0)

            files.append(files.pop(0))
            retries += 1
            # If too many retries occur, terminate the script
            if retries > 10:
                exit()

    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()