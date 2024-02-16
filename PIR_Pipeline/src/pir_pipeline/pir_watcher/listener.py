import os, time, datetime, subprocess, mysql.connector, shutil

def main(file_info, config):
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    
    db_config = {
        'host' : config["dbhost"],
        'port' : config["dbport"],
        'user' : config['dbusername'],
        'password' : config['dbpassword'],
        'database' : 'pir_logs'
    }
    log_path = config["Listener_Logs"]
    script_path = os.path.join(current_dir, "..", "pir_ingestion", "ingest_data.R")
    r_path = config["R_Path"]
    bat_path = config["Listener_bats"]
    
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor(buffered=True)
    except Exception as e:
        print("command '{}' returned with error (code {}): {}\n".format(e.cmd, e.returncode, e.output))
    
    to_ingest = {}

    for file in file_info.keys():
        current_file = file_info[file]
        if file.split(".")[1] in ["xlsx", "csv", "xls"]:
            to_ingest[file] = current_file
        else:
            shutil.move(current_file["Path"], os.path.join(config["Unprocessed"], file))
    
    current_taskname = "pir_ingestion" + "_" + time.strftime("%Y%m%d_%H%M%S")
    bat_name = current_taskname + ".bat"
    command_path =  os.path.join(bat_path, bat_name)
    paths = [to_ingest[key]['Path'] for key in to_ingest.keys()]
    paths = ' '.join(paths)
    ingestion_log = os.path.join(log_path, "pir_ingestion_logs", "ingestion_log.log")
    schedule_command = 'schtasks /CREATE /TN {} /TR "{}" /SC ONCE /SD {} /ST 01:00 /RU System'
    
    with open(command_path, "w") as f:
        command = r_path + " " + script_path + " " + paths + " >> " + ingestion_log + " 2>&1"
        f.write(command)
    
    target_date = datetime.date.today() # + datetime.timedelta(days = 1)
    schedule_command = schedule_command.format(
            current_taskname, command_path, target_date.strftime("%m/%d/%Y")
    )
    
    query = """
        REPLACE INTO pir_listener_logs
        (run, timestamp, message)
        VALUES
        ('{}', '{}', '{}')
        """
    
    try:
        subprocess.check_output(schedule_command,stderr=subprocess.STDOUT)
        message = "Ingestion scheduled at 01:00am today for files: {}\n".format(paths)
        query = query.format(*[time.strftime("%Y-%m-%d %H:%M:%S"), time.strftime("%Y-%m-%d %H:%M:%S"), message])
        cursor.execute(query)
        conn.commit()
    except subprocess.CalledProcessError as e:
        message = "command '{}' returned with error (code {}): {}\n".format(e.cmd, e.returncode, e.output)
        query = query.format(*[time.strftime("%Y-%m-%d %H:%M:%S"), time.strftime("%Y-%m-%d %H:%M:%S"), message])
        cursor.execute(query)
        conn.commit()
        
    cursor.close()
    conn.close()