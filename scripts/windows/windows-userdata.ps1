# Run as System on startup
<powershell>
# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# install chocolately
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# install pgadmin4 with chocolately
choco install pgadmin4 -y

# import aws powershell module for reading server files from s3 bucket
Import-Module AWSPowerShell

# read servers.json, init.sql files and store them in pgadmin folder
Read-S3Object -BucketName "olistflow-etl-dev-artifacts" -Key "pgadmin/servers.json" -File "C:\pgadmin\servers.json"
Read-S3Object -BucketName "olistflow-etl-dev-artifacts" -Key "scripts/sql/init.sql" -File "C:\pgadmin\scripts\sql\init.sql"
</powershell>
<persist>true</persist>
