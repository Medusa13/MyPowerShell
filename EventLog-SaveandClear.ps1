#requires -version 4
<#[
.SYNOPSIS
    Save Windows event logs and optionally clear them.
.DESCRIPTION
    Iterates through all local event logs, saves their contents to files, performs log
    rollover when files grow too large, and optionally clears the logs. Logs can
    also be emailed to Support@DENVIC.ca.
.PARAMETER NoClear
    Prevents clearing of log contents after saving.
.PARAMETER SendMail
    When specified, sends the saved logs via email.
.PARAMETER SmtpServer
    SMTP server used to send email.
.PARAMETER SmtpPort
    Port for the SMTP server.
.PARAMETER From
    From address for email.
.PARAMETER To
    Destination email address for logs.
.EXAMPLE
    .\EventLog-SaveandClear.ps1 -SendMail -SmtpServer smtp.example.com
.EXAMPLE
    .\EventLog-SaveandClear.ps1 -NoClear
#>

param(
    [switch]$NoClear,
    [switch]$SendMail,
    [string]$SmtpServer = 'localhost',
    [int]$SmtpPort = 25,
    [string]$From = "$env:USERNAME@$env:USERDNSDOMAIN",
    [string]$To = 'Support@DENVIC.ca'
)

$ErrorActionPreference = 'Stop'

# Import PSLogging module if available
if (Get-Module -ListAvailable -Name PSLogging) {
    Import-Module PSLogging
}

$ScriptVersion = '1.0'
$LogPath = 'C:\DV-Evts\EvtLogs'
$LogName = 'EventLog-SaveandClear.log'
$LogFile = Join-Path -Path $LogPath -ChildPath $LogName

function Ensure-LogDirectory {
    if (-not (Test-Path -Path $LogPath)) {
        New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
    }
}

function Start-ScriptLog {
    Ensure-LogDirectory
    if (Get-Command -Name Start-Log -ErrorAction SilentlyContinue) {
        Start-Log -LogPath $LogPath -LogName $LogName -ScriptVersion $ScriptVersion
    }
}

function Stop-ScriptLog {
    if (Get-Command -Name Stop-Log -ErrorAction SilentlyContinue) {
        Stop-Log -LogPath $LogFile
    }
}

function Write-ScriptLog {
    param([string]$Message)
    if (Get-Command -Name Write-LogInfo -ErrorAction SilentlyContinue) {
        Write-LogInfo -LogPath $LogFile -Message $Message
    } else {
        Write-Output $Message
    }
}

function Save-EventLogs {
    Write-ScriptLog "Enumerating logs"
    $logs = Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -gt 0 }
    foreach ($log in $logs) {
        $fileName = "$($log.LogName).evtx"
        $target = Join-Path -Path $LogPath -ChildPath $fileName

        # Rollover existing file if larger than 10MB
        if (Test-Path $target) {
            $sizeMB = (Get-Item $target).Length / 1MB
            if ($sizeMB -ge 10) {
                $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
                $archive = Join-Path -Path $LogPath -ChildPath "$($log.LogName)-$timestamp.evtx"
                Move-Item -Path $target -Destination $archive
                Write-ScriptLog "Rolled $fileName to $archive"
            }
        }

        Write-ScriptLog "Exporting $($log.LogName)"
        wevtutil epl $log.LogName $target

        if (-not $NoClear) {
            try {
                wevtutil cl $log.LogName
                Write-ScriptLog "Cleared $($log.LogName)"
            } catch {
                Write-ScriptLog "Failed to clear $($log.LogName): $_"
            }
        }
    }
}

function Send-LogsMail {
    $files = Get-ChildItem -Path $LogPath -Filter '*.evtx'
    if (-not $files) { return }
    $zip = Join-Path -Path $LogPath -ChildPath 'Logs.zip'
    if (Test-Path $zip) { Remove-Item $zip }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($LogPath, $zip)

    $params = @{To=$To; From=$From; Subject='Event Logs'; Body='Event logs attached'; SmtpServer=$SmtpServer; Port=$SmtpPort; Attachments=$zip}
    try {
        Send-MailMessage @params
        Write-ScriptLog "Email sent to $To"
    } catch {
        Write-ScriptLog "Failed to send email: $_"
    }
}

try {
    Start-ScriptLog
    Save-EventLogs
    if ($SendMail) {
        Send-LogsMail
    }
} finally {
    Stop-ScriptLog
}
