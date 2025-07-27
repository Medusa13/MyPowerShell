#requires -version 4
<#
.SYNOPSIS
  Cycle through Logs and Save as .evt .evtx or .csv format then potentially Clear logs
.DESCRIPTION
  Save and optionally Clear Windows Event-Log files
.PARAMETER NoClear
  /NoClear switch is used to prevent clearing of log contents
.PARAMETER MaxLogSizeMB
  Maximum size in megabytes before the log file is rotated
.INPUTS
  None
.OUTPUTS Log File
  The script log file stored in C:\DV-Evts\EvtLogs\<script_name>.log
.NOTES
  Version:        1.0
  Author:         Victor Nichols
  Creation Date:  Nov. 28th, 2021
  Purpose/Change: Initial script development
.EXAMPLE 1
  To save all log Windows log files with content to a storage folder

  .\EventLog-SaveandClear.ps1
.EXAMPLE 2
  To save all log Windows log files with content to a storage folder, once completed, clear the existing log file optionally

  .\EventLog-SaveandClear.ps1 /NoClear
#>

Param (
  [switch]$NoClear,
  [int]$MaxLogSizeMB = 10
)

#Set Error Action to SilentlyContinue
$ErrorActionPreference = 'SilentlyContinue'

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Start-Log {
    param(
        [string]$LogPath,
        [string]$LogName,
        [string]$ScriptVersion,
        [int]$MaxSizeMB
    )
    if (-not (Test-Path $LogPath)) {
        New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
    }
    $logFile = Join-Path -Path $LogPath -ChildPath $LogName
    if (Test-Path $logFile -and $MaxSizeMB -gt 0) {
        $sizeMB = (Get-Item $logFile).Length / 1MB
        if ($sizeMB -ge $MaxSizeMB) {
            $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
            $archiveName = ([IO.Path]::GetFileNameWithoutExtension($LogName) + "_$timestamp" + [IO.Path]::GetExtension($LogName))
            Rename-Item -Path $logFile -NewName $archiveName -Force
        }
    }
    Add-Content -Path $logFile -Value "Log started $(Get-Date) - Version $ScriptVersion"
    return $logFile
}

function Stop-Log {
    param(
        [string]$LogPath
    )
    Add-Content -Path $LogPath -Value "Log finished $(Get-Date)"
}

function Write-LogInfo {
    param(
        [string]$LogPath,
        [string]$Message
    )
    Add-Content -Path $LogPath -Value "$(Get-Date -Format u) [INFO] $Message"
}

function Write-LogError {
    param(
        [string]$LogPath,
        [string]$Message
    )
    Add-Content -Path $LogPath -Value "$(Get-Date -Format u) [ERROR] $Message"
}

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$sScriptVersion = '1.0'
$sLogPath = 'C:\DV-Evts\EvtLogs'
$sLogName = '<script_name>.log'
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

#-----------------------------------------------------------[Execution]------------------------------------------------------------

$sLogFile = Start-Log -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion -MaxSizeMB $MaxLogSizeMB

#Script Execution goes here

Stop-Log -LogPath $sLogFile
