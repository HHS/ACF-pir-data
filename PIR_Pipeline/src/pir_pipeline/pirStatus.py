def main():
    # Import necessary modules for operating system interactions, database connection, JSON parsing, and argument parsing
    import os, mysql.connector, json, argparse
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())
    # Setup database configuration for connection
    db_config = {
        'host' : config["dbhost"],
        'port' : config["dbport"],
        'user' : config['dbusername'],
        'password' : config['dbpassword'],
        'database' : 'pir_logs'
    }
    # Initialize argument parser to define and parse command-line arguments
    parser = argparse.ArgumentParser(
        prog="pir-status",
        description="Get status of PIR pipeline."
    )
    parser.add_argument('--ingestion', action='store_true')
    parser.add_argument('--links', action='store_true')
    
    args = parser.parse_args()
    # Attempt to establish a connection to the MySQL database
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor(buffered=True)
    except Exception as e:
        print([e._full_msg, e.msg, e.errno])
    # If the ingestion argument is specified, query the most recent ingestion logs
    if args.ingestion:
        query = """
        SELECT * 
        FROM pir_ingestion_logs 
        WHERE run = (
            SELECT max(run)
            FROM pir_ingestion_logs
        )
        """

        cursor.execute(query)
        result = cursor.fetchall()
        
        print("Most recent ingestion log entries")
        output = {}
        i = 0
        for run, time, message in result:
            i += 1
            output[i] = {}
            output[i]['run'] = run.strftime("%Y/%m/%d, %H:%M:%S")
            output[i]['time'] = time.strftime("%Y/%m/%d, %H:%M:%S")
            output[i]['message'] = message
        print(json.dumps(output, indent=2))
    # If the links argument is specified, query the most recent question linkage logs    
    if args.links:
        query = """
        SELECT * 
        FROM pir_logs.pir_question_linkage_logs
        WHERE run = (
            SELECT max(run)
            FROM pir_logs.pir_question_linkage_logs
        )
        """
        cursor.execute(query)
        result = cursor.fetchall()
        
        print("Most recent question link log entries")
        output = {}
        i = 0
        for run, time, message in result:
            i += 1
            output[i] = {}
            output[i]['run'] = run.strftime("%Y/%m/%d, %H:%M:%S")
            output[i]['time'] = time.strftime("%Y/%m/%d, %H:%M:%S")
            output[i]['message'] = message
        print(json.dumps(output, indent=2))