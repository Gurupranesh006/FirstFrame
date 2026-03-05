param(
    [string]$TaskName = "StartupPhotoCaptureTask",
    [string]$UnlockTaskName = "StartupPhotoCaptureTask_OnUnlock"
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

$principalUser = "$env:USERDOMAIN\$env:USERNAME"
$taskCommand = "`"$pythonPath`" `"$scriptPath`""

function Register-Task {
    param(
        [string]$Name,
        [string]$Schedule
    )

    $output = schtasks /Create /TN $Name /TR $taskCommand /SC $Schedule /RL LIMITED /F /RU $principalUser 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to register task '$Name' with schedule '$Schedule'."
        $output | ForEach-Object { Write-Error $_ }
        exit 1
    }
}

Register-Task -Name $TaskName -Schedule ONLOGON
Register-Task -Name $UnlockTaskName -Schedule ONUNLOCK

Write-Host "Scheduled task '$TaskName' created/updated successfully (runs at sign-in)."
Write-Host "Scheduled task '$UnlockTaskName' created/updated successfully (runs when session is unlocked)."
Write-Host "Both tasks run for user $env:USERNAME."
