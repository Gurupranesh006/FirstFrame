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
        # Fallback to current user context when explicit /RU updates are denied.
        $output = schtasks /Create /TN $Name /TR $taskCommand /SC $Schedule /RL LIMITED /F 2>&1
        if ($LASTEXITCODE -ne 0) {
            return $false
        }
    }

    return $true
}

$logonRegistered = Register-Task -Name $TaskName -Schedule ONLOGON
if (-not $logonRegistered) {
    schtasks /Query /TN $TaskName 1>$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Warning "Could not update '$TaskName' due to permissions; keeping existing task definition."
    }
    else {
        Write-Error "Failed to register task '$TaskName' with schedule 'ONLOGON'."
        exit 1
    }
}

# Trigger on workstation unlock/reconnect via LocalSessionManager operational events.
$unlockQuery = "*[System[(EventID=25)]]"
$unlockOutput = schtasks /Create /TN $UnlockTaskName /TR $taskCommand /SC ONEVENT /EC "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" /MO $unlockQuery /RL LIMITED /F /RU $principalUser 2>&1
if ($LASTEXITCODE -ne 0) {
    # Fallback to current user context when explicit /RU updates are denied.
    $unlockOutput = schtasks /Create /TN $UnlockTaskName /TR $taskCommand /SC ONEVENT /EC "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" /MO $unlockQuery /RL LIMITED /F 2>&1
    if ($LASTEXITCODE -ne 0) {
        schtasks /Query /TN $UnlockTaskName 1>$null 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Warning "Could not update '$UnlockTaskName' due to permissions; keeping existing task definition."
        }
        else {
            Write-Error "Failed to register task '$UnlockTaskName' for unlock event trigger."
            $unlockOutput | ForEach-Object { Write-Error $_ }
            exit 1
        }
    }
}

Write-Host "Scheduled task '$TaskName' created/updated successfully (runs at sign-in)."
Write-Host "Scheduled task '$UnlockTaskName' created/updated successfully (runs on unlock event)."
Write-Host "Both tasks run for user $env:USERNAME."
