$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function Restart-NvidiaService {
    if (-not $isAdmin) {
        $scriptPath = $MyInvocation.PSCommandPath
        if ([string]::IsNullOrEmpty($scriptPath)) {
            $scriptPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        }
        
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -FixOnly" -Verb RunAs
        return
    }
    
    try {
        Stop-Service "NvContainerLocalSystem" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        Start-Service "NvContainerLocalSystem" -ErrorAction SilentlyContinue
        
        [System.Windows.Forms.MessageBox]::Show(
            "Restarted the NVIDIA service",
            "Completion",
            "OK",
            "Information"
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Service restart failed:`n$($_.Exception.Message)",
            "Error",
            "OK",
            "Error"
        )
    }
}

if ($args -contains "-FixOnly") {
    Restart-NvidiaService
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$iconObj = [System.Drawing.Icon]::ExtractAssociatedIcon($exePath)

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = $iconObj
$notify.Text = "Fix Brightness"
$notify.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$fixItem = $menu.Items.Add("Fix Brightness")
$exitItem = $menu.Items.Add("Exit")

$fixItem.Add_Click({
    Restart-NvidiaService
})

$exitItem.Add_Click({
    $notify.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})

$notify.ContextMenuStrip = $menu

[System.Windows.Forms.Application]::Run()
