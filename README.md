# Fix Display Brightness for ASUS laptops(Nvidia GPU)

A small utility to fix the brightness control issue
when switching to dGPU mode using G-Helper on
ASUS laptops.

## What is this?

On some ASUS laptops,
the screen brightness cannot be adjusted after
switching to dGPU mode using G-Helper.

This tool fixes the issue by restarting
the NVIDIA `NvContainerLocalSystem` service.

## How to Use

1. Download `FixBrightness.exe` and `Restart.bat` from the Releases page
2. Run the application (administrator permission required)
3. Click "Fix Brightness" or use the tray icon

The screen brightness control should work immediately.

## Tray Icon

- The app runs in the system tray
- Right-click the tray icon to:
  - Fix Brightness
  - Exit
    
## Antivirus False Positives

This application may be flagged by some antivirus
software.

Reason:
- Built using PowerShell (ps2exe)
- Requires administrator privileges
- Restarts an NVIDIA system service

The source code is fully open and does NOT:
- Access the network
- Collect any data
- Run automatically in the background

## Source Code

The PowerShell source code is included in this repository.
You can inspect or modify it freely.

## ⚠ Disclaimer

Use this tool at your own risk.
This is an unofficial utility and is not affiliated
with ASUS, NVIDIA, or G-Helper.

