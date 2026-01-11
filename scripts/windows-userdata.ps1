<powershell>
# Run as System on startup
$Admin = [adsi]("WinNT://./administrator,user")
$Admin.SetPassword("${admin_password}")
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

# Optional: Start pgAdmin or create shortcut (runs via Start Menu after install)
</powershell>
