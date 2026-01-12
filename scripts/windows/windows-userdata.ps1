# Run as System on startup
$Admin = [adsi]("WinNT://./administrator,user")
$Admin.SetPassword("${admin_password}")
$Admin.SetInfo()

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"