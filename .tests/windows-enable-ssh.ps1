# Run once in an elevated PowerShell inside the VM:
#   powershell -ExecutionPolicy Bypass -File \\host.lan\Data\enable-ssh.ps1
$ErrorActionPreference = 'Stop'

Write-Host 'Installing OpenSSH Server (can take a few minutes)...'
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
Set-Service sshd -StartupType Automatic
Start-Service sshd

if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
  New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
}

# PowerShell as the SSH shell, so the host can send scripts directly
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -PropertyType String -Force | Out-Null

# The VM user is an administrator, so sshd reads this file, not ~/.ssh/authorized_keys
$keys = 'C:\ProgramData\ssh\administrators_authorized_keys'
Set-Content -Path $keys -Value '@PUBKEY@' -Encoding ascii
icacls.exe $keys /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null

Restart-Service sshd
Write-Host 'SSH is ready.' -ForegroundColor Green
