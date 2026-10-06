extends Node
## Optional presentation audio. Missing files are silent, and this never changes game data.

const MUSIC_PATH: String = "res://assets/audio/music/workshop_theme.ogg"
const UI_CLICK_PATH: String = "res://assets/audio/sfx/ui_click.wav"
const PART_SELECT_PATH: String = "res://assets/audio/sfx/part_select.wav"
const SUCCESS_PATH: String = "res://assets/audio/sfx/success.wav"
const FAILURE_PATH: String = "res://assets/audio/sfx/failure.wav"
const REWARD_PATH: String = "res://assets/audio/sfx/reward.wav"
const SFX_VOICE_COUNT: int = 3

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _stream_cache: Dictionary = {}
var _next_sfx_voice: int = 0
var _music_requested: bool = false
var _backgrounded: bool = false


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.volume_db = -18.0
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)
	for index in range(SFX_VOICE_COUNT):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % (index + 1)
		player.volume_db = -8.0
		add_child(player)
		_sfx_players.append(player)
	play_music()


func play_music() -> void:
	_music_requested = true
	var stream := _load_optional_stream(MUSIC_PATH)
	if stream == null or _music_player == null:
		return
	if _music_player.stream != stream:
		_music_player.stream = stream
	if not _backgrounded and not _music_player.playing:
		_music_player.play()


func stop_music() -> void:
	_music_requested = false
	if _music_player != null:
		_music_player.stop()


func play_ui_click() -> void:
	_play_sfx(UI_CLICK_PATH)


func play_part_select() -> void:
	_play_sfx(PART_SELECT_PATH)


func play_success() -> void:
	_play_sfx(SUCCESS_PATH)


func play_failure() -> void:
	_play_sfx(FAILURE_PATH)


func play_reward() -> void:
	_play_sfx(REWARD_PATH)


func _load_optional_stream(path: String) -> AudioStream:
	# Cache missing files too: taps should not repeatedly check the filesystem.
	if not _stream_cache.has(path):
		_stream_cache[path] = null
		if ResourceLoader.exists(path):
			_stream_cache[path] = ResourceLoader.load(path) as AudioStream
	return _stream_cache[path] as AudioStream


func _play_sfx(path: String) -> void:
	if _backgrounded or _sfx_players.is_empty():
		return
	var stream := _load_optional_stream(path)
	if stream == null:
		return
	# Reuse a fixed small pool, even when a player taps rapidly.
	var player := _sfx_players[_next_sfx_voice]
	_next_sfx_voice = (_next_sfx_voice + 1) % SFX_VOICE_COUNT
	player.stream = stream
	player.play()


func _on_music_finished() -> void:
	# Also works if the Ogg import's Loop option has not been enabled.
	if _music_requested and not _backgrounded:
		_music_player.play()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_backgrounded = true
		if _music_player != null:
			_music_player.stream_paused = true
		for player in _sfx_players:
			player.stop()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_backgrounded = false
		if _music_player != null:
			_music_player.stream_paused = false
		if _music_requested:
			play_music()
