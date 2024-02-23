def main(file_info, config, schedule_command):
    import os, time, datetime, subprocess, mysql.connector, shutil
    current_dir = os.path.dirname(os.path.abspath(__file__))

    db_config = {
        'host' : config["dbhost"],
        'port' : config["dbport"],
        'user' : config['dbusername'],
        'password' : config['dbpassword'],
        'database' : 'pir_logs'
    }
    log_path = config["Automated_Pipeline_Logs"]
    script_dir = os.path.join(current_dir, "..", "pir_ingestion")
    script_path = os.path.join(script_dir, "ingest_data.R")
    r_path = config["R_Path"]
    bat_path = config["Listener_bats"]

    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor(buffered=True)
    except Exception as e:
        print([e._full_msg, e.msg, e.errno])
    
    to_ingest = {}

    for file in file_info.keys():
        current_file = file_info[file]
        if file.split(".")[1] in ["xlsx", "xls"]:
            to_ingest[file] = current_file
        else:
            shutil.move(current_file["Path"], os.path.join(config["Unprocessed"], file))
    
    current_task_time = time.strftime("%Y%m%d_%H%M%S")
    current_taskname = "pir_ingestion" + "_" + current_task_time
    bat_name = current_taskname + ".bat"
    command_path =  os.path.join(bat_path, bat_name)
    paths = [to_ingest[key]['Path'] for key in to_ingest.keys()]
    paths = ['"{}"'.format(p) for p in paths]
    paths = ' '.join(paths)
    ingestion_log = os.path.join(log_path, "ingestion_log_{}.log".format(current_task_time))
    
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
    
    target_date = datetime.date.today() + datetime.timedelta(days = 1)
    schedule_command = schedule_command.format(
            current_taskname, command_path, target_date.strftime("%m/%d/%Y")
    )
    
    query = """
        REPLACE INTO pir_logs.listener_logs 
        (run, timestamp, message)
        VALUES
        ('{}', '{}', '{}')
        """
    
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
