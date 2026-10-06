# PC Builder prototype

A simple 2D educational PC-building simulator for Godot 4.x, written in GDScript. Complete five customer jobs, earn coins and XP, and unlock parts as you level up. Progress saves locally on this device. The responsive UI uses the supplied workshop background, Mika portrait, and component icons alongside simple panels, text, and buttons. No plugins or external services are required.

## Run the game

1. Open Godot 4.x and import this folder's `project.godot`.
2. Open the project and press **F5** (Run Project).
3. Click **Start building** to start the next available customer, or choose an unlocked customer on the job board.
4. In the shop, select one CPU, motherboard, RAM kit, SSD, and PSU. Click a selected option again to deselect it.
5. Continue to the build screen, review your selection, and click **Build PC**.
6. Read **SUCCESS** or **FAILURE** and the check explanations. Fix failed builds in the shop.
7. After a successful build, collect the job's reward. Mika's first study job gives **5,000 coins, 100 XP, and 1 gem**.
8. Click **Next customer** to continue, or return to the job board to replay an unlocked job.

Use the mouse wheel or scrollbar to read longer screens. The action buttons stay visible in a footer while the page scrolls.

The UI adapts to desktop and portrait windows, including **360 × 800** and **440 × 900**. Part choices appear in two columns on desktop and one column on a phone-sized window. Selected cards show a **SELECTED** badge; locked cards show their required level. Coins, XP, gems, and level stay visible in the shared header, and the shop basket stays visible while browsing parts. Resizing keeps the current screen and selections.

Use **F5** for the complete flow. **F6** runs only the currently open scene, so an individual screen may not have the navigation or selections provided by the main scene.

Customer budgets are separate from the player's earned coins: selecting parts does not spend rewards. Mika's first budget is **60,000 coins**. Later customers allow larger budgets and require stronger CPUs, more RAM, larger SSDs, or NVMe storage.

## Customers and progression

You begin at **level 1, 0 XP, 0 coins, and 50 free gems**. Each successful attempt pays coins and XP once. The first completion of each customer also gives **1 gem**; replaying that customer gives coins and XP again without another first-completion gem.

| Level | Customer | Job | Budget | Minimum CPU score / RAM / SSD | Reward coins / XP |
| ---: | --- | --- | ---: | --- | ---: |
| 1 | Mika | Basic study PC | 60,000 | 1 / 8 GB / 256 GB | 5,000 / 100 |
| 2 | Riku | Budget gaming PC | 85,000 | 2 / 16 GB / 512 GB | 8,000 / 200 |
| 3 | Hana | Esports PC | 115,000 | 3 / 16 GB / 512 GB | 12,000 / 300 |
| 4 | Nao | Content creator PC | 155,000 | 4 / 32 GB / 1 TB NVMe | 18,000 / 400 |
| 5 | Daichi | High-end workstation | 210,000 | 5 / 64 GB / 2 TB NVMe | 26,000 / 500 |

Level thresholds are **0, 100, 300, 600, 1,000, and 1,500 total XP** for levels 1–6. The general threshold for level `n` is `50 * n * (n - 1)`, so levels continue beyond 6. Completing each customer once reaches level 6 with **69,000 coins, 1,500 XP, and 55 gems**. CPU scores are fictional game ratings used to teach matching parts to a customer's needs.

## Local saving

Successful reward collection writes `user://pc_builder_save.json` in Godot's local user-data directory. It stores a version number, coins, XP, level, gems, and completed customer IDs. Restarting loads these values and offers the next available incomplete job. XP determines the loaded level; an inconsistent saved level does not override it.

Part selections and an unclaimed build result are temporary and are not saved. Replacement writes use a `.tmp` file and retain the previous valid JSON as `pc_builder_save.json.bak`. If the main save is missing or corrupt, loading recovers that backup. When neither file is valid, the current progress stays unchanged; a new installation starts with a fresh profile. Save failures are reported on the menu and reward screen. Tests use their own temporary save path and clean its JSON, temporary file, and backup without writing to the player's normal save.

## Parts catalog

Each category has five options. The original two options are available at level 1; the additional parts unlock at the levels below.

| Category | Part | Level | Price | Compatibility / specification |
| --- | --- | ---: | ---: | --- |
| CPU | StudyChip S4 | 1 | 12,000 | STUDY-A, score 1, 65 W |
| CPU | StudyChip P6 | 1 | 20,000 | STUDY-B, score 2, 125 W |
| CPU | PlayChip G8 | 3 | 32,000 | STUDY-B, score 3, 150 W |
| CPU | CreateChip C12 | 4 | 45,000 | STUDY-B, score 4, 180 W |
| CPU | WorkChip W16 | 5 | 65,000 | STUDY-B, score 5, 240 W |
| Motherboard | StudyBoard A | 1 | 10,000 | STUDY-A, DDR4, SATA, 35 W |
| Motherboard | StudyBoard B | 1 | 16,000 | STUDY-B, DDR5, SATA, 40 W |
| Motherboard | StudyBoard A Plus | 2 | 14,000 | STUDY-A, DDR4, SATA/NVMe, 40 W |
| Motherboard | StudyBoard B Plus | 2 | 22,000 | STUDY-B, DDR5, SATA/NVMe, 45 W |
| Motherboard | WorkBoard B Pro | 4 | 30,000 | STUDY-B, DDR5, SATA/NVMe, 55 W |
| RAM | StudyRAM 8 GB | 1 | 5,000 | DDR4, 5 W |
| RAM | StudyRAM 16 GB | 1 | 9,000 | DDR5, 8 W |
| RAM | StudyRAM 16 GB DDR4 | 2 | 8,000 | DDR4, 8 W |
| RAM | CreateRAM 32 GB | 4 | 15,000 | DDR5, 12 W |
| RAM | WorkRAM 64 GB | 5 | 26,000 | DDR5, 18 W |
| SSD | StudySSD 256 GB | 1 | 5,000 | SATA, 4 W |
| SSD | StudySSD 512 GB | 1 | 8,000 | SATA, 5 W |
| SSD | PlaySSD 512 GB NVMe | 2 | 11,000 | NVMe, 6 W |
| SSD | CreateSSD 1 TB NVMe | 4 | 18,000 | NVMe, 7 W |
| SSD | WorkSSD 2 TB NVMe | 5 | 32,000 | NVMe, 10 W |
| PSU | StudyPower 180 W | 1 | 6,000 | Supplies up to 180 W |
| PSU | StudyPower 350 W | 1 | 10,000 | Supplies up to 350 W |
| PSU | PlayPower 450 W | 2 | 12,000 | Supplies up to 450 W |
| PSU | CreatePower 550 W | 3 | 15,000 | Supplies up to 550 W |
| PSU | WorkPower 750 W | 5 | 22,000 | Supplies up to 750 W |

These are fictional learning parts. The fixed case and cooling add **30 W** to the build's power requirement.

A working first build is **StudyChip S4 + StudyBoard A + StudyRAM 8 GB + StudySSD 256 GB + StudyPower 180 W**. It costs **38,000 coins** and needs **139 W**. The CPU socket and RAM generation must match the motherboard; the SSD interface must be supported; the PSU must meet the total power requirement; and the total price must stay at or below the customer's budget. Customer minimum specifications are checked alongside these compatibility rules.

## Project layout

- `scenes/main.tscn` starts the game and hosts the current screen.
- `scenes/screens/` contains the six screens: main menu, customer request, parts shop, PC build, result, and reward.
- `scripts/screens/` builds each screen's UI and handles its buttons.
- `scripts/main.gd` swaps screens when they request navigation.
- `scripts/ui/screen_ui.gd`, `scripts/ui/part_choice_card.gd`, and `theme/default_theme.tres` share the responsive layout, part cards, and styling.
- `scripts/ui/player_hud.gd` shows coins, XP, gems, and level and updates when the game state changes.
- `scripts/ui/art_assets.gd` shares cached textures and creates image controls that preserve aspect ratio.
- `scripts/ui/ui_motion.gd` contains the short entrance fades, portrait slide, and selection pop.
- `scripts/ui/button_feedback.gd` adds short button tint feedback while preserving native touch targets.
- `scripts/audio_manager.gd` is the optional `AudioManager` autoload for music and UI sound effects.
- `scripts/data/part_data.gd` defines the fields on a part.
- `scripts/data/parts_catalog.gd` defines the twenty-five shop options and their unlock levels. Edit this file to change names, prices, or specifications.
- `scripts/data/job_data.gd` and `scripts/data/jobs_catalog.gd` define the five customers, requirements, unlock levels, and rewards.
- `scripts/build_validator.gd` checks a selected build and returns explanations without changing it.
- `scripts/game_state.gd` is the `GameState` autoload. It holds the current job, selections, result, currencies, XP, and level, and prevents duplicate or stale reward claims.
- `scripts/save_data.gd` validates local JSON and uses a temporary file plus a previous valid backup for recoverable replacement.
- `tests/run_tests.gd` checks the rules, reward handling, complete button flow, and responsive UI; `tests/progression_tests.gd` adds level, unlock, save, and five-customer flow checks.

## Art and UI motion

The supplied images use these normalized paths:

- `assets/backgrounds/workshop_room.png` appears behind the menu and customer request, with a dark overlay for readable text.
- `assets/characters/mika.png` appears beside Mika's customer details.
- `assets/icons/cpu.png`, `motherboard.png`, `ram.png`, `ssd.png`, and `psu.png` provide the shop's category icons. All five choices in a category reuse the same cached texture.

Godot limits imported icons to **256 pixels**, the portrait to **512 pixels**, and the background to **1,280 pixels** on the longest side. Source files remain in `assets/`; the bounded imported textures keep these decorations lightweight. Image controls preserve aspect ratio, and decorative art leaves mouse input available to the buttons.

Short, one-shot tweens mark each screen entrance with a 0.16-second fade. Mika's portrait keeps its small slide. Buttons briefly tint without scaling their touch targets; selected part icons pop and deselected icons settle gently. Success pulses the status text; failure gives that text a tiny wobble while the educational explanations stay still. Rapid selection changes cancel the earlier icon and badge tweens.

Newly collected rewards count their coin, XP, and gem labels up over 0.45 seconds. The reward is claimed and saved immediately before those visual counters start. Leaving during the count cannot cancel the reward, and reopening an already collected reward displays its final values immediately. The header always shows the actual current balances.

Optional audio expects `assets/audio/music/workshop_theme.ogg` and five WAV files in `assets/audio/sfx/`: `ui_click.wav`, `part_select.wav`, `success.wav`, `failure.wav`, and `reward.wav`. No sound files are bundled yet; missing files remain silent. One music player and three reusable effects players keep resource use bounded. See [audio setup and filenames](docs/audio.md). Haptics are omitted because Godot requires Android's vibration permission for them; export permissions remain unchanged.

## Android test APK

The checked-in **Android** export preset targets `pc-builder-debug.apk` and retains the configuration used for the working phone build. The project uses the Compatibility renderer, portrait orientation, and responsive UI scaling. Touch taps operate the existing buttons; use finger drags to scroll on a phone. Tests and documentation are excluded from the APK.

Touch events propagate through cards, panels, and buttons so dragging over them scrolls the page. The automated swipe probe simulates touchscreen availability on Windows and verifies that a swipe scrolls and cancels the part-card tap.

The prototype has been reported working on a real Android phone. This presentation pass was verified in rendered portrait windows on Windows; the updated APK still needs a phone smoke test after re-exporting with the existing preset. The earlier [Android device checklist](docs/android_device_test.md) contains installation and save persistence checks; its initial setup notes describe the configuration before the successful device test.

## Headless checks

Use your Godot executable in place of `godot` below. Run these commands from the project folder. The import step prepares Godot's resource and script-class cache on a fresh checkout.

```sh
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/run_tests.gd
```

For PowerShell with a Godot executable outside `PATH`:

```powershell
& 'C:\path\to\Godot_v4.x-stable_win64_console.exe' --headless --editor --path . --import
& 'C:\path\to\Godot_v4.x-stable_win64_console.exe' --headless --path . --script res://tests/run_tests.gd
```

The suite exits with code `0` when all checks pass and code `1` if a check fails. It covers compatible and incompatible builds, missing or misplaced parts, customer requirement boundaries, budget and PSU boundaries, reward safeguards, XP thresholds, and level locks. It also completes all five customer jobs through the actual buttons at desktop and both portrait sizes. UI checks cover visible footer buttons, horizontal overflow, selection badges, wallet updates, and resizing the shop without losing selections. Art checks cover asset imports, texture reuse, aspect ratio, portrait layout, decorative input handling, and animation settling after rapid selection changes. Save checks use an isolated temporary file to verify real reward autosaving and mid-progression resume, repeated writes and backup recovery, round-tripping, corrupt or invalid data, XP-derived levels, and first-completion gems after loading.

Android readiness checks additionally inject native touch events through Godot's input system to traverse all six screens, verify short swipes cancel button presses, and check phone touch targets and horizontal bounds. Swipe checks temporarily simulate touchscreen availability in the desktop test process. Separate writer and reader processes verify saved progression resumes from an isolated file.

Presentation checks cover immediate navigation, unchanged touch targets, rapid selection and deselection, animation settlement, readable failure reasons, intermediate reward counts, saved rewards when leaving during animation, repeated reward views, missing audio, the fixed sound-player pool, and background audio pause/resume. The Godot 4.7.2 suite passed **1,519 checks**; the rendered touch/save/presentation probe passed **404 checks** at **360 x 800** and **440 x 900**. Visual inspection covered all six screens at both sizes. These desktop checks do not certify an Android APK or phone lifecycle.
