# The Witcher 3 PC Steam — DualSense Touchpad Guide

[Back to README](README.md) · [한국어 설명서](사용설명서.md)

This Windows package recreates the touchpad setup confirmed working on the original test PC. It uses the game's native DualSense support with Steam Input disabled.

## Controls

| Input | Result |
|---|---|
| Briefly click and release the touchpad | Open the world map |
| Hold the touchpad for at least 0.3 seconds | Open the inventory |
| Close a menu with the touchpad | Use the game's existing close behavior |
| Button prompts | Locked to gamepad mode |

Swipe gestures are not added. The UI lock also keeps gamepad prompts visible when you use a keyboard or mouse. Other controller buttons bound to the same `FastMenu` action may also open the map.

## Installation, including after reinstalling Windows or the game

1. Install The Witcher 3 through Steam.
2. Connect your DualSense. In Steam, open the game's **Properties → Controller** and disable Steam Input for this game. Use a connection method and in-game configuration that already work with native DualSense support on your PC.
3. Launch the game once, then exit completely. This creates the settings files in your Documents folder. If you plan to use both DirectX 11 and DirectX 12, launch and exit each version once.
4. Download the repository using **Code → Download ZIP** and **extract it** to a writable personal folder. Do not run the tools from inside the ZIP.
5. Double-click `Install.cmd`.
6. The tool searches Steam library folders. If asked for the game folder, select **The Witcher 3**, containing `bin` and `content`. If asked for the settings folder, select **Documents\The Witcher 3**, containing `input.settings`. If Documents is redirected to OneDrive, select the actual folder containing these files.
7. A green `Installed` message confirms completion. Start the game and check the map, inventory, and PlayStation button prompts.

The tool does not change Steam settings, adaptive trigger settings, vibration, or the controller connection method. Its PowerShell execution-policy override applies only to the launched process; it does not permanently change the system execution policy.

## Restore the previous setup

Close the game, then double-click **`Restore.cmd` in the same extracted folder used for installation**.

### With an installation record

- The installed mod is moved out of the game into the backup folder.
- The UI lock value is restored to its pre-installation state.
- Subsequent changes to unrelated settings, such as graphics and audio, are preserved.
- If the UI was already locked to gamepad mode before installation, it remains locked after restoration. To enable automatic prompt switching, close the game and remove `LockControlScheme=1`, or change it to `0`, under `[Hidden]` in `user.settings` and `dx12user.settings`, where present.

### Without an installation record

`Restore.cmd` can also work without `installation.json`. It finds the game folder, moves the recognized touchpad mod into a backup folder, and removes `LockControlScheme=1` to restore automatic prompt switching. It cannot recover an unknown earlier UI setting, so it also removes a gamepad lock that may have existed before the mod. If nothing needs restoring, it makes no changes. Unrecognized mod contents cause restoration to stop.

Keep the package's `Backups` folder and `installation.json` together. The record contains the paths for that PC. On a new PC or after reinstalling Windows, **extract a fresh copy of the original ZIP**; do not reuse the old installation record.

## Files changed

- Creates `Mods\modTouchpadMapInventory\content\scripts\game\player\playerInput.ws` inside the game folder. The tool reads the installed original script and adds a gamepad map-opening branch to the existing short-menu action. Existing long-press handling and suppression of an extra action on release remain intact.
- Sets `LockControlScheme=1` under `[Hidden]` in whichever of `user.settings` and `dx12user.settings` exist in the game's Documents folder. This is the game's built-in gamepad UI lock.
- Leaves `input.settings` unchanged, using the original touchpad bindings.
- Leaves the original scripts under the game's `content` folder and save files unchanged.

## Updates and troubleshooting

- **Game running:** exit it completely before running either tool.
- **Folder not found:** use Steam's **Manage → Browse local files** to locate the game directory.
- **Access denied:** check write permissions. If the game is in a protected folder and elevation is needed, right-click the CMD file and run it as administrator.
- **Conflicting input mod:** installation stops if another mod contains `playerInput.ws`. Remove the conflicting mod or arrange a separate merge; this tool does not merge mods.
- **Unexpected touchpad bindings:** experimental or custom bindings may stop installation. Restore the original `input.settings` first. Back up the file before resetting it, since resetting can remove other custom bindings.
- **Changed game code:** installation stops when the original script no longer has the expected structure. Compatibility with all future updates is not guaranteed.
- **After a game update:** run `Restore.cmd` from the existing package folder, then `Install.cmd` to regenerate the mod from the updated game script. If the game reports script errors immediately after an update, restore first.
- **Mod modified after installation:** restoration with an installation record stops if the mod files have changed, rather than overwriting or removing unexpected files.
- **Manual removal:** close the game, move only `Mods\modTouchpadMapInventory` outside the game folder, and set `LockControlScheme=0` under `[Hidden]` in both settings files where present. This restores automatic prompt switching.

## Validation and sharing

Map and inventory shortcuts and locked gamepad prompts were confirmed during gameplay on the original test PC. The installer and restore tools were tested in separate folders using Windows PowerShell, including preservation of unrelated settings and stopping on incompatible code or conflicting mods. Actual play on other PCs or future game versions still needs verification.

Share the original repository ZIP, not your installed package folder. `Backups/` and `installation.json` can contain game scripts, settings, and personal paths. The repository excludes them with `.gitignore`.

This is an unofficial community tool and is not affiliated with CD PROJEKT RED, Sony, or Valve.
