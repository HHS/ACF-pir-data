import win32serviceutil
import win32service
import win32event
import servicemanager
import socket
import time

class AppServerSvc(win32serviceutil.ServiceFramework):
    _svc_name_ = "PIRWatcher"
    _svc_display_name_ = "PIR Folder Watcher"
    _svc_description_ = "Watches the PIR folder for xlsx and xls files to ingest."
    
    def __init__(self, args):
        win32serviceutil.ServiceFramework.__init__(self, args)
        self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
        socket.setdefaulttimeout(60)
        self.running = True
        
    def SvcStop(self):
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        win32event.SetEvent(self.hWaitStop)
        self.running = False
        
    def SvcDoRun(self):
        servicemanager.LogMsg(
            servicemanager.EVENTLOG_INFORMATION_TYPE, servicemanager.PYS_SERVICE_STARTED,
            (self._svc_name_, '')
        )
        while self.running:
            self.main()
            time.sleep(60)
        
    def main(self):
        import watcher, json, os
        current_dir = os.path.dirname(os.path.abspath(__file__))
        config_json = os.path.join(current_dir, "..", "config.json")
        config = open(config_json)
        config = json.loads(config.read())
        watcher.FolderWatcher(config)            
    
if __name__ == '__main__':
    win32serviceutil.HandleCommandLine(AppServerSvc)