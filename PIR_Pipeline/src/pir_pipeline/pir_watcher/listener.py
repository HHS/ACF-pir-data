def main(file_info, config, schedule_command):
    import os, time, datetime, subprocess, mysql.connector, shutil
    current_dir = os.path.dirname(os.path.abspath(__file__))
    # Database configuration settings from the provided config dictionary
    db_config = {
        'host' : config["dbhost"],
        'port' : config["dbport"],
        'user' : config['dbusername'],
        'password' : config['dbpassword'],
        'database' : 'pir_logs'
    }
    # Retrievng the path for pipeline logs, R interpreter,  batch (.bat) files
    log_path = config["Automated_Pipeline_Logs"]
    script_dir = os.path.join(current_dir, "..", "pir_ingestion")
    script_path = os.path.join(script_dir, "ingest_data.R")
    r_path = config["R_Path"]
    bat_path = config["Listener_bats"]

    # Attempt to connect to the MySQL database with the provided settings
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor(buffered=True)
    # If connection fails, print the error details
    except Exception as e:
        print([e._full_msg, e.msg, e.errno])
    
    to_ingest = {}
    
    # Iterate over the files to determine which ones need to be ingested
    for file in file_info.keys():
        current_file = file_info[file]
        if file.split(".")[1] in ["xlsx", "xls"]:
            to_ingest[file] = current_file
        else:
            shutil.move(current_file["Path"], os.path.join(config["Unprocessed"], file))
    
    # Generate a unique name for the current task based on the current time
    current_task_time = time.strftime("%Y%m%d_%H%M%S")
    current_taskname = "pir_ingestion" + "_" + current_task_time
    bat_name = current_taskname + ".bat"
    command_path =  os.path.join(bat_path, bat_name)
    
    # Prepare the paths of files to ingest, adding quotes around each path
    paths = [to_ingest[key]['Path'] for key in to_ingest.keys()]
    paths = ['"{}"'.format(p) for p in paths]
    paths = ' '.join(paths)
    ingestion_log = os.path.join(log_path, "ingestion_log_{}.log".format(current_task_time))
    
    # Write the batch file that will execute the ingestion process
    with open(command_path, "w") as f:
        change_directories = 'cd "{}"\n'.format(os.path.join(current_dir, ".."))
        command = '"{}"'.format(r_path) + ' ' + '"{}"'.format(script_path) + ' ' + paths + ' >> ' + '"{}"'.format(ingestion_log) + ' 2>&1'
        delete_scheduled = "schtasks /DELETE /TN {} /F \n".format(current_taskname)
        delete_self = '(goto) 2>nul & del "%~f0"'
        f.write(change_directories)
        f.write(command)
        f.write("\n")
        f.write(delete_scheduled)
        f.write(delete_self)
    
    # Schedule the ingestion task to run at 01:00 AM the next day
    target_date = datetime.date.today() + datetime.timedelta(days = 1)
    schedule_command = schedule_command.format(
            current_taskname, command_path, target_date.strftime("%m/%d/%Y")
    )

    # Template for inserting log entries into the MySQL database
    query = """
        REPLACE INTO pir_logs.pir_listener_logs 
        (run, timestamp, message)
        VALUES
        ('{}', '{}', '{}')
        """
    # Attempt to schedule the task and log success message, but only when there are files to ingest
    if to_ingest:
        try:
            subprocess.check_output(schedule_command,stderr=subprocess.STDOUT)
            message = "Ingestion scheduled at 01:00am tomorrow for files: {}\n".format(paths)
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
