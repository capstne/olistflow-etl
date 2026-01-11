<powershell>
# Run as System on startup
$Admin = [adsi]("WinNT://./administrator,user")
$Admin.SetPassword("$${admin_password}")
$Admin.SetInfo()

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Install pgAdmin 4 (latest stable, 64-bit)
$pgAdminUrl = "https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v9.4/windows/pgadmin4-9.4-x64.exe"  # Update to latest version from https://www.pgadmin.org/download/pgadmin-4-windows/
$installerPath = "C:\temp\pgadmin4.exe"

# Create temp directory if needed
New-Item -ItemType Directory -Force -Path "C:\temp" | Out-Null

# Download installer
Invoke-WebRequest -Uri $pgAdminUrl -OutFile $installerPath

# Install silently for all users
Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT /NORESTART /ALLUSERS /LOG=C:\temp\pgadmin_install.log" -Wait -NoNewWindow

# Cleanup installer
Remove-Item $installerPath -Force

# After pgAdmin install in userdata...
$pgConfigPath = "$${env:ProgramFiles}\pgAdmin 4\v9\runtime\config_local.py"
$configContent = @"
import os
DATA_DIR = r'C:\\Users\\Public\\pgadmin4'
SERVER_MODE = True
CONNECTION_TIMEOUT = 60
DEFAULT_SERVER = ''
LOG_FILE = os.path.join(DATA_DIR, 'pgadmin4.log')
SQLITE_PATH = os.path.join(DATA_DIR, 'pgadmin4.db')
ALLOW_SAVE_PASSWORD = True
SHOW_SYSTEM_OBJECTS = True
MAX_ROWS = 1000
PGAUDIT_LOG_CONNECTIONS = True
"@

# Ensure data dir
New-Item -ItemType Directory -Force -Path "C:\Users\Public\pgadmin4" | Out-Null

# Write config (enables browser access)
$configContent | Out-File -FilePath $pgConfigPath -Encoding UTF8

# Create batch to auto-start pgAdmin server
$batchContent = @"
@echo off
cd /d "$${env:ProgramFiles}\pgAdmin 4\v9\bin"
pgAdmin4.exe
"@
$batchContent | Out-File -FilePath "$${env:PUBLIC}\Desktop\Start pgAdmin Server.bat" -Encoding ASCII
</powershell>
