# Android debug APK and physical-device checklist

This guide covers a private, offline test build of the existing game. Use Godot **4.7.2** for the documented export setup. Run PowerShell commands from the project folder and replace example installation paths or device serials with your own.

## Current verification status

Godot 4.7.2 passed the full regression suite: **1,250 checks, 0 failures**. The rendered native touch/save probe also passed **134 checks, 0 failures**. Separate desktop processes confirmed save/load persistence using an isolated profile; Android lifecycle persistence remains a phone-test step below.

The repository has an Android export preset and portrait/touch project settings. A resource pack exported with that preset contains the main scene, all six screens, runtime scripts, theme, and all seven imported images; tests, this guide, and the README are excluded. The game's portrait layouts have also been checked in Windows Godot windows at 360 × 800 and 440 × 900, alongside 1180 × 780 desktop checks.

Touch propagation through cards, panels, and buttons was corrected so vertical drags reach the page's `ScrollContainer`. A Windows Godot probe simulated touchscreen availability for the swipe check only: an 80-pixel swipe that stayed inside its original part card moved the scroll position and cancelled the card tap. Real-phone touch behavior remains part of the checklist below.

These are **project, resource-pack, and simulated layout checks**. An Android APK has not yet been built or run on a physical phone. During the 2026-10-05 audit, this PC's export-template directory was empty, its configured Android SDK directory did not exist, and its Java SDK setting was empty. `java`, `keytool`, and `adb` were not available on PATH or at the common installation locations checked. Device connection could not be assessed without `adb`. No tools were installed and no device was changed during that audit.

## Preset already in the repository

Open **Project → Export → Android Test**. Keep these settings for the first phone test:

| Setting | Current value |
| --- | --- |
| Build | Signed debug APK; Gradle build disabled |
| Output file | `pc-builder-debug.apk` in the project folder |
| Package ID / launcher name | `org.example.pcbuilder` / `PC Builder` |
| Version code / version name | `1` / `0.1.0` |
| Architectures | ARMv7 and ARM64; no x86 builds |
| Orientation | Portrait |
| Renderer | Compatibility on desktop and mobile |
| Scaling | 440 × 900 base, `canvas_items`, aspect `expand` |
| System bars | Immersive mode off; edge-to-edge off |
| Permissions | All engine permission options off; custom list empty |
| Android backup | Off; progress remains local |
| Resources | All resources; exclude `tests/*,docs/*,README.md` |

This uses Godot's prebuilt APK workflow. Do not install a custom Android build template or switch to AAB for this test. Minimum/target SDK override fields apply to Gradle exports, so check the actual APK manifest instead of relying on those fields here. [Godot Android export options](https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformandroid.html)

The engine's non-immersive, non-edge-to-edge Android mode applies native system-bar and display-cutout insets. The game therefore keeps its existing shared page margins. Confirm that behavior on the target phone rather than adding another unmeasured inset. [Godot 4.7.2 Android window handling](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/platform/android/java/lib/src/main/java/org/godotengine/godot/Godot.kt#L349)

## 1. Set up the Windows export tools

1. Install the Android export templates matching **Godot 4.7.2** using **Editor → Manage Export Templates**. Select the Android architectures and install the selected templates, or install the matching downloaded `.tpz`. An export-template version must match the editor. [Godot export templates](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html#export-templates)
2. Install **OpenJDK 17** and the Android SDK. In Android Studio's SDK Manager, enable **Show Package Details** when selecting exact package versions:

   | SDK package | Godot 4.7 documented version |
   | --- | --- |
   | Android SDK Platform-Tools | 35.0.0 or later |
   | Android SDK Build-Tools | 35.0.1 |
   | Android SDK Platform | Android 15 / API 35 |
   | Android SDK Command-line Tools | Latest |
   | CMake | 3.10.2.4988404 |
   | NDK (Side by side) | r28b / 28.1.13356709 |

3. In Godot, open **Editor → Editor Settings → Export → Android**. Set **Java SDK Path** to the JDK's root folder containing `bin/java.exe` and `bin/keytool.exe`. Set **Android SDK Path** to the SDK root containing `platform-tools/adb.exe`, commonly `%LOCALAPPDATA%\Android\Sdk`. These are machine settings, not paths committed in this project. [Godot 4.7 Android setup](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)
4. Check that the configured files exist. For example, adjust the JDK path below, then run:

   ```powershell
   $pcbuilderJdk = 'C:\Program Files\Eclipse Adoptium\jdk-17.x.x'
   $pcbuilderSdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
   & (Join-Path $pcbuilderJdk 'bin\java.exe') -version
   & (Join-Path $pcbuilderSdk 'platform-tools\adb.exe') version
   ```

   Java should report version 17. If the SDK lives elsewhere, replace `$pcbuilderSdk` with that configured root.

## 2. Confirm the debug signing key

After a valid Java SDK is configured, Godot normally creates its debug keystore outside the project. In **Editor Settings → Export → Android**, confirm that **Debug Keystore** points to an existing file, **Debug Keystore User** is `androiddebugkey`, and **Debug Keystore Pass** is `android`. Leave the preset's debug-keystore fields empty so it uses those editor settings. [Godot debug-key creation](https://github.com/godotengine/godot/blob/4.7-stable/platform/android/export/export_plugin.cpp#L866)

If automatic creation did not succeed, create a test key manually at the normal Godot location, then select it in those editor settings. Run this only when the file is absent:

```powershell
$pcbuilderKey = Join-Path $env:APPDATA 'Godot\keystores\debug.keystore'
New-Item -ItemType Directory -Force (Split-Path -Parent $pcbuilderKey) | Out-Null
if (-not (Test-Path -LiteralPath $pcbuilderKey)) {
    & (Join-Path $pcbuilderJdk 'bin\keytool.exe') -genkeypair -keystore $pcbuilderKey -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=PC Builder Test'
}
```

Keep the same key for subsequent installs over this test app. Debug signing is appropriate for private testing; it is not a release-signing workflow. Do not commit the keystore or `.godot/export_credentials.cfg`. Android requires compatible signing identities for app updates. [Android app signing](https://developer.android.com/studio/publish/app-signing)

## 3. Export and inspect the APK

1. Import the project in Godot 4.7.2 and let resource imports finish.
2. Open **Project → Export**, select **Android Test**, and resolve any missing-tool/template errors.
3. Click **Export Project**, keep **Export With Debug** checked, and save `pc-builder-debug.apk` in the project folder. **Export PCK/ZIP** creates only data, not an installable app. [Godot project exports](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html#export-menu)
4. Use a standalone export, without remote debugging or a remote file server. Those export flags can add `INTERNET` even when the preset checkbox is off. [Godot Android export flags](https://github.com/godotengine/godot/blob/4.7-stable/platform/android/export/export_plugin.cpp#L3414)

The equivalent PowerShell commands, after setup, are:

```powershell
$pcbuilderGodot = 'C:\path\to\Godot_v4.7.2-stable_win64_console.exe'
& $pcbuilderGodot --headless --editor --path . --import
& $pcbuilderGodot --headless --path . --export-debug 'Android Test' 'pc-builder-debug.apk'
```

Both commands must finish successfully. An existing APK left from an earlier export is not evidence that a failed export worked. The APK is ignored by Git.

Before installation, inspect the generated file using the SDK tools:

```powershell
$pcbuilderApk = Join-Path (Get-Location) 'pc-builder-debug.apk'
$pcbuilderAnalyzer = Join-Path $pcbuilderSdk 'cmdline-tools\latest\bin\apkanalyzer.bat'
& $pcbuilderAnalyzer manifest application-id $pcbuilderApk
& $pcbuilderAnalyzer manifest min-sdk $pcbuilderApk
& $pcbuilderAnalyzer manifest target-sdk $pcbuilderApk
& $pcbuilderAnalyzer manifest permissions $pcbuilderApk
& (Join-Path $pcbuilderSdk 'build-tools\35.0.1\apksigner.bat') verify --verbose $pcbuilderApk
```

The application ID must be `org.example.pcbuilder`; the signature check must pass. Record the SDK levels reported from the actual APK. The permission list must not include Internet, billing, or external-storage access. App-private save files do not need external-storage permission. [APK Analyzer](https://developer.android.com/tools/apkanalyzer), [signature verification](https://developer.android.com/tools/apksigner), [Android app-specific storage](https://developer.android.com/training/data-storage/app-specific)

## 4. Install on a physical phone

Use an ARM phone whose Android version meets the APK's reported minimum SDK. Godot's Compatibility renderer requires OpenGL ES 3.0; the documented simple-project Android baseline is Android 7.0. [Godot exported-project requirements](https://docs.godotengine.org/en/4.7/about/system_requirements.html#exported-godot-project)

Enable **Developer options → USB debugging**, connect a data-capable USB cable, unlock the phone, and accept its USB-debugging authorization prompt. On Windows, an OEM USB driver may be needed. [Android hardware-device setup](https://developer.android.com/studio/run/device)

```powershell
$pcbuilderAdb = Join-Path $pcbuilderSdk 'platform-tools\adb.exe'
& $pcbuilderAdb devices -l
```

Find the intended phone's serial and confirm its status is `device`, not `unauthorized` or `offline`. Use that serial explicitly so commands target the correct phone:

```powershell
$pcbuilderDevice = 'REPLACE_WITH_PHONE_SERIAL'
& $pcbuilderAdb -s $pcbuilderDevice install -r $pcbuilderApk
```

Wait for `Success`, then open **PC Builder** from the phone's launcher. `install -r` replaces an existing compatible installation while keeping its data. If installation reports an incompatible signature, recover the original signing key rather than uninstalling progress you want to retain. [Android Debug Bridge](https://developer.android.com/tools/adb)

## 5. Check touch, layout, and the full game flow

Use a fresh test installation for the expected totals below. If this phone already has progress, record that starting state and adjust reward expectations; do not clear its storage just to match this checklist.

- Confirm portrait orientation, readable text, and no horizontal clipping. Check the header counters, customer budget, and every footer button with both gesture navigation and three-button navigation if available. On a notch/punch-hole phone, no essential text or controls should sit beneath the cutout or system bars.
- Tap **Start building → Accept request**. Locked jobs and parts should show their level and remain unselectable. The first profile has level 1, 0 coins, 0 XP, and 50 gems.
- In the shop, tap a part and confirm its **SELECTED** badge and basket. Tap it again to deselect. Select a different option in that category and confirm replacement. Drag vertically from both blank space and a part card; scrolling should not accidentally choose a card. The footer and basket should stay visible while browsing.
- Build Mika's PC using the first row below. The review should show **38,000 coins** and **139 W**, including the **30 W** case/cooling allowance. Tap **Build PC** and confirm **SUCCESS** with readable checks.
- Open the reward. The first completion should give 5,000 coins, 100 XP, and 1 gem, reaching level 2 and 51 gems. Repeatedly tapping the reward/navigation button must not duplicate that attempt's payout.
- Tap **Next customer** and complete the remaining rows. Check each customer's name, request, budget, requirements, success result, and reward. After all five first completions, expect **69,000 coins, 1,500 XP, level 6, and 55 gems**. A replay gives its normal coins/XP but no second first-completion gem.

| Customer | CPU | Motherboard | RAM | SSD | PSU |
| --- | --- | --- | --- | --- | --- |
| Mika | StudyChip S4 | StudyBoard A | StudyRAM 8 GB | StudySSD 256 GB | StudyPower 180 W |
| Riku | StudyChip P6 | StudyBoard B | StudyRAM 16 GB | StudySSD 512 GB | StudyPower 350 W |
| Hana | PlayChip G8 | StudyBoard B | StudyRAM 16 GB | StudySSD 512 GB | StudyPower 350 W |
| Nao | CreateChip C12 | StudyBoard B Plus | CreateRAM 32 GB | CreateSSD 1 TB NVMe | CreatePower 550 W |
| Daichi | WorkChip W16 | WorkBoard B Pro | WorkRAM 64 GB | WorkSSD 2 TB NVMe | WorkPower 750 W |

Also replay Mika and deliberately pair StudyBoard A with StudyRAM 16 GB (DDR5). Build to see **FAILURE** with a RAM-generation explanation and no reward. Return to the shop, choose StudyRAM 8 GB, and return to review; it must show the updated part. Repeat with a missing slot and check the clear failure reason.

Put the phone in airplane mode and reopen the game; the full flow should remain usable without permission prompts or network access. Press Home, return to the app, and lock/unlock the phone during the shop and result screens. Confirm rendering, scrolling, buttons, and selections remain usable after resuming. Use the game's own back/menu buttons for screen navigation and record the system Back button's behavior separately.

Android versions can enforce edge-to-edge behavior depending on the app's target SDK. Check system-bar/cutout behavior on the actual exported APK, especially Android 15/16; a Windows portrait window cannot establish those results. [Android 16 edge-to-edge behavior](https://developer.android.com/about/versions/16/behavior-changes-16#edge-to-edge)

## 6. Verify saved progress across restart and update

The save API audit required no changes to `SaveData` or `GameState`. `FileAccess` reads and writes `user://pc_builder_save.json`; `ProjectSettings.globalize_path()` converts its paths before the supported `DirAccess.copy_absolute()` and `rename_absolute()` calls. Godot's exported-project warning concerns globalizing `res://`, not this `user://` save. This confirms the API choice; the device checks below still verify Android file behavior and persistence. [Godot 4.7 `globalize_path()`](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html#class-projectsettings-method-globalize-path)

1. After collecting a reward, record coins, XP, level, gems, and completed customers. Confirm the reward screen reports successful saving.
2. Force-stop this test app, then launch **PC Builder** again from the phone's launcher:

   ```powershell
   & $pcbuilderAdb -s $pcbuilderDevice shell am force-stop org.example.pcbuilder
   ```

3. Confirm the recorded progress remains, and the menu offers the next available incomplete customer. Part selections and an unclaimed result intentionally reset after a full restart; they are not saved.
4. Re-export with the **same package ID and signing key**. For a numbered update, increase the preset's version code. Install using the same `install -r` command and reopen the app. Confirm the recorded progress still remains.
5. An ordinary uninstall or **Settings → Apps → PC Builder → Storage → Clear storage** deletes the app's local progress. Only test that reset on progress you deliberately intend to discard. This preset disables Android backup; keep it off for this local test. Do not use uninstall/reinstall as an update procedure. [Android local-file lifetime](https://developer.android.com/training/data-storage/app-specific)

If launch or rendering fails, collect the existing device log without clearing it:

```powershell
& $pcbuilderAdb -s $pcbuilderDevice logcat -d -s Godot AndroidRuntime
```

The force-stop and log commands are documented Android shell/debugging operations; they are instructions for the device tester and were not executed during the repository audit. [ADB shell commands](https://developer.android.com/tools/adb#shellcommands)

## Record the physical-device result

Fill this in after testing. Leave unperformed checks as **Not tested**.

| Field | Result |
| --- | --- |
| Test date / tester | |
| Phone model / Android version / CPU ABI | |
| APK version / package ID / min SDK / target SDK | |
| Screen resolution / cutout / navigation mode | |
| APK export, signature, and permission inspection | Not tested |
| First install / portrait and system-bar layout | Not tested |
| Tap, deselection, replacement, and drag scrolling | Not tested |
| Five customer successes and rewards | Not tested |
| Failure reasons and return-to-shop refresh | Not tested |
| Airplane mode / background and resume | Not tested |
| Force-stop and relaunch preserve progress | Not tested |
| Same-package, same-key update preserves progress | Not tested |
| Relevant log output / screenshots / defects | |
