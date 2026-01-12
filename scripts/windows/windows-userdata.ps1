<powershell>
Start-Transcript "C:\userdata.log" -Append
Write-Output "=== Userdata Start: $(Get-Date) ==="

# Set admin password
$Admin = [adsi]("WinNT://./administrator,user")
$Admin.SetPassword("${admin_password}")
$Admin.SetInfo()
Write-Output "Admin password set"

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Write-Output "RDP enabled"

# # Wait for network
# do { Start-Sleep 10 } while (-not (Test-NetConnection 8.8.8.8 -InformationLevel Quiet))
# Write-Output "Network ready"

# # Smaller, reliable HTTPS download (direct pgAdmin mirror)
# $pgAdminUrl = "https://github.com/pgadmin-org/pgadmin4/releases/download/v9.4/pgadmin4-9.4-x64.exe"
# New-Item "C:\temp" -Force | Out-Null
# Invoke-WebRequest -Uri $pgAdminUrl -OutFile "C:\temp\pgadmin4.exe" -UseBasicParsing -TimeoutSec 600
# Write-Output "Downloaded pgAdmin"

# # Install
# Start-Process "C:\temp\pgadmin4.exe" -ArgumentList "/VERYSILENT /NORESTART /ALLUSERS /LOG=C:\temp\install.log" -Wait -NoNewWindow
# Write-Output "pgAdmin installed"

# # Config (hardcoded - works)
# $configContent = @"
# import os
# DATA_DIR = r'C:\Users\Public\pgadmin4'
# SERVER_MODE = True
# ALLOW_SAVE_PASSWORD = True
# "@
# New-Item "C:\Users\Public\pgadmin4" -Force | Out-Null
# $configContent | Out-File "C:\Program Files\pgAdmin 4\v9\runtime\config_local.py" -Encoding UTF8
# Write-Output "Config written"

# # Desktop shortcut
# $batchContent = @"
# @echo off
# start "" "C:\Program Files\pgAdmin 4\v9\bin\pgAdmin4.exe"
# "@
# $batchContent | Out-File "C:\Users\Public\Desktop\Start pgAdmin.bat" -Encoding ASCII

# Write-Output "=== Userdata Complete: $(Get-Date) ==="
# Stop-Transcript
</powershell>
