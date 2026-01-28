# Run as System on startup
<powershell>
$ErrorActionPreference = "Stop"

# Log everything
$LogDir = "C:\ProgramData\userdata"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
Start-Transcript -Path "$LogDir\userdata.log" -Append

try {
    # Ensure folders exist
    New-Item -ItemType Directory -Path "C:\pgadmin\scripts\sql" -Force | Out-Null

    # Enable RDP
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    # install chocolately
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # install pgadmin4 with chocolately
    choco install pgadmin4 -y

    # Install AWS Tools for PowerShell if missing, then import
    if (-not (Get-Module -ListAvailable -Name AWSPowerShell)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Install-Module -Name AWSPowerShell -Force -AllowClobber
    }

    # Set default region explicitly
    Set-DefaultAWSRegion -Region "us-east-1"

    # import aws powershell module for reading server files from s3 bucket
    Import-Module AWSPowerShell

    # read servers.json, init.sql files and store them in pgadmin folder
    Read-S3Object -BucketName "olistflow-etl-dev-artifacts" -Key "pgadmin/servers.json" -File "C:\pgadmin\servers.json"
    Read-S3Object -BucketName "olistflow-etl-dev-artifacts" -Key "scripts/sql/init.sql" -File "C:\pgadmin\scripts\sql\init.sql"

    "Success: $(Get-Date -Format o)" | Out-File "$LogDir\status.txt" -Append
catch {
    "Failure: $(Get-Date -Format o)`r`n$($_ | Out-String)" | Out-File "$LogDir\status.txt" -Append
    throw
}
finally {
    Stop-Transcript
}
</powershell>
<persist>true</persist>
