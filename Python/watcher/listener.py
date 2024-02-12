import os, time, datetime, subprocess

def main(file_info, log_path, r_path, script_path):
    to_ingest = {}
    for file in file_info.keys():
        current_file = file_info[file]
        if file.split(".")[1] in ["xlsx", "csv", "xls"]:
            to_ingest[file] = current_file
    
    current_taskname = "pir_ingestion" + "_" + time.strftime("%Y%m%d_%H%M%S")
    bat_name = current_taskname + ".bat"
    command_path =  os.path.join(log_path, "pir_bat_files", bat_name)
    paths = [to_ingest[key]['Path'] for key in to_ingest.keys()]
    paths = ' '.join(paths)
    ingestion_log = os.path.join(log_path, "pir_ingestion_logs", "ingestion_log.log")
    with open(command_path, "w") as f:
        command = "cd C:\\OHS-Project-1\\ACF-pir-data \n" + r_path + " " + script_path + " " + paths + " >> " + ingestion_log + " 2>&1"
        f.write(command)
    
    if len(to_ingest) == 1:
        if to_ingest[0]['Size'] <= 10:
            target_date = datetime.date.today() + datetime.timedelta(days = 1)
            schedule_command = 'schtasks /Create /TN ' + current_taskname + ' /TR ' + ' "' + command_path + '" ' + '/SC ONCE /SD ' + target_date.strftime("%m/%d/%Y") + ' /ST 03:00' + " /RU System"
            
    else:
        target_date = datetime.date.today() + datetime.timedelta(days = 1)
        schedule_command = 'schtasks /Create /TN ' + current_taskname + ' /TR ' + ' "' + command_path + '" ' + '/SC ONCE /SD ' + target_date.strftime("%m/%d/%Y") + ' /ST 03:00' + " /RU System"
    
    # try:
    #     # os.system(schedule_command)
    #     subprocess.run(schedule_command, stdin=subprocess.DEVNULL, check = True)
    # except Exception as e:
    #     with open(os.path.join(log_path, "pir_listener_logs", "temp_listener_log.log"), 'w') as f:
    #         f.write(e.__str__())
    try:
        subprocess.check_output(schedule_command,stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        with open(os.path.join(log_path, "pir_listener_logs", "temp_listener_log.log"), 'w') as f:
            f.write("command '{}' return with error (code {}): {}".format(e.cmd, e.returncode, e.output))