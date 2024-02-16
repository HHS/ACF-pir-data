#***************************************
# Created by : Sankar Kalaga
# Date       : 02/15/2024
# Description: It will install the packages and creates necessary directories 
#####################################################################################################
# Function to install an application using Chocolatey
<#
function Install-Application {
    param (
        [string]$packageName
    )
    try {
        # Check if the package is already installed
        if (!(Get-Package -Name $packageName -ErrorAction SilentlyContinue)) {
            Write-Host "Installing $packageName..."
            choco install $packageName -y
        }
        else {
            Write-Host "$packageName is already installed."
        }
    } catch {
        Write-Host "An error occurred while installing {$packageName}: $_"
    }
}

# Check if Chocolatey is installed, if not, install it
try {
    if (!(Get-PackageProvider -Name Chocolatey -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey is not installed. Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    } else {
        Write-Host "Chocolatey is already installed."
    }
} catch {
    Write-Host "An error occurred while installing Chocolatey: $_"
}

# Installing the Required Applications
Install-Application 'python'
Install-Application 'r.project'
Install-Application 'mysql'
Install-Application 'mysql.workbench'
Install-Application 'vscode'

Write-Host "Installation of packages completed"

#>

$mainFolderName = "PIR_Directory"
$subFolders = @(
    "PIR_data_repository",
    "Automated_Pipeline_Logs",
    "Installation_Logs",
    "Listener_Logs",
    "mySQL_Binary_Logs",
    "mySQL_General_Logs",
    "mySQL_Logs",
    "mySQL_Query_Logs"
)

function Create-Directories {
    param (
        [string]$mainDirectoryPath,
        [string[]]$subDirectories
    )

    $subDirectoryPaths = @() 

    if (!(Test-Path -Path $mainDirectoryPath)) {
        New-Item -ItemType Directory -Path $mainDirectoryPath
        Write-Host "Created main directory: $mainDirectoryPath"
    } else {
        Write-Host "Main directory already exists: $mainDirectoryPath"
    }

    foreach ($subDir in $subDirectories) {
        $fullSubDirPath = Join-Path -Path $mainDirectoryPath -ChildPath $subDir
        if (!(Test-Path -Path $fullSubDirPath)) {
            New-Item -ItemType Directory -Path $fullSubDirPath
            Write-Host "Created subdirectory: $fullSubDirPath"
        } else {
            Write-Host "Subdirectory already exists: $fullSubDirPath"
        }
        $subDirectoryPaths += $fullSubDirPath 
    }

    return $subDirectoryPaths 
}


$mainFolder = Join-Path -Path $PSScriptRoot -ChildPath $mainFolderName
$subDirectoryPaths = Create-Directories -mainDirectoryPath $mainFolder -subDirectories $subFolders

Write-Host "Directory creation is completed."


# Initialize a simplified hashtable for storing the main folder and subfolders' paths
$jsonObjectSimplified = @{}
$jsonObjectSimplified['MainFolder'] = $mainFolder 

# Append each subFolder's name and simplified path information to the hashtable
foreach ($subDir in $subFolders) {
    $fullSubDirPath = Join-Path -Path $mainFolder -ChildPath $subDir
    # Add only the path of the subdirectory
    $jsonObjectSimplified[$subDir] = $fullSubDirPath
}

# Specify the path for the config.json file
$jsonPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"

# Check if the config.json file already exists
if (-not (Test-Path -Path $jsonPath)) {
    Write-Host "config.json does not exist. Creating now..."
    # The file will be created by the Out-File cmdlet
} else {
    Write-Host "config.json already exists. Updating now..."
}

# Convert the simplified hashtable to a JSON string
$jsonContentSimplified = $jsonObjectSimplified | ConvertTo-Json

# Write the simplified JSON content to the config.json file
$jsonContentSimplified | Out-File -FilePath $jsonPath -Encoding UTF8

Write-Host "Config.json has been created/updated."
