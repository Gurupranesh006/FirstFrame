# FirstFrame

`FirstFrame` is a lightweight Windows automation project that captures one webcam photo each time you sign in and each time you unlock your session.

It uses Task Scheduler to run `startup_capture.py` at logon and on session unlock, then:
- Logs startup timestamp in `startup_log.txt`
- Captures one webcam frame
- Saves the photo to `startup_photos/` as `YYYY-MM-DD_HH-MM-SS.jpg`

![FirstFrame Workflow](docs/images/workflow.svg)

## Project Structure

![Project Structure](docs/images/project-structure.svg)

## Requirements

- Windows 10 or newer
- Python 3.10+ (with `python` available in PATH)
- Webcam connected and accessible

## Setup

1. Clone the repository and open PowerShell in the project root.
2. Install dependencies:

```powershell
python -m pip install -r requirements.txt
```

3. Register the startup task:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup_startup.ps1
```

This creates or updates two scheduled tasks for the current user:
- `StartupPhotoCaptureTask` (runs at sign-in)
- `StartupPhotoCaptureTask_OnUnlock` (runs on local session unlock/reconnect event)

## Run Manually (Quick Test)

Run once to verify your camera and paths:

```powershell
python .\startup_capture.py
```

Expected outputs:
- A new line in `startup_log.txt`
- A new `.jpg` file in `startup_photos/`

## Verify Startup Automation

1. Sign out and sign back in, then check for a new log/photo entry.
2. Lock your session (`Win + L`), unlock it, then check for another new log/photo entry.

Note: The unlock task listens to `Microsoft-Windows-TerminalServices-LocalSessionManager/Operational` event `25`.

## Uninstall / Disable

Remove the scheduled tasks:

```powershell
Unregister-ScheduledTask -TaskName "StartupPhotoCaptureTask" -Confirm:$false
Unregister-ScheduledTask -TaskName "StartupPhotoCaptureTask_OnUnlock" -Confirm:$false
```

## Troubleshooting

- `PHOTO_ERROR: opencv-python is not installed`
	- Reinstall dependencies: `python -m pip install -r requirements.txt`
- `PHOTO_ERROR: Camera not available`
	- Close other apps using the camera and re-run script
	- Check Windows camera privacy settings
- `Python is not installed or not in PATH`
	- Install Python and ensure `python` command works in PowerShell

## Security and Privacy

- This project captures images from your local webcam at user sign-in and session unlock.
- Use it only on systems where all users are informed and where this behavior complies with policy/law.

## License

This project is licensed under the MIT License. See `LICENSE`.
