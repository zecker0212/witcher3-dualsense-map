# Witcher 3 DualSense — v1.0.1

[English guide](GUIDE.en.md) · [한국어 설명서](사용설명서.md)

## 한국어

Steam Input을 끄고 USB 듀얼센스를 사용하는 위쳐 3 PC Steam 버전용 설정 설치·원복 도구입니다.

| 입력 | 동작 |
|---|---|
| 옵션 짧게 | 기존 일시정지 메뉴 |
| 옵션 0.5초 길게 | 지도 |
| 터치패드 짧게 / 길게 | 원본 유지: 메뉴 / 소지품 |

패드 버튼 안내를 고정합니다. 키보드·마우스를 사용해도 안내는 패드 기준으로 유지됩니다. 스와이프와 캡처 버튼 기능은 추가하지 않습니다.

### 설치

1. **v1.0.0 사용자는 먼저 기존 v1.0.0 폴더의 Restore.cmd로 원복하세요.** 기존 터치패드 모드를 남기면 터치패드가 계속 지도를 엽니다. v1.0.1은 기존 모드를 자동으로 삭제하지 않습니다. 실험용 스와이프 도구도 종료하고 제거하세요.
2. [v1.0.1 Releases](https://github.com/zecker0212/witcher3-dualsense-touchpad/releases/tag/v1.0.1)에서 `Witcher3-DualSense-Setup-v1.0.1.zip`을 내려받아 쓰기 가능한 새 폴더에 압축을 풉니다. 이전 버전 폴더에 덮어쓰지 마세요.
3. 게임을 한 번 실행한 뒤 완전히 종료합니다. Steam Input은 끄고 듀얼센스는 USB로 연결합니다.
4. `Install.cmd`를 실행합니다. 설정 폴더를 찾지 못하면 `문서\The Witcher 3` 폴더를 선택합니다.
5. 게임에서 옵션 짧게/길게, 터치패드, 지도를 열고 닫을 때의 패드 안내를 확인합니다.

상주 프로그램, Steam Input, 게임 모드는 필요 없습니다. 설치 도구는 설정을 저장한 뒤 종료됩니다. 다른 사람도 자신의 설정 파일에 적용할 수 있습니다.

### 변경 및 원복

- `input.settings`: 기존 옵션 일시정지 항목이 있는 각 구간에 `IK_PS4_OPTIONS=(Action=PanelMap,State=Duration,IdleTime=0.5)`만 추가합니다.
- `user.settings`, `dx12user.settings`: 존재하는 파일의 `[Hidden]` 구간에서 `LockControlScheme=1`만 설정합니다.
- 터치패드, 세이브, 게임 원본 파일은 수정하지 않습니다. 전체 설정을 배포본으로 덮어쓰지 않습니다.
- 게임 종료 후 **설치에 썼던 같은 폴더의 `Restore.cmd`**를 실행하면 이번 설치가 변경한 항목만 설치 직전 값으로 복원합니다. 이후 바꾼 다른 설정은 유지합니다.
- 이미 같은 설정이 있던 항목은 원복 시 유지합니다. 설치 후 해당 항목이 다른 값으로 바뀌었다면 덮어쓰지 않고 중단합니다.
- `Backups/`와 `installation.json`을 보관하세요. 개인 경로와 설정이 들어갈 수 있으므로 공유하지 마세요. Windows 재설치나 다른 PC에서는 ZIP을 새로 풀어 설치하세요.

현재 사용자 PC에서 실제 동작을 확인했습니다. 배포 도구의 설치·원복은 별도 시험 설정으로 검증했습니다. 다른 입력 모드, 변경된 옵션 버튼 배치, 향후 게임 버전은 추가 확인이 필요합니다.

## English

A settings-only installer and restore tool for The Witcher 3 on Steam with a USB DualSense and **Steam Input disabled**.

- Tap **Options**: original pause menu.
- Hold **Options for 0.5 seconds**: world map.
- **Touchpad unchanged**: original menu on tap, inventory on hold.
- Keeps gamepad prompts visible, including when using keyboard/mouse.
- No swipe or Create-button support; no background helper or game mod.

**Upgrading from v1.0.0:** restore using the old version's `Restore.cmd` first. v1.0.1 does not remove old mods. Extract this version to a fresh folder, close the game, then run `Install.cmd`. Run `Restore.cmd` from that same folder to undo only changes made by this installation. Keep its private `Backups/` and `installation.json` locally.

The tool patches only the Options hold binding and `[Hidden] LockControlScheme` in the existing settings files. It preserves touchpad bindings, unrelated settings, saves, and original game files. See the [English guide](GUIDE.en.md) for recovery and troubleshooting.

Unofficial community tool; not affiliated with CD PROJEKT RED, Sony, or Valve.
