class ListenerObject {
    [string]$directoryPath
    [string]$unprocessed_dir
    [string]$processed_dir
    [System.IO.FileSystemWatcher]$Watcher
    [System.IO.StreamWriter]$StreamWriter

    ListenerObject([string]$directoryPath, [string]$unprocessed_dir, [string]$processed_dir) {
        $this.directoryPath = $directoryPath
        $this.unprocessed_dir = $unprocessed_dir
        $this.processed_dir = $processed_dir
        $this.InitializeListener()
        # $this.InitializeStreamWriter()
        $this.StartListening()
    }

    [void]CheckProcessed() {
        $files = Get-ChildItem -Path $this.unprocessed_dir
        foreach ($file in $files) {
            $file_name = $file.Basename
            $file_matches = Get-ChildItem $this.processed_dir | Where-Object {$_.FullName -Match "$file_name"}
            if ($file_matches) {
                $base_file = $file_matches | Sort-Object LastWriteTime | Select-Object -last 1
                $modified_file = Get-ChildItem $this.unprocessed_dir | Where-Object {$_.FullName -Match "$file_name"}
                python.exe "C:\OHS-Project-1\ACF-pir-data\Python\diff\getDiff.py" $base_file.FullName $modified_file.FullName
            }
        }
    }

    [void]InitializeListener() {
        $this.Watcher = New-Object System.IO.FileSystemWatcher
        $this.Watcher.Path = $this.unprocessed_dir
        $this.Watcher.Filter = "*.*"
        $this.Watcher.IncludeSubdirectories = $true
        $this.Watcher.EnableRaisingEvents = $true
    }

    [void]InitializeStreamWriter() {
        $this.StreamWriter = [System.IO.StreamWriter]::new("$($this.unprocessed_dir)\log.txt", $true)
    }

    [void]StartListening() {
        Write-Host "Watching for changes in directory: $($this.unprocessed_dir)"
        while ($true) {
            $changedFiles = $this.Watcher.WaitForChanged('All', 1)  # Wait for 1 millisecond

            if ($changedFiles.ChangeType -eq "Created") {
                $eventType = $changedFiles.ChangeType
                if ($eventType -eq "Created") {
                    # $this.CheckProcessed()
                    # $this.StreamWriter.WriteLine("Caught Creation")
                    # $this.StreamWriter.Flush()
                    try {
                        Rscript.exe "C:\OHS-Project-1\ACF-pir-data\listener\listener.R"
                        # $this.StreamWriter.WriteLine("Ran script")
                        # $this.StreamWriter.Flush()
                    }
                    catch {
                        # $this.StreamWriter.WriteLine("Script did not run")
                        # $this.StreamWriter.Flush()
                    }
                }
            }
        }
    }
}

$root_dir = "C:\OHS-Project-1\ACF-pir-data\tests\data\unprocessed"
$unprocessed_dir = "C:\OHS-Project-1\ACF-pir-data\tests\data\unprocessed"
$processed_dir = "C:\OHS-Project-1\ACF-pir-data\tests\data\processed"

$listener = [ListenerObject]::new(
    $root_dir, $unprocessed_dir, $processed_dir
)