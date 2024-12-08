$StartupPath="HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$ProgramName="Kanata"
# change the executable path
$KanataPath="C:\Portable\Kanata\kanata_gui.exe"
# change the config path
$KanataConfigPath="$env:appdata\kanata-config\"
$KanataConfigName="kanata.kbd"
$KanataMadConfigName="kanata-mad.kbd"

# C:\Windows\system32\conhost.exe --headless 
$StartupCommand="`"$KanataPath`" --cfg `"$KanataConfigPath$KanataMadConfigName`" --cfg `"$KanataConfigPath$KanataConfigName`""
Set-ItemProperty -LiteralPath "$StartupPath" -Name "$ProgramName" -Value "$StartupCommand" 
