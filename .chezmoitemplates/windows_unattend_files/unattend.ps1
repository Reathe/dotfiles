$timeoutSeconds = 6 * 60;
$startTime = Get-Date;

Write-Host "Waiting for 'bw' command to become available (timeout: $timeoutSeconds seconds)..." -ForegroundColor Cyan;
$wingetLinks = "$env:LOCALAPPDATA\Microsoft\WinGet\Links";
$chmoi = "$wingetLinks\chezmoi.exe";


while (-not (Get-Command $chmoi -ErrorAction SilentlyContinue)) {
    if ((Get-Date) - $startTime -ge [TimeSpan]::FromSeconds($timeoutSeconds)) {
        Write-Host "'chezmoi' command not found within timeout period. Exiting." -ForegroundColor Yellow;
        exit 1;
    }
    Start-Sleep -Seconds 2;
}


try {
    $desktop = [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)
    $filePath = Join-Path -Path $desktop -ChildPath "hello.txt";

    Set-Content -Path $filePath -Value "This file was created because 'chezmoi' exists." -Force;

    Write-Host "Command 'chezmoi' found. File 'hello' created at $filePath" -ForegroundColor Green;
}
catch {
    Write-Host "Error creating the file: $($_.Exception.Message)" -ForegroundColor Red;
}

# put bws token here
$token = "";
setx BWS_ACCESS_TOKEN $token;
$env:BWS_ACCESS_TOKEN = $token;
$env:Path += ";$env:LOCALAPPDATA\Programs\nu\bin;C:\Program Files\GitHub CLI;$wingetLinks";
.$chmoi init reathe --apply;
