[CmdletBinding()]
param(
    [ValidateSet("npm", "git")]
    [string]$InstallMethod,
    [string]$Tag = "latest",
    [string]$GitDir,
    [switch]$NoOnboard,
    [switch]$DryRun,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$Script:ReleaseVersion = "1.0.0"
$OfficialInstallUrl = if ($env:OPENCLAW_OFFICIAL_INSTALL_PS1) { $env:OPENCLAW_OFFICIAL_INSTALL_PS1 } else { "https://openclaw.ai/install.ps1" }

function Show-Banner {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  OpenClaw 一键安装工具 for Windows v$($Script:ReleaseVersion)" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  开发者：创造晴天" -ForegroundColor Yellow
    Write-Host "  微信：kerp531" -ForegroundColor Yellow
    Write-Host ""
}

function Show-Usage {
    $lines = @(
        "OpenClaw Windows 安装包装脚本 v$($Script:ReleaseVersion)",
        "",
        "开发者：创造晴天",
        "微信：kerp531",
        "",
        "用途:",
        "  这个脚本转调 OpenClaw 官方 PowerShell 安装器，",
        "  适合双击本地运行、远程协助时让对方执行，或作为 GitHub Raw 安装入口。",
        "",
        "用法:",
        "  powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 [参数]",
        "",
        "参数:",
        "  -InstallMethod [npm|git]  安装方式，默认 npm",
        "  -Tag [tag|version]        版本，默认 latest",
        "  -GitDir [path]            git 模式源码目录",
        "  -NoOnboard                安装后不进入 onboarding",
        "  -DryRun                   只打印计划动作",
        "  -Help                     显示帮助",
        "",
        "示例:",
        "  .\install-windows.ps1",
        "  .\install-windows.ps1 -NoOnboard",
        "  .\install-windows.ps1 -InstallMethod git -GitDir C:\openclaw",
        "  .\install-windows.ps1 -DryRun -NoOnboard"
    )
    $lines -join [Environment]::NewLine
}

function Test-IsAdministrator {
    try {
        $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Get-RelaunchArguments {
    $argsList = New-Object System.Collections.Generic.List[string]
    $argsList.Add("-ExecutionPolicy")
    $argsList.Add("Bypass")
    $argsList.Add("-File")
    $argsList.Add($PSCommandPath)

    if ($PSBoundParameters.ContainsKey("InstallMethod")) {
        $argsList.Add("-InstallMethod")
        $argsList.Add($InstallMethod)
    }
    if ($PSBoundParameters.ContainsKey("Tag")) {
        $argsList.Add("-Tag")
        $argsList.Add($Tag)
    }
    if ($PSBoundParameters.ContainsKey("GitDir")) {
        $argsList.Add("-GitDir")
        $argsList.Add($GitDir)
    }
    if ($NoOnboard) {
        $argsList.Add("-NoOnboard")
    }
    if ($DryRun) {
        $argsList.Add("-DryRun")
    }
    if ($Help) {
        $argsList.Add("-Help")
    }

    return $argsList.ToArray()
}

function Ensure-ElevatedIfNeeded {
    if ($Help -or $DryRun) {
        return
    }

    if (Test-IsAdministrator) {
        return
    }

    Write-Host "当前不是管理员权限，正在请求提升..." -ForegroundColor Yellow
    $relaunchArgs = Get-RelaunchArguments
    $proc = Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $relaunchArgs -Wait -PassThru
    exit $proc.ExitCode
}

function Refresh-ProcessPath {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

function Test-GitAvailable {
    try {
        $null = Get-Command git -ErrorAction Stop
        $version = git --version
        return [PSCustomObject]@{
            Available = $true
            Version = $version
        }
    } catch {
        return [PSCustomObject]@{
            Available = $false
            Version = $null
        }
    }
}

function Install-GitWithWinget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        return $false
    }

    Write-Host "未检测到 Git，正在通过 winget 安装 Git for Windows..." -ForegroundColor Yellow
    & winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        Write-Host "winget 安装 Git 失败，退出码: $exitCode" -ForegroundColor Yellow
        return $false
    }

    Refresh-ProcessPath
    return (Test-GitAvailable).Available
}

function Install-GitWithDirectDownload {
    $gitUrl = "https://github.com/git-for-windows/git/releases/latest/download/Git-64-bit.exe"
    $gitInstaller = Join-Path $env:TEMP "openclaw-git-installer.exe"

    Write-Host "正在下载 Git for Windows 安装程序..." -ForegroundColor Yellow
    Invoke-WebRequest -UseBasicParsing -Uri $gitUrl -OutFile $gitInstaller

    Write-Host "正在静默安装 Git for Windows..." -ForegroundColor Yellow
    & $gitInstaller /VERYSILENT /NORESTART /NOCANCEL /SP-
    $exitCode = $LASTEXITCODE

    Refresh-ProcessPath
    Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue

    if ($exitCode -ne 0) {
        Write-Host "Git 静默安装失败，退出码: $exitCode" -ForegroundColor Yellow
        return $false
    }

    return (Test-GitAvailable).Available
}

function Ensure-GitReady {
    $git = Test-GitAvailable
    if ($git.Available) {
        Write-Host "Git 已就绪：$($git.Version)" -ForegroundColor Green
        return
    }

    if ($DryRun) {
        Write-Host "DryRun：当前未检测到 Git，真实安装时会先尝试自动安装 Git。" -ForegroundColor Yellow
        return
    }

    if (Install-GitWithWinget) {
        $git = Test-GitAvailable
        Write-Host "Git 安装成功：$($git.Version)" -ForegroundColor Green
        return
    }

    if (Install-GitWithDirectDownload) {
        $git = Test-GitAvailable
        Write-Host "Git 安装成功：$($git.Version)" -ForegroundColor Green
        return
    }

    throw "无法自动安装 Git。请先手动安装 Git for Windows 后重试：https://git-scm.com/download/win"
}

if ($Help) {
    Show-Banner
    Show-Usage
    exit 0
}

Show-Banner
Ensure-ElevatedIfNeeded
Ensure-GitReady

$tempFile = Join-Path $env:TEMP "openclaw-official-install.ps1"

Write-Host "正在下载 OpenClaw 官方 Windows 安装器..." -ForegroundColor Cyan
Invoke-WebRequest -UseBasicParsing -Uri $OfficialInstallUrl -OutFile $tempFile

$invokeArgs = @()
if ($PSBoundParameters.ContainsKey("InstallMethod")) {
    $invokeArgs += "-InstallMethod"
    $invokeArgs += $InstallMethod
}
if ($PSBoundParameters.ContainsKey("Tag") -and $Tag -ne "latest") {
    $invokeArgs += "-Tag"
    $invokeArgs += $Tag
}
if ($PSBoundParameters.ContainsKey("GitDir")) {
    $invokeArgs += "-GitDir"
    $invokeArgs += $GitDir
}
if ($NoOnboard) {
    $invokeArgs += "-NoOnboard"
}
if ($DryRun) {
    $invokeArgs += "-DryRun"
}

Write-Host "已切换到官方安装路径：$($OfficialInstallUrl)" -ForegroundColor Green
Write-Host ("即将执行：powershell -File {0} {1}" -f $tempFile, ($invokeArgs -join " ")) -ForegroundColor Yellow
Write-Host ""

$processArgs = @(
    "-NoProfile"
    "-ExecutionPolicy"
    "Bypass"
    "-File"
    $tempFile
) + $invokeArgs

& powershell.exe $processArgs
