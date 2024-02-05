##################################################################
##  Created by: Sankar Kalaga
##  Description: Creates_watcher_service_for getting the details of the   
##  files present in the PIR directory
##  It uses a powershell script with no params/oop 
##################################################################

# Set the path to the PowerShell executable
$powerShellExe =  "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"

# Set the path to the PowerShell script
$scriptPath = "C:\OHS-Project-1\ACF-pir-data\PowerShell\listener.ps1"

# Set the name of the service
$serviceName = "TestListener"

# Set the description of the service
$serviceDescription = "Listens for changes in the PIR directory"

# Install the service using NSSM
& ".\nssm.exe" install $serviceName $powerShellExe "-File $scriptPath"
& ".\nssm.exe" set $serviceName Description $serviceDescription

# Start the service
Start-Service -Name $serviceName
####################################################################################################

