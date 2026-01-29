# Run as System on startup
<powershell>
$ErrorActionPreference = 'Stop'
$serversJson = 'C:\pgadmin\servers.json'

try {
    # Log everything
    $LogDir = 'C:\ProgramData\userdata'
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    Start-Transcript -Path '$LogDir\userdata.log' -Append

    # Ensure folders exist
    New-Item -ItemType Directory -Path 'C:\pgadmin\scripts\sql' -Force | Out-Null

    # Enable RDP
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
    Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'

    # Install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Install pgAdmin4
    choco install pgadmin4 -y

    # Install AWS Tools for PowerShell if missing, then import
    if (-not (Get-Module -ListAvailable -Name AWSPowerShell)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Install-Module -Name AWSPowerShell -Force -AllowClobber
    }
    Import-Module AWSPowerShell

    # Set default region explicitly (needed for AWS cmdlets to pick endpoints)
    Set-DefaultAWSRegion -Region 'us-east-1'

    # Download artifacts from S3
    Read-S3Object -BucketName 'olistflow-etl-dev-artifacts' -Key 'pgadmin/servers.json'  -File $serversJson
    Read-S3Object -BucketName 'olistflow-etl-dev-artifacts' -Key 'scripts/sql/init.sql' -File 'C:\pgadmin\scripts\sql\init.sql'

    # Setup DB
    $pgRoot    = Join-Path $env:ProgramFiles 'pgAdmin 4'
    $pgRuntime = Join-Path $pgRoot '\runtime'
    $pythonExe = Join-Path $pgRoot 'python\python.exe'
    $setupPy   = Join-Path $pgRoot 'web\setup.py'

    $env:PATH = "$pgRuntime;$pgRoot;$env:PATH"

    & $pythonExe $setupPy setup-db 

    # Import server
    & $pythonExe $setupPy load-servers $serversJson

    'Success: $(Get-Date -Format o)' | Out-File '$LogDir\status.txt' -Append
}
catch {
    'Failure: $(Get-Date -Format o)`r`n$($_ | Out-String)' | Out-File '$LogDir\status.txt' -Append
    throw
}
finally {
    Stop-Transcript
}
</powershell>
<persist>true</persist>
