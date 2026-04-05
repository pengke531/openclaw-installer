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
$OfficialInstallUrl = if ($env:OPENCLAW_OFFICIAL_INSTALL_PS1) { $env:OPENCLAW_OFFICIAL_INSTALL_PS1 } else { "https://openclaw.ai/install.ps1" }

function Show-Usage {
    @"
OpenClaw Windows 安装包装脚本

用途:
  这个脚本转调 OpenClaw 官方 PowerShell 安装器，
  适合双击本地运行、远程协助时让对方执行，或作为 GitHub Raw 安装入口。

用法:
  powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 [参数]

参数:
  -InstallMethod <npm|git>  安装方式，默认 npm
  -Tag <tag|version>        版本，默认 latest
  -GitDir <path>            git 模式源码目录
  -NoOnboard                安装后不进入 onboarding
  -DryRun                   只打印计划动作
  -Help                     显示帮助

示例:
  .\install-windows.ps1
  .\install-windows.ps1 -NoOnboard
  .\install-windows.ps1 -InstallMethod git -GitDir C:\openclaw
  .\install-windows.ps1 -DryRun -NoOnboard
"@
}

if ($Help) {
    Show-Usage
    exit 0
}

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
