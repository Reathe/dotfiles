Write-Host "Downloading Bitwarden Secrets Manager installer..."

$script = [System.Text.Encoding]::UTF8.GetString((Invoke-WebRequest https://bws.bitwarden.com/install -UseBasicParsing).Content)

# Make sure we have a single string
if ($script -is [System.Array]) {
    $script = $script -join "`n"
}

Write-Host "Patching installer to avoid setx PATH..."

$script = $script -replace 'setx PATH "\$env:PATH;\$installDir"', 
'$linkExe = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData) | Join-Path -ChildPath "Microsoft" | Join-Path -ChildPath "WinGet" | Join-Path -ChildPath "Links" | Join-Path -ChildPath "bws.exe"
    if (Test-Path $linkExe) {
        Write-Host "$linkExe exists already"
    } else {
        $installExe = Join-Path $installDir "bws.exe"
        Write-Host "Creating bws.exe shortcut in $linkExe from $installExe"
        New-Item -ItemType SymbolicLink -Path $linkExe -Target $installExe
    }
'

# check if SHOW_INSTALLER is true
if ($env:SHOW_INSTALLER -eq "true") {
    Write-Host "Running patched installer... SHOW_INSTALLER=true, printing the script"
    Write-Host $script
}else{
    Write-Host "Running patched installer... set SHOW_INSTALLER=true print the script"
}

Invoke-Expression $script
Write-Host "bws installed safely without adding to PATH."




