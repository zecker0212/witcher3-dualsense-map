# v1.0.1 English guide

## Requirements and installation

Windows PowerShell 5.1 (included in Windows), The Witcher 3 PC Steam, USB DualSense, Steam Input disabled. Launch and close the game once to create settings. Close the game before installing or restoring.

1. If upgrading from v1.0.0, run **the old version's Restore.cmd first**. The old mod changes the touchpad; v1.0.1 neither removes nor updates it. Stop/remove any experimental swipe helper separately.
2. Download the v1.0.1 release ZIP and extract to a new writable folder. Do not reuse another PC's installation record or overwrite an old version's folder.
3. Run `Install.cmd`. It detects the Windows Documents folder, including redirected Documents. If needed, select the folder containing `input.settings`, normally `Documents\The Witcher 3`.
4. Check Options tap (pause), Options hold for 0.5 seconds (map), unchanged touchpad controls, and gamepad prompts when opening/closing menus.

No administrator rights normally needed. The tool exits after changing settings; no helper runs during gameplay. It does not enable Steam Input or install a mod. Gameplay has been confirmed on the author's PC; other versions/mod combinations may differ.

## Exactly what changes

In every section with `IK_PS4_OPTIONS=(Action=IngameMenu)`, adds:

```ini
IK_PS4_OPTIONS=(Action=PanelMap,State=Duration,IdleTime=0.5)
```

In `[Hidden]` of existing `user.settings` (DX11) and `dx12user.settings` (DX12), sets:

```ini
LockControlScheme=1
```

At least one of these UI settings files must exist. Gamepad prompts remain selected even when keyboard/mouse are used. Touchpad bindings, unrelated settings, saves, game scripts, and installed mods are not modified. A different existing Options-duration binding causes installation to stop.

## Restore and backups

Close the game and run `Restore.cmd` from the **same extracted folder**. Only entries changed by this installation revert to their previous values. Identical settings present before installation stay in place. Later unrelated changes are preserved. If an edited entry changed after installation, restore stops rather than overwrite it. Keep `installation.json` and `Backups/`; do not upload them because they contain personal settings/paths.

Without the installation record, automatic restore is unavailable. With the game closed, manually remove this version's exact Options hold line from `input.settings` and restore the previous `LockControlScheme` value under `[Hidden]` using your backups (remove it if previously absent). Do not replace entire files with backups unless you also intend to discard subsequent settings changes.

For Windows/game reinstallation or another PC, use a fresh extraction. If existing settings already match, installation does not take ownership of those entries, and restore keeps them. The original v1.0.0 release remains available for its different touchpad behavior.

## Troubleshooting

- Close the game fully before running either command.
- If the touchpad still opens the map, restore the old v1.0.0 mod using its original tool.
- If an Options hold binding conflicts, restore your earlier remapping first.
- If prompts change again, confirm that the active DX11/DX12 settings file contains `LockControlScheme=1` under `[Hidden]`.
- Review the displayed error rather than rerunning with administrator rights automatically.

Advanced: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Setup.ps1 -Action Install -SettingsPath "D:\YourDocuments\The Witcher 3" -NonInteractive`
