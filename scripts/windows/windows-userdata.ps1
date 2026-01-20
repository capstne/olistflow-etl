# Run as System on startup
$Admin = [adsi]("WinNT://./administrator,user")
$Admin.SetPassword("${admin_password}")
$Admin.SetInfo()

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# install chocolately
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# install pgadmin4 with chocolately
choco install pgadmin4 -y

