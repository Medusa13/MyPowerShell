# EventLog-SaveandClear

This repository contains `EventLog-SaveandClear.ps1`, a PowerShell script that exports
Windows event logs to a folder, optionally clears them, and can email the logs to
support.

## Prerequisites
- PowerShell 4.0 or later
- [`PSLogging`](https://www.powershellgallery.com/packages/PSLogging/) module (optional for enhanced logging)

## Usage
```powershell
# Save logs and clear them
./EventLog-SaveandClear.ps1

# Save without clearing
./EventLog-SaveandClear.ps1 -NoClear

# Save, clear, and email logs using a specific SMTP server
./EventLog-SaveandClear.ps1 -SendMail -SmtpServer 'smtp.example.com'
```

Logs are stored in `C:\DV-Evts\EvtLogs`. When `-SendMail` is used, the script
zips the exported logs and sends them to `Support@DENVIC.ca`.

## License
See [LICENSE](LICENSE) for license information.
