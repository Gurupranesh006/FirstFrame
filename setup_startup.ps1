param(
    [string]$TaskName = "StartupPhotoCaptureTask"
)

$scriptPath = Join-Path $PSScriptRoot "startup_capture.py"
if (-not (Test-Path $scriptPath)) {
    Write-Error "Could not find startup_capture.py in $PSScriptRoot"
    exit 1
}

$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Error "Python is not installed or not in PATH. Install Python first."
    exit 1
}

$pythonPath = $pythonCmd.Source

$action = New-ScheduledTaskAction -Execute $pythonPath -Argument "`"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null

Write-Host "Scheduled task '$TaskName' created/updated successfully."
Write-Host "It will run at each sign-in for user $env:USERNAME."
