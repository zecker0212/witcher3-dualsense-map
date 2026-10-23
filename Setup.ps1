param([ValidateSet('Install','Uninstall')][string]$Action='Install',[string]$SettingsPath,[switch]$NonInteractive)
$ErrorActionPreference='Stop'
$statePath=Join-Path $PSScriptRoot 'installation.json'
$hold='IK_PS4_OPTIONS=(Action=PanelMap,State=Duration,IdleTime=0.5)'
function Sections($text) { [regex]::Matches($text,'(?ms)^\[([^\]\r\n]+)\]\r?\n.*?(?=^\[|\z)') }
function Save($path,$text,$bom) { [IO.File]::WriteAllText($path,$text,(New-Object Text.UTF8Encoding([bool]$bom))) }
function Replace-Section($text,$name,$old,$new) {
    $found=@(Sections $text | Where-Object {$_.Groups[1].Value -ceq $name})
    if($found.Count -ne 1){throw "Missing/duplicate section: $name"}
    $s=$found[0]
    if($old -eq ''){throw 'Invalid empty replacement anchor.'}
    if(([regex]::Matches($s.Value,[regex]::Escape($old))).Count -ne 1){throw "Setting changed since installation: $name. No files changed."}
    $text.Substring(0,$s.Index)+$s.Value.Replace($old,$new)+$text.Substring($s.Index+$s.Length)
}
try {
    if(Get-Process witcher3,witcher3_dx12 -ErrorAction SilentlyContinue){throw 'Close The Witcher 3 first.'}
    $changes=@()
    if($Action -eq 'Uninstall') {
        if(!(Test-Path -LiteralPath $statePath)){throw 'No installation.json. Use the same folder used to install. See README for manual restore.'}
        $state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        if($state.Version -ne '1.0.1'){throw 'Use the matching older version to restore first.'}
        foreach($f in $state.Files){
            $before=[IO.File]::ReadAllText($f.Path); $after=$before
            foreach($e in $f.Edits){$after=Replace-Section $after $e.Section $e.After $e.Before}
            $changes+=@{Path=$f.Path;Before=$before;After=$after;Bom=$f.Bom}
        }
    } else {
        if(Test-Path -LiteralPath $statePath){throw 'Already installed here. Restore before installing again.'}
        if(!$SettingsPath){$SettingsPath=Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'The Witcher 3'}
        if(!(Test-Path -LiteralPath (Join-Path $SettingsPath 'input.settings'))){
            if($NonInteractive){throw 'input.settings not found.'}
            Add-Type -AssemblyName System.Windows.Forms
            $dialog=New-Object Windows.Forms.FolderBrowserDialog
            $dialog.Description='Select Documents\The Witcher 3 (contains input.settings)'
            if($dialog.ShowDialog() -ne 'OK'){throw 'Cancelled.'}
            $SettingsPath=$dialog.SelectedPath
        }
        $SettingsPath=(Resolve-Path -LiteralPath $SettingsPath).Path
        $files=@(); $pauseCount=0
        foreach($name in @('input.settings','user.settings','dx12user.settings')){
            $path=Join-Path $SettingsPath $name
            if(!(Test-Path -LiteralPath $path)){if($name -eq 'input.settings'){throw 'input.settings missing.'}; continue}
            $raw=[IO.File]::ReadAllBytes($path)
            if($raw.Length -gt 1 -and (($raw[0] -eq 255 -and $raw[1] -eq 254) -or ($raw[0] -eq 254 -and $raw[1] -eq 255))){throw 'UTF-16 settings are unsupported; no files changed.'}
            $bom=$raw.Length -ge 3 -and $raw[0] -eq 239 -and $raw[1] -eq 187 -and $raw[2] -eq 191
            $before=[IO.File]::ReadAllText($path); $after=$before; $edits=@()
            $sections=@(Sections $before)
            if(@($sections | Group-Object {$_.Groups[1].Value} | Where-Object Count -gt 1).Count){throw 'Duplicate settings sections.'}
            foreach($s in $sections){
                $old=$null; $new=$null
                if($name -eq 'input.settings'){
                    $anchor=[regex]::Match($s.Value,'(?m)^IK_PS4_OPTIONS=\(Action=IngameMenu\)(\r?\n)')
                    if(!$anchor.Success){continue}
                    $pauseCount++
                    $existing=@([regex]::Matches($s.Value,'(?m)^IK_PS4_OPTIONS=[^\r\n]*State=Duration[^\r\n]*'))
                    if($existing.Count){
                        if($existing.Count -eq 1 -and $existing[0].Value -ceq $hold){continue}
                        throw 'An Options hold binding already exists. Restore it before installing.'
                    }
                    $old=$anchor.Value; $new=$old+$hold+$anchor.Groups[1].Value
                } elseif($s.Groups[1].Value -ceq 'Hidden'){
                    $lock=@([regex]::Matches($s.Value,'(?m)^LockControlScheme=[^\r\n]*'))
                    if($lock.Count -gt 1){throw 'Duplicate UI lock settings.'}
                    if($lock.Count){$old=$lock[0].Value; $new='LockControlScheme=1'}
                    else {$old=[regex]::Match($s.Value,'^\[Hidden\](\r?\n)').Value; $new=$old+'LockControlScheme=1'+[regex]::Match($old,'\r?\n').Value}
                }
                if($null -ne $old -and $old -cne $new){
                    $after=Replace-Section $after $s.Groups[1].Value $old $new
                    if($new.StartsWith($old) -and ($name -eq 'input.settings' -or $old.StartsWith('[Hidden]'))){
                        $edits+=@{Section=$s.Groups[1].Value;Before='';After=$new.Substring($old.Length)}
                    } else {$edits+=@{Section=$s.Groups[1].Value;Before=$old;After=$new}}
                }
            }
            if($name -ne 'input.settings' -and !(@($sections | Where-Object {$_.Groups[1].Value -ceq 'Hidden'}).Count)){throw "Hidden section missing in $name. Launch and exit the game first."}
            $files+=@{Path=$path;Bom=$bom;Edits=@($edits)}
            $changes+=@{Path=$path;Before=$before;After=$after;Bom=$bom}
        }
        if($pauseCount -eq 0 -or $files.Count -lt 2){throw 'Expected game settings not found. Launch and exit the game first.'}
        $backup=Join-Path $PSScriptRoot ('Backups\'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
        New-Item -ItemType Directory -Path $backup -Force | Out-Null
        foreach($f in $files){Copy-Item -LiteralPath $f.Path -Destination $backup}
        $state=@{Version='1.0.1';BackupPath=$backup;Files=@($files)}
    }
    $written=@()
    try {
        foreach($c in $changes){
            if([IO.File]::ReadAllText($c.Path) -cne $c.Before){throw 'Settings changed while running. Close the game and retry.'}
            $written+=$c
            Save $c.Path $c.After $c.Bom
            if([IO.File]::ReadAllText($c.Path) -cne $c.After){throw 'Write verification failed.'}
        }
        if($Action -eq 'Install'){Save $statePath ($state | ConvertTo-Json -Depth 8) $false}
        else {Move-Item -LiteralPath $statePath -Destination (Join-Path $state.BackupPath ('restored-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'.json'))}
    } catch {
        foreach($c in $written){Save $c.Path $c.Before $c.Bom}
        throw
    }
    Write-Host "$Action completed. v1.0.1" -ForegroundColor Green
    if($Action -eq 'Install'){Write-Host 'Options: tap = pause; hold 0.5 seconds = map. Touchpad unchanged. Gamepad prompts locked.'}
    exit 0
} catch {Write-Host $_.Exception.Message -ForegroundColor Red; exit 1}
