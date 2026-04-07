[CmdletBinding()]
param(
    [ValidateSet("npm", "git")]
    [string]$InstallMethod,
    [string]$Tag = "latest",
    [string]$GitDir,
    [switch]$Uninstall,
    [switch]$PurgeData,
    [switch]$NoOnboard,
    [switch]$VerboseInstall,
    [switch]$DryRun,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$Script:ReleaseVersion = "1.1.0"
$OfficialInstallUrl = if ($env:OPENCLAW_OFFICIAL_INSTALL_PS1) { $env:OPENCLAW_OFFICIAL_INSTALL_PS1 } else { "https://openclaw.ai/install.ps1" }
$Script:NpmInstallLogLevel = if ($VerboseInstall) { "verbose" } else { "notice" }

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
        "  Windows 的 npm 安装模式会直接执行官方文档推荐命令，",
        "  并在需要时调用官方 PowerShell 安装器处理 git 源码安装模式。",
        "",
        "用法:",
        "  powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 [参数]",
        "",
        "参数:",
        "  -InstallMethod [npm|git]  安装方式，默认 npm",
        "  -Tag [tag|version]        版本，默认 latest",
        "  -GitDir [path]            git 模式源码目录",
        "  -Uninstall                一键卸载 OpenClaw CLI 与服务",
        "  -PurgeData                与 -Uninstall 搭配，额外删除状态/工作区/配置",
        "  -NoOnboard                安装后不进入 onboarding",
        "  -VerboseInstall           包装层输出额外排查提示",
        "  -DryRun                   只打印计划动作",
        "  -Help                     显示帮助",
        "",
        "示例:",
        "  .\install-windows.ps1",
        "  .\install-windows.ps1 -Uninstall -PurgeData",
        "  .\install-windows.ps1 -NoOnboard",
        "  .\install-windows.ps1 -InstallMethod git -GitDir C:\openclaw",
        "  .\install-windows.ps1 -VerboseInstall",
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
    if ($Uninstall) {
        $argsList.Add("-Uninstall")
    }
    if ($PurgeData) {
        $argsList.Add("-PurgeData")
    }
    if ($NoOnboard) {
        $argsList.Add("-NoOnboard")
    }
    if ($VerboseInstall) {
        $argsList.Add("-VerboseInstall")
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

function Test-NodeAvailable {
    try {
        $nodeVersion = node --version
        $major = [int](($nodeVersion -replace '^v', '').Split('.')[0])
        return [PSCustomObject]@{
            Available = ($major -ge 22)
            Version = $nodeVersion
            Major = $major
        }
    } catch {
        return [PSCustomObject]@{
            Available = $false
            Version = $null
            Major = 0
        }
    }
}

function Install-NodeWithWinget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        return $false
    }

    Write-Host "未检测到可用的 Node.js，正在通过 winget 安装 Node.js LTS..." -ForegroundColor Yellow
    & winget install OpenJS.NodeJS.LTS --source winget --accept-package-agreements --accept-source-agreements
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        Write-Host "winget 安装 Node.js 失败，退出码: $exitCode" -ForegroundColor Yellow
        return $false
    }

    Refresh-ProcessPath
    return (Test-NodeAvailable).Available
}

function Install-NodeWithDirectDownload {
    $nodeUrl = "https://nodejs.org/dist/latest-v22.x/node-v22-x64.msi"
    $nodeInstaller = Join-Path $env:TEMP "openclaw-node-installer.msi"

    Write-Host "正在下载 Node.js 安装程序..." -ForegroundColor Yellow
    Invoke-WebRequest -UseBasicParsing -Uri $nodeUrl -OutFile $nodeInstaller

    Write-Host "正在静默安装 Node.js..." -ForegroundColor Yellow
    & msiexec.exe /i $nodeInstaller /qn /norestart
    $exitCode = $LASTEXITCODE

    Refresh-ProcessPath
    Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue

    if ($exitCode -ne 0) {
        Write-Host "Node.js 静默安装失败，退出码: $exitCode" -ForegroundColor Yellow
        return $false
    }

    return (Test-NodeAvailable).Available
}

function Ensure-NodeReady {
    $node = Test-NodeAvailable
    if ($node.Available) {
        Write-Host "Node.js 已就绪：$($node.Version)" -ForegroundColor Green
        return
    }

    if ($DryRun) {
        Write-Host "DryRun：当前未检测到 Node.js 22+，真实安装时会先自动安装 Node.js LTS。" -ForegroundColor Yellow
        return
    }

    if (Install-NodeWithWinget) {
        $node = Test-NodeAvailable
        Write-Host "Node.js 安装成功：$($node.Version)" -ForegroundColor Green
        return
    }

    if (Install-NodeWithDirectDownload) {
        $node = Test-NodeAvailable
        Write-Host "Node.js 安装成功：$($node.Version)" -ForegroundColor Green
        return
    }

    throw "无法自动安装 Node.js 22+。请先手动安装：https://nodejs.org/en/download/"
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

function Write-DiagnosticHint {
    Write-Host ""
    Write-Host "[提示] 长时间没有新输出，当前很可能卡在 npm 全局安装阶段。" -ForegroundColor Yellow
    Write-Host "[提示] 这通常不是脚本本身卡死，而是目标设备在下载、解压、杀毒扫描或等待 npm registry/GitHub 响应。" -ForegroundColor Yellow
    Write-Host "[提示] 如果再等几分钟仍无变化，请在目标设备上手动执行以下排查命令：" -ForegroundColor Yellow
    Write-Host "  node -v" -ForegroundColor Cyan
    Write-Host "  npm -v" -ForegroundColor Cyan
    Write-Host "  npm ping" -ForegroundColor Cyan
    Write-Host "  npm view openclaw version" -ForegroundColor Cyan
    Write-Host "  npm install -g openclaw@latest --loglevel verbose" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-ProcessWithMonitor {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$InstallDetectionText = "Installing OpenClaw"
    )

    $stdoutFile = Join-Path $env:TEMP ("openclaw-official-stdout-" + [guid]::NewGuid().ToString("N") + ".log")
    $stderrFile = Join-Path $env:TEMP ("openclaw-official-stderr-" + [guid]::NewGuid().ToString("N") + ".log")
    $sawInstallLine = $false
    $hintShown = $false
    $lastOutputAt = Get-Date
    $stdoutLineCount = 0
    $stderrLineCount = 0

    try {
        $proc = Start-Process -FilePath $FilePath -ArgumentList $Arguments -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile -PassThru -WindowStyle Hidden

        while (-not $proc.HasExited) {
            Start-Sleep -Seconds 3

            if (Test-Path $stdoutFile) {
                $stdoutLines = Get-Content $stdoutFile -ErrorAction SilentlyContinue
                if ($stdoutLines.Count -gt $stdoutLineCount) {
                    $newStdout = $stdoutLines[$stdoutLineCount..($stdoutLines.Count - 1)]
                    foreach ($line in $newStdout) {
                        Write-Host $line
                        if ($line -like "*$InstallDetectionText*") {
                            $sawInstallLine = $true
                        }
                    }
                    $stdoutLineCount = $stdoutLines.Count
                    $lastOutputAt = Get-Date
                }
            }

            if (Test-Path $stderrFile) {
                $stderrLines = Get-Content $stderrFile -ErrorAction SilentlyContinue
                if ($stderrLines.Count -gt $stderrLineCount) {
                    $newStderr = $stderrLines[$stderrLineCount..($stderrLines.Count - 1)]
                    foreach ($line in $newStderr) {
                        Write-Host $line -ForegroundColor Red
                    }
                    $stderrLineCount = $stderrLines.Count
                    $lastOutputAt = Get-Date
                }
            }

            $silentSeconds = [int]((Get-Date) - $lastOutputAt).TotalSeconds
            if ($silentSeconds -ge 30) {
                Write-Host "[等待中] 官方安装器已 $silentSeconds 秒没有新输出..." -ForegroundColor DarkYellow
                $lastOutputAt = Get-Date
            }

            if ($sawInstallLine -and -not $hintShown -and $silentSeconds -ge 180) {
                Write-DiagnosticHint
                $hintShown = $true
            }
        }

        if (Test-Path $stdoutFile) {
            $stdoutLines = Get-Content $stdoutFile -ErrorAction SilentlyContinue
            if ($stdoutLines.Count -gt $stdoutLineCount) {
                $stdoutLines[$stdoutLineCount..($stdoutLines.Count - 1)] | ForEach-Object { Write-Host $_ }
            }
        }

        if (Test-Path $stderrFile) {
            $stderrLines = Get-Content $stderrFile -ErrorAction SilentlyContinue
            if ($stderrLines.Count -gt $stderrLineCount) {
                $stderrLines[$stderrLineCount..($stderrLines.Count - 1)] | ForEach-Object { Write-Host $_ -ForegroundColor Red }
            }
        }

        $proc.WaitForExit()
        $proc.Refresh()
        if ($null -eq $proc.ExitCode -or $proc.ExitCode -eq "") {
            return
        }
        if ($proc.ExitCode -ne 0) {
            throw "官方安装器退出码: $($proc.ExitCode)"
        }
    } finally {
        try {
            if (-not [string]::IsNullOrWhiteSpace($stdoutFile) -and (Test-Path -LiteralPath $stdoutFile)) {
                Remove-Item -LiteralPath $stdoutFile -Force -ErrorAction SilentlyContinue
            }
        } catch {}
        try {
            if (-not [string]::IsNullOrWhiteSpace($stderrFile) -and (Test-Path -LiteralPath $stderrFile)) {
                Remove-Item -LiteralPath $stderrFile -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }
}

function Get-NpmCommandPath {
    $npmCmd = Get-Command npm.cmd -ErrorAction SilentlyContinue
    if ($npmCmd -and $npmCmd.Source) {
        return $npmCmd.Source
    }

    $npmExe = Get-Command npm.exe -ErrorAction SilentlyContinue
    if ($npmExe -and $npmExe.Source) {
        return $npmExe.Source
    }

    $npmPlain = Get-Command npm -ErrorAction SilentlyContinue
    if ($npmPlain -and $npmPlain.Source) {
        return $npmPlain.Source
    }

    throw "npm 未找到。请确认 Node.js 已正确安装。"
}

function Test-NpmAvailable {
    try {
        $npmPath = Get-NpmCommandPath
        $npmVersion = & $npmPath --version
        return [PSCustomObject]@{
            Available = $true
            Path = $npmPath
            Version = $npmVersion
        }
    } catch {
        return [PSCustomObject]@{
            Available = $false
            Path = $null
            Version = $null
        }
    }
}

function Ensure-NpmReady {
    $npm = Test-NpmAvailable
    if ($npm.Available) {
        Write-Host "npm 已就绪：$($npm.Version)" -ForegroundColor Green
        return
    }

    throw "npm 不可用。请确认 Node.js 安装完整，或重新打开 PowerShell 后重试。"
}

function Test-DirectoryWritable {
    param([string]$PathToCheck)

    try {
        if (-not (Test-Path $PathToCheck)) {
            New-Item -ItemType Directory -Force -Path $PathToCheck | Out-Null
        }
        $probe = Join-Path $PathToCheck ("write-test-" + [guid]::NewGuid().ToString("N") + ".tmp")
        Set-Content -Path $probe -Value "ok" -Encoding ASCII
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch {
        return $false
    }
}

function Ensure-NpmPrefixReady {
    $preferredPrefix = if ($env:APPDATA) { Join-Path $env:APPDATA "npm" } else { Join-Path $env:USERPROFILE "AppData\\Roaming\\npm" }
    $npmPath = Get-NpmCommandPath
    $currentPrefix = (& $npmPath config get prefix).Trim()
    $needsUserPrefix = $false

    if ([string]::IsNullOrWhiteSpace($currentPrefix)) {
        $needsUserPrefix = $true
    } elseif ($currentPrefix -match 'Program Files' -or $currentPrefix -match 'WindowsApps') {
        $needsUserPrefix = $true
    } elseif (-not (Test-DirectoryWritable -PathToCheck $currentPrefix)) {
        $needsUserPrefix = $true
    }

    if ($needsUserPrefix) {
        if ($DryRun) {
            Write-Host "DryRun：npm 全局前缀将切换为用户目录：$preferredPrefix" -ForegroundColor Yellow
        } else {
            Write-Host "正在将 npm 全局前缀调整到用户目录：$preferredPrefix" -ForegroundColor Yellow
            if (-not (Test-Path $preferredPrefix)) {
                New-Item -ItemType Directory -Force -Path $preferredPrefix | Out-Null
            }
            & $npmPath config set prefix $preferredPrefix --location=user | Out-Null
            Refresh-ProcessPath
            $currentPrefix = (& $npmPath config get prefix).Trim()
        }
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if (-not [string]::IsNullOrWhiteSpace($currentPrefix)) {
        if (-not ($userPath -split ";" | Where-Object { $_ -ieq $currentPrefix })) {
            if ($DryRun) {
                Write-Host "DryRun：会把 npm 全局目录加入用户 PATH：$currentPrefix" -ForegroundColor Yellow
            } else {
                [Environment]::SetEnvironmentVariable("Path", "$userPath;$currentPrefix", "User")
                Refresh-ProcessPath
                Write-Host "已将 npm 全局目录加入用户 PATH：$currentPrefix" -ForegroundColor Yellow
            }
        }
    }

    if (-not $DryRun) {
        $finalPrefix = (& $npmPath config get prefix).Trim()
        Write-Host "npm 全局前缀：$finalPrefix" -ForegroundColor Green
    }
}

function Test-OpenClawAvailable {
    try {
        $null = Get-Command openclaw -ErrorAction Stop
        return $true
    } catch {
        try {
            $null = Get-Command openclaw.cmd -ErrorAction Stop
            return $true
        } catch {
            return $false
        }
    }
}

function Get-OpenClawCommandPath {
    $cmd = Get-Command openclaw.cmd -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }

    $plain = Get-Command openclaw -ErrorAction SilentlyContinue
    if ($plain -and $plain.Source) {
        return $plain.Source
    }

    return $null
}

function Ensure-OpenClawOnPath {
    Refresh-ProcessPath
    if (Test-OpenClawAvailable) {
        return $true
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $npmPrefix = (& (Get-NpmCommandPath) config get prefix).Trim()
    $candidates = @()

    if (-not [string]::IsNullOrWhiteSpace($npmPrefix)) {
        $candidates += $npmPrefix
        $candidates += (Join-Path $npmPrefix "bin")
    }
    if (-not [string]::IsNullOrWhiteSpace($env:APPDATA)) {
        $candidates += (Join-Path $env:APPDATA "npm")
    }

    $candidates = $candidates | Select-Object -Unique
    foreach ($candidate in $candidates) {
        if (-not (Test-Path (Join-Path $candidate "openclaw.cmd"))) {
            continue
        }
        if (-not ($userPath -split ";" | Where-Object { $_ -ieq $candidate })) {
            [Environment]::SetEnvironmentVariable("Path", "$userPath;$candidate", "User")
            Refresh-ProcessPath
            Write-Host "已将 OpenClaw 所在目录加入用户 PATH：$candidate" -ForegroundColor Yellow
        }
        return $true
    }

    return $false
}

function Install-OpenClawViaNpm {
    $packageSpec = "openclaw@$Tag"

    Ensure-NodeReady
    Ensure-NpmReady
    Ensure-NpmPrefixReady

    $npmPath = Get-NpmCommandPath

    Write-Host "正在执行官方推荐安装命令：npm install -g $packageSpec" -ForegroundColor Cyan
    if ($VerboseInstall) {
        Write-Host "已启用详细日志，npm 将使用 --loglevel verbose。" -ForegroundColor Cyan
    }

    if ($DryRun) {
        Write-Host "[DryRun] npm install -g $packageSpec --loglevel $($Script:NpmInstallLogLevel)" -ForegroundColor Yellow
        return
    }

    $commandText = "& '{0}' install -g '{1}' --loglevel {2} --fund=false --audit=false" -f $npmPath, $packageSpec, $Script:NpmInstallLogLevel
    Invoke-ProcessWithMonitor -FilePath "powershell.exe" -Arguments @("-NoProfile", "-Command", $commandText) -InstallDetectionText "npm"

    if (-not (Ensure-OpenClawOnPath)) {
        Write-Host "安装已完成，但当前终端还找不到 openclaw 命令。" -ForegroundColor Yellow
        Write-Host "请重新打开 PowerShell 后执行：openclaw --version" -ForegroundColor Yellow
        return
    }

    try {
        $version = (& openclaw --version).Trim()
        if ($version) {
            Write-Host "OpenClaw 安装成功：$version" -ForegroundColor Green
        } else {
            Write-Host "OpenClaw 安装成功。" -ForegroundColor Green
        }
    } catch {
        Write-Host "OpenClaw 已安装，但暂时无法读取版本号，请重新打开终端后执行 openclaw --version。" -ForegroundColor Yellow
    }

    if (-not $NoOnboard) {
        Write-Host "开始执行 onboarding..." -ForegroundColor Cyan
        & openclaw onboard --install-daemon
    } else {
        Write-Host "已按要求跳过 onboarding，稍后可手动执行：openclaw onboard --install-daemon" -ForegroundColor Yellow
    }
}

function Get-OpenClawStateDirectories {
    $dirs = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($env:OPENCLAW_STATE_DIR)) {
        $dirs.Add($env:OPENCLAW_STATE_DIR)
    }

    if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE) -and (Test-Path -LiteralPath $env:USERPROFILE)) {
        $dirs.Add((Join-Path $env:USERPROFILE ".openclaw"))
        Get-ChildItem -LiteralPath $env:USERPROFILE -Force -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like ".openclaw-*" } |
            ForEach-Object { $dirs.Add($_.FullName) }
    }

    return $dirs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
}

function Invoke-LoggedCommand {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$Description,
        [switch]$IgnoreFailure
    )

    $display = if ($Arguments -and $Arguments.Count -gt 0) {
        "$FilePath $($Arguments -join ' ')"
    } else {
        $FilePath
    }

    if ($DryRun) {
        Write-Host "[DryRun] $Description：$display" -ForegroundColor Yellow
        return $true
    }

    Write-Host "$Description：$display" -ForegroundColor Cyan
    & $FilePath @Arguments
    $exitCode = $LASTEXITCODE

    if ($IgnoreFailure) {
        if ($exitCode -ne 0) {
            Write-Host "已忽略失败，退出码：$exitCode" -ForegroundColor DarkYellow
        }
        return ($exitCode -eq 0)
    }

    if ($exitCode -ne 0) {
        throw "$Description 失败，退出码：$exitCode"
    }

    return $true
}

function Remove-OpenClawScheduledTasks {
    $taskRows = @()
    try {
        $raw = schtasks.exe /Query /FO CSV /NH 2>$null
        if ($raw) {
            $taskRows = $raw | ConvertFrom-Csv | Where-Object { $_.TaskName -like "\OpenClaw Gateway*" }
        }
    } catch {
        $taskRows = @()
    }

    if (-not $taskRows -or $taskRows.Count -eq 0) {
        Write-Host "未发现 OpenClaw 计划任务。" -ForegroundColor DarkGray
        return
    }

    foreach ($task in $taskRows) {
        $taskName = $task.TaskName.TrimStart("\")
        Invoke-LoggedCommand -FilePath "schtasks.exe" -Arguments @("/Delete", "/F", "/TN", $taskName) -Description "删除 OpenClaw 计划任务" -IgnoreFailure
    }
}

function Remove-OpenClawStartupEntries {
    $startupTargets = New-Object System.Collections.Generic.List[string]

    foreach ($startupDir in @([Environment]::GetFolderPath("Startup"), [Environment]::GetFolderPath("CommonStartup"))) {
        if ([string]::IsNullOrWhiteSpace($startupDir) -or -not (Test-Path -LiteralPath $startupDir)) {
            continue
        }

        Get-ChildItem -LiteralPath $startupDir -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "OpenClaw*" } |
            ForEach-Object { $startupTargets.Add($_.FullName) }
    }

    foreach ($stateDir in Get-OpenClawStateDirectories) {
        $gatewayCmd = Join-Path $stateDir "gateway.cmd"
        if (Test-Path -LiteralPath $gatewayCmd) {
            $startupTargets.Add($gatewayCmd)
        }
    }

    $uniqueTargets = $startupTargets | Select-Object -Unique
    if (-not $uniqueTargets -or $uniqueTargets.Count -eq 0) {
        Write-Host "未发现 OpenClaw 启动项或 gateway.cmd。" -ForegroundColor DarkGray
        return
    }

    foreach ($target in $uniqueTargets) {
        if ($DryRun) {
            Write-Host "[DryRun] 删除 OpenClaw 启动项：$target" -ForegroundColor Yellow
            continue
        }
        if (Test-Path -LiteralPath $target) {
            Remove-Item -LiteralPath $target -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "已删除：$target" -ForegroundColor Yellow
        }
    }
}

function Remove-OpenClawStateData {
    if (-not $PurgeData) {
        Write-Host "未指定 -PurgeData，保留 OpenClaw 状态、工作区和配置数据。" -ForegroundColor DarkGray
        return
    }

    $targets = New-Object System.Collections.Generic.List[string]
    foreach ($stateDir in Get-OpenClawStateDirectories) {
        $targets.Add($stateDir)
    }

    if (-not [string]::IsNullOrWhiteSpace($env:OPENCLAW_CONFIG_PATH)) {
        $targets.Add($env:OPENCLAW_CONFIG_PATH)
    }

    foreach ($target in ($targets | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($target)) {
            continue
        }
        if ($DryRun) {
            Write-Host "[DryRun] 删除 OpenClaw 数据目录/文件：$target" -ForegroundColor Yellow
            continue
        }
        if (Test-Path -LiteralPath $target) {
            Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "已删除 OpenClaw 数据：$target" -ForegroundColor Yellow
        }
    }
}

function Remove-OpenClawGitCheckout {
    if ([string]::IsNullOrWhiteSpace($GitDir)) {
        return
    }

    if (-not $PurgeData) {
        Write-Host "已保留 git 源码目录；如需一并删除，请与 -Uninstall 搭配 -PurgeData -GitDir <路径>。" -ForegroundColor DarkGray
        return
    }

    if ($DryRun) {
        Write-Host "[DryRun] 删除 OpenClaw git 源码目录：$GitDir" -ForegroundColor Yellow
        return
    }

    if (Test-Path -LiteralPath $GitDir) {
        Remove-Item -LiteralPath $GitDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "已删除 OpenClaw git 源码目录：$GitDir" -ForegroundColor Yellow
    }
}

function Remove-OpenClawCliShims {
    $targets = New-Object System.Collections.Generic.List[string]
    $prefixes = New-Object System.Collections.Generic.List[string]

    try {
        $npmStatus = Test-NpmAvailable
        if ($npmStatus.Available) {
            $prefix = (& $npmStatus.Path config get prefix).Trim()
            if (-not [string]::IsNullOrWhiteSpace($prefix)) {
                $prefixes.Add($prefix)
            }
        }
    } catch {}

    if (-not [string]::IsNullOrWhiteSpace($env:APPDATA)) {
        $prefixes.Add((Join-Path $env:APPDATA "npm"))
    }

    foreach ($prefix in ($prefixes | Select-Object -Unique)) {
        foreach ($name in @("openclaw", "openclaw.cmd", "openclaw.ps1")) {
            $targets.Add((Join-Path $prefix $name))
        }
        $binDir = Join-Path $prefix "bin"
        foreach ($name in @("openclaw", "openclaw.cmd")) {
            $targets.Add((Join-Path $binDir $name))
        }
    }

    foreach ($target in ($targets | Select-Object -Unique)) {
        if ($DryRun) {
            Write-Host "[DryRun] 清理 OpenClaw 命令残留：$target" -ForegroundColor Yellow
            continue
        }
        if (Test-Path -LiteralPath $target) {
            Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
            Write-Host "已清理命令残留：$target" -ForegroundColor Yellow
        }
    }
}

function Remove-OpenClawGlobalPackage {
    $npm = Test-NpmAvailable
    if (-not $npm.Available) {
        Write-Host "未检测到 npm，跳过 npm 全局卸载。" -ForegroundColor DarkGray
        return
    }

    if ($DryRun) {
        Write-Host "[DryRun] $($npm.Path) rm -g openclaw --loglevel error" -ForegroundColor Yellow
        return
    }

    Invoke-LoggedCommand -FilePath $npm.Path -Arguments @("rm", "-g", "openclaw", "--loglevel", "error") -Description "卸载 npm 全局包 openclaw" -IgnoreFailure
}

function Uninstall-OpenClaw {
    Write-Host "开始执行 OpenClaw 卸载流程..." -ForegroundColor Cyan

    $cliPath = Get-OpenClawCommandPath
    if ($cliPath) {
        $uninstallArgs = @("uninstall")
        if ($PurgeData) {
            $uninstallArgs += @("--all", "--yes", "--non-interactive")
        } else {
            $uninstallArgs += @("--service", "--yes", "--non-interactive")
        }

        Invoke-LoggedCommand -FilePath $cliPath -Arguments $uninstallArgs -Description "调用 OpenClaw 官方内置卸载器" -IgnoreFailure | Out-Null
        Invoke-LoggedCommand -FilePath $cliPath -Arguments @("gateway", "stop") -Description "停止 OpenClaw 网关" -IgnoreFailure | Out-Null
        Invoke-LoggedCommand -FilePath $cliPath -Arguments @("gateway", "uninstall") -Description "卸载 OpenClaw 网关服务" -IgnoreFailure | Out-Null
    } else {
        Write-Host "当前未检测到 openclaw 命令，直接执行手工清理兜底。" -ForegroundColor Yellow
    }

    Remove-OpenClawScheduledTasks
    Remove-OpenClawStartupEntries
    Remove-OpenClawStateData
    Remove-OpenClawGlobalPackage
    Remove-OpenClawCliShims
    Remove-OpenClawGitCheckout

    Write-Host ""
    Write-Host "OpenClaw 卸载流程已执行完成。" -ForegroundColor Green
    if ($PurgeData) {
        Write-Host "本次已包含状态、工作区和配置清理。" -ForegroundColor Green
    } else {
        Write-Host "本次未删除本地状态/工作区；如需彻底清仓，请使用：-Uninstall -PurgeData" -ForegroundColor Yellow
    }
    Write-Host "Node.js 与 Git 为通用依赖，本脚本不会自动卸载它们。" -ForegroundColor DarkGray
}

function Invoke-GitInstallViaOfficialInstaller {
    param(
        [string[]]$Arguments
    )

    Write-Host "git 模式仍交给 OpenClaw 官方安装器处理..." -ForegroundColor Cyan
    Invoke-ProcessWithMonitor -FilePath "powershell.exe" -Arguments $Arguments -InstallDetectionText "Installing OpenClaw"
}

if ($Help) {
    Show-Banner
    Show-Usage
    exit 0
}

Show-Banner
Ensure-ElevatedIfNeeded

if ($Uninstall) {
    Uninstall-OpenClaw
    exit 0
}

Ensure-GitReady

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

if ($InstallMethod -eq "git") {
    $tempFile = Join-Path $env:TEMP "openclaw-official-install.ps1"
    $processArgs = @(
        "-NoProfile"
        "-ExecutionPolicy"
        "Bypass"
        "-File"
        $tempFile
    ) + $invokeArgs
    Write-Host "正在下载 OpenClaw 官方 Windows 安装器..." -ForegroundColor Cyan
    Invoke-WebRequest -UseBasicParsing -Uri $OfficialInstallUrl -OutFile $tempFile
    Write-Host "已切换到官方安装路径：$($OfficialInstallUrl)" -ForegroundColor Green
    Write-Host ("即将执行：powershell -File {0} {1}" -f $tempFile, ($invokeArgs -join " ")) -ForegroundColor Yellow
    Write-Host ""
    if ($VerboseInstall) {
        Write-Host "已启用增强诊断模式：如果安装长时间无输出，会自动显示排查提示。" -ForegroundColor Cyan
    }
    Invoke-GitInstallViaOfficialInstaller -Arguments $processArgs
} else {
    if ($VerboseInstall) {
        Write-Host "已启用增强诊断模式：如果安装长时间无输出，会自动显示排查提示。" -ForegroundColor Cyan
    }
    Install-OpenClawViaNpm
}
