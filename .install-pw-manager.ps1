Write-Host "Downloading Bitwarden Secrets Manager installer..."

$script = [System.Text.Encoding]::UTF8.GetString((Invoke-WebRequest https://bws.bitwarden.com/install -UseBasicParsing).Content)

# Make sure we have a single string
if ($script -is [System.Array]) {
    $script = $script -join "`n"
}

Write-Host "Patching installer to avoid setx PATH..."

# Fix to the setx on path by the installer
$script = $script -replace 'setx PATH "\$env:PATH;\$installDir"', 
  '$linkExe = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData) | Join-Path -ChildPath "Microsoft" | Join-Path -ChildPath "WinGet" | Join-Path -ChildPath "Links" | Join-Path -ChildPath "bws.exe"
  if (Test-Path $linkExe) {
    Write-Host "shortcut link $linkExe exists already"
  } else {
    $installExe = Join-Path $installDir "bws.exe"
    Write-Host "Creating bws.exe shortcut in $linkExe from $installExe"
    New-Item -ItemType SymbolicLink -Path $linkExe -Target $installExe
  }'

# remove useless prints
$script = $script -replace '  Write-Host "\$installDir has been added to your PATH"\s*[\r\n]+', ''
$script = $script -replace '  Write-Host "Please restart your shell to use bws"\s*[\r\n]+', ''

# change asking to replace when already installed by environment variable
$script = $script -replace '(?s)\$userInput\s*=\s*Read-Host\s+"bws is already installed.*?\(Y/N\)"\s*if\s*\(\s*\$userInput\s*-ne\s*"Y"\s*\)\s*\{\s*Write-Host\s+"Installation cancelled by user\."\s*exit\s*\}', @'
if (-not $env:BWS_REINSTALL) {
    Write-Host "bws is already installed at $($existingBws.Source), skipping. (set BWS_REINSTALL=true to overwrite it)"
    exit
  }
  Write-Host "bws is already installed at $($existingBws.Source), reinstalling because BWS_REINSTALL=true..."
'@

# check if SHOW_INSTALLER is true
if ($env:SHOW_INSTALLER -eq "true") {
    Write-Host "Running patched installer... SHOW_INSTALLER=true, printing the script"
    Write-Host $script
}else{
    Write-Host "Running patched installer... set SHOW_INSTALLER=true print the script"
}

Invoke-Expression $script

