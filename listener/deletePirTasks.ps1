$tasks = Get-ScheduledTask -TaskPath "\PIR\"
foreach ($task in $tasks) {
    $info = $task | Get-ScheduledTaskInfo
    if (!$info.NextRunTime) {
        Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
    }
}