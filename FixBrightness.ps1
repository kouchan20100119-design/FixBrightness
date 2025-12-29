# Fix Display Brightness for ASUS laptops (Nvidia GPU)
# This script restarts the NVIDIA service to fix brightness control issues

# 定数定義
$SERVICE_NAME = "NvContainerLocalSystem"
$SERVICE_STOP_TIMEOUT = 10  # 秒
$SERVICE_START_TIMEOUT = 10  # 秒
$SERVICE_STOP_WAIT = 3       # 秒

# 管理者権限チェック関数
function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# メッセージボックス表示関数
function Show-MessageBox {
    param(
        [string]$Message,
        [string]$Title,
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Information
    )
    
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, $Icon) | Out-Null
}

# サービスが存在するかチェック
function Test-ServiceExists {
    param([string]$ServiceName)
    
    try {
        $null = Get-Service -Name $ServiceName -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# サービス再起動関数
function Restart-NvidiaService {
    # 管理者権限チェック
    if (-not (Test-Administrator)) {
        $scriptPath = $MyInvocation.PSCommandPath
        if ([string]::IsNullOrEmpty($scriptPath)) {
            $scriptPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        }
        
        try {
            Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -FixOnly" -Verb RunAs
        }
        catch {
            Show-MessageBox -Message "管理者権限の取得に失敗しました:`n$($_.Exception.Message)" -Title "エラー" -Icon Error
        }
        return
    }
    
    # サービス存在確認
    if (-not (Test-ServiceExists -ServiceName $SERVICE_NAME)) {
        Show-MessageBox -Message "サービス '$SERVICE_NAME' が見つかりません。`nNVIDIAドライバーがインストールされているか確認してください。" -Title "エラー" -Icon Error
        return
    }
    
    try {
        $service = Get-Service -Name $SERVICE_NAME
        
        # サービス停止
        if ($service.Status -eq 'Running') {
            Stop-Service -Name $SERVICE_NAME -Force -ErrorAction Stop
            $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped, [TimeSpan]::FromSeconds($SERVICE_STOP_TIMEOUT))
        }
        
        # 停止待機
        Start-Sleep -Seconds $SERVICE_STOP_WAIT
        
        # サービス開始
        Start-Service -Name $SERVICE_NAME -ErrorAction Stop
        $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Running, [TimeSpan]::FromSeconds($SERVICE_START_TIMEOUT))
        
        # 最終状態確認
        $service.Refresh()
        if ($service.Status -eq 'Running') {
            Show-MessageBox -Message "NVIDIAサービスを正常に再起動しました。" -Title "完了" -Icon Information
        }
        else {
            Show-MessageBox -Message "サービスを再起動しましたが、起動状態を確認できませんでした。`n現在の状態: $($service.Status)" -Title "警告" -Icon Warning
        }
    }
    catch {
        $errorMessage = "サービス再起動に失敗しました:`n$($_.Exception.Message)"
        if ($_.Exception.InnerException) {
            $errorMessage += "`n詳細: $($_.Exception.InnerException.Message)"
        }
        Show-MessageBox -Message $errorMessage -Title "エラー" -Icon Error
    }
}

# -FixOnly パラメータが指定された場合、サービス再起動のみ実行
if ($args -contains "-FixOnly") {
    Restart-NvidiaService
    exit
}

# 不正な引数チェック
if ($args.Count -gt 0 -and -not ($args -contains "-FixOnly")) {
    Write-Host "使用法: $($MyInvocation.MyCommand.Name) [-FixOnly]" -ForegroundColor Yellow
    exit 1
}

# GUI初期化
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# アイコンの読み込み
$iconObj = $null
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$iconPath = Join-Path $scriptDir "icon.ico"

if (Test-Path $iconPath) {
    try {
        $iconObj = [System.Drawing.Icon]::new($iconPath)
    }
    catch {
        Write-Warning "アイコンファイルの読み込みに失敗しました: $($_.Exception.Message)"
    }
}

# アイコンファイルが見つからない場合、実行ファイルから抽出を試行
if ($null -eq $iconObj) {
    try {
        $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $iconObj = [System.Drawing.Icon]::ExtractAssociatedIcon($exePath)
    }
    catch {
        Write-Warning "アイコンの抽出に失敗しました: $($_.Exception.Message)"
    }
}

# デフォルトアイコンを使用（上記すべて失敗した場合）
if ($null -eq $iconObj) {
    $iconObj = [System.Drawing.SystemIcons]::Application
}

# 通知アイコンの作成
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = $iconObj
$notify.Text = "Fix Brightness"
$notify.Visible = $true

# コンテキストメニューの作成
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$fixItem = $menu.Items.Add("Fix Brightness")
$exitItem = $menu.Items.Add("Exit")

# イベントハンドラの設定
$fixItem.Add_Click({
    Restart-NvidiaService
})

$exitItem.Add_Click({
    # リソースのクリーンアップ
    if ($notify) {
        $notify.Visible = $false
        $notify.Dispose()
    }
    if ($iconObj -and $iconObj -ne [System.Drawing.SystemIcons]::Application) {
        $iconObj.Dispose()
    }
    if ($menu) {
        $menu.Dispose()
    }
    [System.Windows.Forms.Application]::Exit()
})

$notify.ContextMenuStrip = $menu

# アプリケーション終了時のクリーンアップ処理
[System.Windows.Forms.Application]::Add_ApplicationExit({
    if ($notify) {
        $notify.Visible = $false
        $notify.Dispose()
    }
    if ($iconObj -and $iconObj -ne [System.Drawing.SystemIcons]::Application) {
        $iconObj.Dispose()
    }
    if ($menu) {
        $menu.Dispose()
    }
})

# メインループ
try {
    [System.Windows.Forms.Application]::Run()
}
finally {
    # 確実にリソースを解放
    if ($notify) {
        $notify.Visible = $false
        $notify.Dispose()
    }
    if ($iconObj -and $iconObj -ne [System.Drawing.SystemIcons]::Application) {
        $iconObj.Dispose()
    }
    if ($menu) {
        $menu.Dispose()
    }
}
