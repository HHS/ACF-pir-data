##################################################################
##  Created by: Sankar Kalaga
##  Description: This script gets the details fo the files in the PIR directory
##  It will logs the file details to json file
##  In addition it will sends the details to a webpage
##################################################################

class WatcherObject {
    [string]$logFile
    [string]$directoryPath
    [string]$script_path
    [string]$install_dir
    [string]$log_dir
    [string]$security_dir
    [string]$unprocessed_dir
    [string]$processed_dir
    [string]$details
    [System.IO.FileSystemWatcher]$Watcher

    WatcherObject([string]$logFilePath, [string]$dirPath, [string]$script_path, 
    [string]$install_dir, [string]$log_dir, [string]$security_dir,  
    [string]$unprocessed_dir, [string]$processed_dir) {
        $this.logFile = $logFilePath
        $this.directoryPath = $dirPath
        $this.script_path = $script_path
        $this.install_dir = $install_dir
        $this.log_dir = $log_dir
        $this.security_dir = $security_dir
        $this.unprocessed_dir = $unprocessed_dir
        $this.processed_dir = $processed_dir
        $this.ProcessDirectory()
    }
        
    [void] ClearLogFile() {
        # Clear the content of the log file
        Clear-Content -Path $this.logFile
    }

    [void] ProcessDirectory() {
        # Clear the content of the log file
        $this.ClearLogFile()

        # Check if the directory exists
        if (Test-Path $this.directoryPath -PathType Container) {
            # Get all files in the directory
            $files = Get-ChildItem -Path $this.directoryPath
            $fileDetailsList = @()
            $static_paths = @(
                @{
                    script_path    = $this.script_path
                    install_dir    = $this.install_dir
                    log_dir        = $this.log_dir
                    security_dir   = $this.security_dir
                    unprocessed_dir = $this.unprocessed_dir
                    processed_dir  = $this.processed_dir
                    FileCount      = $files.Count 
                }
            )

            $fileDetailsList += $static_paths
            
            # Process each file
            foreach ($file in $files) {
                $fileDetails = @{
                    Name           = $file.Name
                    Basename       = $file.Basename
                    Size           = $file.Length
                    Type           = $file.Extension
                    DateStamp      = Get-Date -Format "yyyyMMdd_HHmmss"
                    LastWriteTime  = $file.LastWriteTime | Get-Date -Format "yyyyMMdd_HHmmss"
                }

                $fileDetailsList += $fileDetails
            }

            # Check if the JSON file exists, create a new one if not
            $this.details = $fileDetailsList | ConvertTo-Json 
            if (!(Test-Path -Path $this.logFile)) {
                $fileDetailsList | ConvertTo-Json | Out-File -Force -FilePath $this.logFile
            } else {
                # Append to the existing JSON file
                $existingFileDetails = Get-Content -Raw -Path $this.logFile | ConvertFrom-Json
                $fileDetailsList += $existingFileDetails
                $fileDetailsList | ConvertTo-Json | Out-File -Force -FilePath $this.logFile
            }

            # Write the total number of files to the log file
            #"Total number of files: $($files.Count)" | Out-File -Append -FilePath $this.logFile

            # Host the JSON file on a local web host
            Start-Job -ScriptBlock {
                $listener = New-Object System.Net.HttpListener
                $listener.Prefixes.Add("http://localhost:8080/")
                $listener.Start()

                $context = $listener.GetContext()
                $response = $context.Response

                $jsonContent = Get-Content -Raw -Path $using:this.logFile
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonContent)
                $response.ContentLength64 = $buffer.Length

                $output = $response.OutputStream
                $output.Write($buffer, 0, $buffer.Length)
                $output.Close()

                $listener.Stop()
                $listener.Close()
            }
        } else {
            # Write an error message to the log file
            "Directory not found: $($this.directoryPath)" | Out-File -Append -FilePath $this.logFile
        }
    }
}


# Path for log file to log the file details
$logFile = "C:\OHS-Project-1\watcher_obj_updated\Log_Filedetails\File_names_params.json"
# Additional parameters
$script_path = "C:\OHS-Project-1\ACF-pir-data\ingestion\ingest_data.R"
$install_dir = ""
$log_dir = "C:\OHS-Project-1\ACF-pir-data\logs\automated_pipeline_logs\listener"
$security_dir = ""
$unprocessed_dir = "C:\OHS-Project-1\ACF-pir-data\tests\data\unprocessed"
$processed_dir = "C:\OHS-Project-1\ACF-pir-data\tests\data\processed"

$watcherObject = [WatcherObject]::new(
    $logFile, $unprocessed_dir, $script_path, $install_dir, 
    $log_dir, $security_dir, $unprocessed_dir, $processed_dir
)

# Call the function to process the directory Indefinite while loop
while ($true) {
    $watcherObject.ProcessDirectory()
    Start-Sleep -Seconds 1
}
