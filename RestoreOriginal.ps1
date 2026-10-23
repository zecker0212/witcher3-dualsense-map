param([string]$GamePath,[string]$SettingsPath,[switch]$NonInteractive)
$ErrorActionPreference='Stop'
$utf8=New-Object System.Text.UTF8Encoding($false)
function Choose($message){
    if($NonInteractive){throw $message}
    Add-Type -AssemblyName System.Windows.Forms
    $d=New-Object System.Windows.Forms.FolderBrowserDialog
    $d.Description=$message
    if($d.ShowDialog() -ne 'OK'){throw 'Cancelled.'}
    $d.SelectedPath
}
try {
    if(Get-Process -Name 'witcher3','witcher3_dx12' -ErrorAction SilentlyContinue){throw 'Close The Witcher 3 first.'}
    if(-not $GamePath){
        $roots=@('C:\Program Files (x86)\Steam','D:\SteamLibrary','E:\SteamLibrary')
        try {$s=(Get-ItemProperty 'HKCU:\Software\Valve\Steam').SteamPath; if($s){$roots+=$s}} catch {}
        foreach($root in @($roots)){
            $vdf=Join-Path $root 'steamapps\libraryfolders.vdf'
            if(Test-Path -LiteralPath $vdf){foreach($m in [regex]::Matches([IO.File]::ReadAllText($vdf),'"path"\s+"([^"]+)"')){$roots+=$m.Groups[1].Value.Replace('\\','\')}}
        }
        $found=@($roots | Select-Object -Unique | ForEach-Object {Join-Path $_ 'steamapps\common\The Witcher 3'} | Where-Object {Test-Path -LiteralPath (Join-Path $_ 'content\content0\scripts\game\player\playerInput.ws')})
        if($found.Count -eq 1){$GamePath=$found[0]}else{$GamePath=Choose 'Select The Witcher 3 game folder (bin and content).'}
    }
    $GamePath=(Resolve-Path -LiteralPath $GamePath).Path
    if(-not(Test-Path -LiteralPath (Join-Path $GamePath 'content\content0\scripts\game\player\playerInput.ws'))){throw 'Invalid game folder.'}
    if(-not $SettingsPath){$SettingsPath=Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'The Witcher 3'}
    if(-not(Test-Path -LiteralPath (Join-Path $SettingsPath 'input.settings'))){$SettingsPath=Choose 'Select Documents\The Witcher 3 (input.settings).'}
    $SettingsPath=(Resolve-Path -LiteralPath $SettingsPath).Path
    $inputPath=Join-Path $SettingsPath 'input.settings'
    $inputText=[IO.File]::ReadAllText($inputPath)
    if($inputText.Contains('TouchpadMapMenu')){throw 'An earlier experimental binding is present. Restore its original input.settings backup first.'}
    $mod=Join-Path $GamePath 'Mods\modTouchpadMapInventory'
    if(Test-Path -LiteralPath $mod){
        $script=Join-Path $mod 'content\scripts\game\player\playerInput.ws'
        $files=@(Get-ChildItem -LiteralPath $mod -Recurse -File)
        if($files.Count -ne 1 -or -not(Test-Path -LiteralPath $script)){throw 'Unexpected files in mod folder; automatic removal stopped.'}
        $code=[IO.File]::ReadAllText($script)
        $signature="if( theInput.LastUsedGamepad() )`r`n`t`t`t{`r`n`t`t`t`tPushMapScreen();`r`n`t`t`t`treturn false;`r`n`t`t`t}`r`n`t`t`t`r`n`t`t`tif( IsActionAllowed( EIAB_OpenFastMenu ) )"
        if(-not $code.Contains($signature)){throw 'Mod is not recognized; automatic removal stopped.'}
        $resolved=(Resolve-Path -LiteralPath $mod).Path
        if($resolved -ine [IO.Path]::GetFullPath($mod)){throw 'Unexpected mod path.'}
    }
    $changes=@()
    foreach($name in @('user.settings','dx12user.settings')){
        $p=Join-Path $SettingsPath $name
        if(Test-Path -LiteralPath $p){
            $text=[IO.File]::ReadAllText($p)
            $h=[regex]::Match($text,'(?ms)^\[Hidden\]\r?\n.*?(?=^\[|\z)')
            if($h.Success){
                $section=[regex]::Replace($h.Value,'(?m)^LockControlScheme=1(?:\r?\n|$)','')
                $new=$text.Substring(0,$h.Index)+$section+$text.Substring($h.Index+$h.Length)
                if($new -cne $text){$changes+=@{Path=$p; Text=$new}}
            }
        }
    }
    if(-not(Test-Path -LiteralPath $mod) -and $changes.Count -eq 0){Write-Host 'Already restored. Nothing to change.' -ForegroundColor Green; exit 0}
    $backup=Join-Path $PSScriptRoot ('Backups\manual-restore-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    foreach($item in $changes){Copy-Item -LiteralPath $item.Path -Destination $backup}
    if(Test-Path -LiteralPath $mod){Move-Item -LiteralPath $resolved -Destination (Join-Path $backup 'removed-modTouchpadMapInventory')}
    foreach($item in $changes){[IO.File]::WriteAllText($item.Path,$item.Text,$utf8); if([IO.File]::ReadAllText($item.Path) -cne $item.Text){throw 'Write verification failed; backups are available.'}}
    Write-Host 'Restored: touchpad mod disabled; gamepad UI lock removed. Other settings and saves preserved.' -ForegroundColor Green
    Write-Host ('Backup: '+$backup)
} catch {Write-Host ('STOPPED: '+$_.Exception.Message) -ForegroundColor Red; exit 1}
