param(
    [ValidateSet('Install','Uninstall')][string]$Action='Install',
    [string]$GamePath,
    [string]$SettingsPath,
    [switch]$NonInteractive
)
$ErrorActionPreference='Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$statePath=Join-Path $PSScriptRoot 'installation.json'
$modName='modTouchpadMapInventory'
function Write-Utf8($Path,$Text) { [IO.File]::WriteAllText($Path,$Text,$utf8) }
function Hash($Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
function Choose-Folder($Description) {
    if($NonInteractive){throw $Description}
    Add-Type -AssemblyName System.Windows.Forms
    $dialog=New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description=$Description
    if($dialog.ShowDialog() -ne 'OK'){throw 'Cancelled.'}
    $dialog.SelectedPath
}
function Check-Game($Path) {
    $Path -and (Test-Path -LiteralPath (Join-Path $Path 'content\content0\scripts\game\player\playerInput.ws'))
}
function Set-Lock($Text,$Value) {
    $nl="`r`n"; if(-not $Text.Contains("`r`n")){$nl="`n"}
    $match=[regex]::Match($Text,'(?ms)^\[Hidden\]\r?\n.*?(?=^\[|\z)')
    if(-not $match.Success){
        if($null -eq $Value){return $Text}
        return $Text+$nl+'[Hidden]'+$nl+'LockControlScheme='+$Value+$nl
    }
    $section=$match.Value
    $pattern='(?m)^LockControlScheme=[^\r\n]*(?:\r?\n|$)'
    if($null -eq $Value){$section=[regex]::Replace($section,$pattern,'')}
    elseif([regex]::IsMatch($section,$pattern)){$section=[regex]::Replace($section,$pattern,('LockControlScheme='+$Value+$nl))}
    else {$section=$section.Insert($section.IndexOf("`n")+1,('LockControlScheme='+$Value+$nl))}
    $Text.Substring(0,$match.Index)+$section+$Text.Substring($match.Index+$match.Length)
}
try {
    if(Get-Process -Name 'witcher3','witcher3_dx12' -ErrorAction SilentlyContinue){throw 'Close The Witcher 3 before running this tool.'}
    if($Action -eq 'Uninstall') {
        if(-not(Test-Path -LiteralPath $statePath)){throw 'No installation record here. Use the same extracted folder that you used to install.'}
        $state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        $mod=Join-Path $state.GamePath ('Mods\'+$modName)
        $script=Join-Path $mod 'content\scripts\game\player\playerInput.ws'
        if(Test-Path -LiteralPath $mod){
            if(-not(Test-Path -LiteralPath $script)){throw 'Mod folder was changed. Automatic removal stopped.'}
            $files=@(Get-ChildItem -LiteralPath $mod -Recurse -File)
            if($files.Count -ne 1 -or (Hash $script) -ne $state.ModHash){throw 'Mod files were changed after installation. Automatic removal stopped.'}
        }
        $restores=@()
        foreach($item in $state.Settings){
            if(-not(Test-Path -LiteralPath $item.Path)){throw ('Settings file is missing: '+$item.Path)}
            $text=[IO.File]::ReadAllText($item.Path)
            $value=$null; if($item.HadLock){$value=[string]$item.PreviousLock}
            $restores+=@{Path=$item.Path; Text=(Set-Lock $text $value)}
        }
        # Move only the exact, validated mod folder into the saved backup directory.
        if(Test-Path -LiteralPath $mod){
            $resolved=(Resolve-Path -LiteralPath $mod).Path
            $expected=[IO.Path]::GetFullPath((Join-Path $state.GamePath ('Mods\'+$modName)))
            if($resolved -ine $expected){throw 'Unexpected mod path.'}
            Move-Item -LiteralPath $resolved -Destination (Join-Path $state.BackupPath ('removed-mod-'+(Get-Date -Format 'yyyyMMdd-HHmmss')))
        }
        foreach($item in $restores){Write-Utf8 $item.Path $item.Text}
        Move-Item -LiteralPath $statePath -Destination (Join-Path $state.BackupPath 'installation-removed.json')
        Write-Host 'Removed. Previous UI setting restored; other current settings preserved.' -ForegroundColor Green
        exit 0
    }
    if(Test-Path -LiteralPath $statePath){throw 'Already installed from this folder. Run Restore first before reinstalling or updating.'}
    if(-not $GamePath){
        $roots=@('C:\Program Files (x86)\Steam','D:\SteamLibrary','E:\SteamLibrary')
        try {$steam=(Get-ItemProperty 'HKCU:\Software\Valve\Steam').SteamPath; if($steam){$roots+= $steam}} catch {}
        foreach($root in @($roots)){
            $vdf=Join-Path $root 'steamapps\libraryfolders.vdf'
            if(Test-Path -LiteralPath $vdf){
                foreach($m in [regex]::Matches([IO.File]::ReadAllText($vdf),'"path"\s+"([^"]+)"')){$roots+=$m.Groups[1].Value.Replace('\\','\')}
            }
        }
        $candidates=@($roots | Select-Object -Unique | ForEach-Object {Join-Path $_ 'steamapps\common\The Witcher 3'} | Where-Object {Check-Game $_})
        if($candidates.Count -eq 1){$GamePath=$candidates[0]}
        else {$GamePath=Choose-Folder 'Select The Witcher 3 game folder (contains bin and content).'}
    }
    if(-not(Check-Game $GamePath)){throw 'Not a supported The Witcher 3 game folder.'}
    $GamePath=(Resolve-Path -LiteralPath $GamePath).Path
    if(-not $SettingsPath){$SettingsPath=Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'The Witcher 3'}
    if(-not(Test-Path -LiteralPath (Join-Path $SettingsPath 'input.settings'))){$SettingsPath=Choose-Folder 'Select Documents\The Witcher 3 (contains input.settings). Run the game once first.'}
    if(-not(Test-Path -LiteralPath (Join-Path $SettingsPath 'input.settings'))){throw 'input.settings not found. Launch and exit the game first.'}
    $SettingsPath=(Resolve-Path -LiteralPath $SettingsPath).Path
    $inputText=[IO.File]::ReadAllText((Join-Path $SettingsPath 'input.settings'))
    if($inputText.Contains('TouchpadMapMenu') -or -not $inputText.Contains('IK_PS4_TOUCH_PRESS=(Action=FastMenu)') -or -not $inputText.Contains('IK_PS4_TOUCH_PRESS=(Action=HoldFastMenu,State=Duration,IdleTime=0.3)')){throw 'Touchpad bindings are not the expected original bindings. Restore original input.settings first.'}
    $source=Join-Path $GamePath 'content\content0\scripts\game\player\playerInput.ws'
    $code=[IO.File]::ReadAllText($source)
    $anchor='if( IsActionAllowed( EIAB_OpenFastMenu ) )'
    $eventStart=$code.IndexOf('event OnFastMenu( action : SInputAction )')
    $anchorIndex=$code.IndexOf($anchor)
    if($eventStart -lt 0 -or $anchorIndex -lt $eventStart -or $anchorIndex-$eventStart -gt 2000 -or ([regex]::Matches($code,[regex]::Escape($anchor))).Count -ne 1){throw 'Game code differs from the supported layout. Nothing has been installed.'}
    $handler=$code.Substring($eventStart,$anchorIndex-$eventStart)
    if(-not $handler.Contains('holdFastMenuInvoked') -or -not $handler.Contains('IsReleased(action)')){throw 'Hold/release handling changed. Installation stopped.'}
    $gui=[IO.File]::ReadAllText((Join-Path $GamePath 'content\content0\scripts\game\gui\r4guimanager.ws'))
    if($gui -notmatch '(?s)enum ELockedControlScheme\s*\{\s*LCS_None,\s*LCS_Gamepad,'){throw 'Gamepad UI setting has changed. Installation stopped.'}
    $mods=Join-Path $GamePath 'Mods'
    $dest=Join-Path $mods $modName
    if(Test-Path -LiteralPath $mods){
        foreach($file in Get-ChildItem -LiteralPath $mods -Recurse -Filter 'playerInput.ws' -File){
            if($file.FullName -ine (Join-Path $dest 'content\scripts\game\player\playerInput.ws')){throw ('Another input mod may conflict: '+$file.FullName)}
        }
    }
    $addition="if( theInput.LastUsedGamepad() )`r`n`t`t`t{`r`n`t`t`t`tPushMapScreen();`r`n`t`t`t`treturn false;`r`n`t`t`t}`r`n`t`t`t`r`n`t`t`t"
    $patched=$code.Replace($anchor,$addition+$anchor)
    if($patched.Replace($addition,'') -cne $code){throw 'Patch verification failed.'}
    if(Test-Path -LiteralPath $dest){
        $old=Join-Path $dest 'content\scripts\game\player\playerInput.ws'
        if(-not(Test-Path -LiteralPath $old)){throw 'Existing mod folder is not recognized.'}
        if([IO.File]::ReadAllText($old) -cne $patched -or @(Get-ChildItem -LiteralPath $dest -Recurse -File).Count -ne 1){throw 'Existing mod differs. Remove or merge it manually before installing.'}
    }
    $settings=@()
    foreach($name in @('user.settings','dx12user.settings')){
        $path=Join-Path $SettingsPath $name
        if(Test-Path -LiteralPath $path){
            $text=[IO.File]::ReadAllText($path)
            $hidden=[regex]::Match($text,'(?ms)^\[Hidden\]\r?\n.*?(?=^\[|\z)').Value
            $lock=[regex]::Match($hidden,'(?m)^LockControlScheme=([^\r\n]*)')
            $settings+=@{Path=$path; HadLock=$lock.Success; PreviousLock=$lock.Groups[1].Value; NewText=(Set-Lock $text '1')}
        }
    }
    if($settings.Count -eq 0){throw 'No user.settings or dx12user.settings. Run the game once first.'}
    $backup=Join-Path $PSScriptRoot ('Backups\'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $SettingsPath 'input.settings') -Destination $backup
    foreach($item in $settings){Copy-Item -LiteralPath $item.Path -Destination $backup}
    Copy-Item -LiteralPath $source -Destination (Join-Path $backup 'playerInput.original.ws')
    if(Test-Path -LiteralPath $dest){Copy-Item -LiteralPath $dest -Destination (Join-Path $backup 'previous-mod') -Recurse}
    $target=Join-Path $dest 'content\scripts\game\player\playerInput.ws'
    New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
    Write-Utf8 $target $patched
    $state=@{GamePath=$GamePath; SettingsPath=$SettingsPath; BackupPath=$backup; ModHash=(Hash $target); Settings=@($settings | ForEach-Object {@{Path=$_.Path; HadLock=$_.HadLock; PreviousLock=$_.PreviousLock}})}
    Write-Utf8 $statePath ($state | ConvertTo-Json -Depth 6)
    foreach($item in $settings){Write-Utf8 $item.Path $item.NewText; if([IO.File]::ReadAllText($item.Path) -cne $item.NewText){throw 'Settings write verification failed. Run Restore.'}}
    if([IO.File]::ReadAllText($target) -cne $patched){throw 'Mod write verification failed. Run Restore.'}
    Write-Host 'Installed: tap = map; hold 0.3 seconds = inventory; gamepad UI locked.' -ForegroundColor Green
    Write-Host ('Backups: '+$backup)
    Write-Host 'Keep this folder for Restore. Restart the game and test both actions.'
} catch {
    Write-Host ('STOPPED: '+$_.Exception.Message) -ForegroundColor Red
    exit 1
}
