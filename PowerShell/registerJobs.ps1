$trig = New-JobTrigger -Daily -At "8:00 AM" -DaysInterval 1
$path = "C:\OHS-Project-1\ACF-pir-data\listener\deletePirTasks.ps1"
Register-ScheduledJob -Name "Delete_PIR_Tasks" -FilePath $path -Trigger $trig