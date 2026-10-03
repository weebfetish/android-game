# PC Builder prototype

A simple 2D educational PC-building simulator for Godot 4.x, written in GDScript. The project uses placeholder panels, text, and buttons. No external assets, plugins, or services are required.

## Run the game

1. Open Godot 4.x and import this folder's `project.godot`.
2. Open the project and press **F5** (Run Project).
3. Click **Start building**, read Mika's request, and accept it.
4. In the shop, select one CPU, motherboard, RAM kit, SSD, and PSU. Click a selected option again to deselect it.
5. Continue to the build screen, review your selection, and click **Build PC**.
6. Read **SUCCESS** or **FAILURE** and the check explanations. Fix failed builds in the shop.
7. After a successful build, continue to the reward screen to receive **5,000 coins and 100 XP**.

Use the mouse wheel or scrollbar to read longer screens. The action buttons stay visible in a footer while the page scrolls.

The UI adapts to desktop and portrait windows, including **360 × 800** and **440 × 900**. Part choices appear in two columns on desktop and one column on a phone-sized window. Selected cards show a **SELECTED** badge. Coins and XP stay visible in the shared header, and the shop basket stays visible while browsing parts. Resizing keeps the current screen and selections.

Use **F5** for the complete flow. **F6** runs only the currently open scene, so an individual screen may not have the navigation or selections provided by the main scene.

The customer budget is **60,000 coins**. It is separate from the player's earned coins: selecting parts does not spend rewards. Coins and XP accumulate during the current game session; closing the game resets them. Returning to the menu lets you replay the first customer.

## Starter parts

| Category | Part | Price | Compatibility / specification |
| --- | --- | ---: | --- |
| CPU | StudyChip S4 | 12,000 | STUDY-A socket, 65 W |
| CPU | StudyChip P6 | 20,000 | STUDY-B socket, 125 W |
| Motherboard | StudyBoard A | 10,000 | STUDY-A, DDR4, SATA, 35 W |
| Motherboard | StudyBoard B | 16,000 | STUDY-B, DDR5, SATA, 40 W |
| RAM | StudyRAM 8 GB | 5,000 | DDR4, 5 W |
| RAM | StudyRAM 16 GB | 9,000 | DDR5, 8 W |
| SSD | StudySSD 256 GB | 5,000 | SATA, 4 W |
| SSD | StudySSD 512 GB | 8,000 | SATA, 5 W |
| PSU | StudyPower 180 W | 6,000 | Supplies up to 180 W |
| PSU | StudyPower 350 W | 10,000 | Supplies up to 350 W |

These are fictional learning parts. The fixed case and cooling add **30 W** to the build's power requirement.

A working first build is **StudyChip S4 + StudyBoard A + StudyRAM 8 GB + StudySSD 256 GB + StudyPower 180 W**. It costs **38,000 coins** and needs **139 W**. The CPU socket and RAM generation must match the motherboard; the SSD interface must be supported; the PSU must meet the total power requirement; and the total price must stay at or below the customer's budget.

## Project layout

- `scenes/main.tscn` starts the game and hosts the current screen.
- `scenes/screens/` contains the six screens: main menu, customer request, parts shop, PC build, result, and reward.
- `scripts/screens/` builds each screen's placeholder UI and handles its buttons.
- `scripts/main.gd` swaps screens when they request navigation.
- `scripts/ui/screen_ui.gd`, `scripts/ui/part_choice_card.gd`, and `theme/default_theme.tres` share the responsive layout, part cards, and styling.
- `scripts/ui/player_hud.gd` shows current coins and XP and updates when the game state changes.
- `scripts/data/part_data.gd` defines the fields on a part.
- `scripts/data/parts_catalog.gd` defines the ten shop options. Edit this file to change names, prices, or specifications.
- `scripts/build_validator.gd` checks a selected build and returns explanations without changing it.
- `scripts/game_state.gd` is the `GameState` autoload. It holds the customer, selections, result, coins, and XP, and prevents duplicate or stale reward claims.
- `tests/run_tests.gd` checks the rules, reward handling, and complete button flow.

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

The suite exits with code `0` when all checks pass and code `1` if a check fails. It covers compatible and incompatible builds, missing or misplaced parts, budget and PSU boundaries, reward safeguards, and navigation through success and failure screens. UI checks also cover both portrait sizes, visible footer buttons, horizontal overflow, selection badges, wallet updates, and resizing the shop without losing selections.
