# Optional presentation audio

The `AudioManager` autoload plays UI audio without reading or changing player progress.
The game runs silently when any or all of these files are missing. No audio files are
bundled with this polish pass.

| Purpose | Expected file |
| --- | --- |
| Background music | `assets/audio/music/workshop_theme.ogg` |
| Button click | `assets/audio/sfx/ui_click.wav` |
| Part selected or deselected | `assets/audio/sfx/part_select.wav` |
| Successful build | `assets/audio/sfx/success.wav` |
| Failed build | `assets/audio/sfx/failure.wav` |
| Reward presentation | `assets/audio/sfx/reward.wav` |

Add licensed audio at these exact paths, open the project in Godot, and let the editor
import it before exporting. Use a modest-size Ogg music track and short WAV effects
to keep loading and memory use small. Enable **Loop** in the music import settings
for a seamless loop; the manager also replays the music when it finishes. The existing
Android export preset includes imported audio resources automatically.

The manager starts music once at launch and retains it across screens. Its public
methods are `play_music()`, `stop_music()`, `play_ui_click()`, `play_part_select()`,
`play_success()`, `play_failure()`, and `play_reward()`. Music uses one non-positional
`AudioStreamPlayer`; effects share three reusable players. Streams and missing-file
checks are cached for the session. Restart after adding a previously missing file.
Music is quieter than effects (`-18 dB` and `-8 dB` respectively).

On Android/iOS application pause, music pauses and active effects stop. Music resumes
when the app returns. Audio playback does not hold up navigation or reward collection.
See [Godot 4.7 AudioStreamPlayer](https://docs.godotengine.org/en/4.7/classes/class_audiostreamplayer.html)
and [application pause notifications](https://docs.godotengine.org/en/4.7/classes/class_node.html#class-node-constant-notification-application-paused).

Optional haptics are omitted. Godot 4.7's `Input.vibrate_handheld()` requires Android's
`VIBRATE` export permission, so this pass leaves the existing permissions unchanged.
See [Godot 4.7 vibration requirements](https://docs.godotengine.org/en/4.7/classes/class_input.html#class-input-method-vibrate-handheld).
