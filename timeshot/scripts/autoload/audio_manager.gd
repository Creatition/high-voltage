extends Node
## Centralized audio playback. Stub for the prototype.
## Will manage music buses, SFX pooling, and ducking later.

@onready var _sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var _music_player: AudioStreamPlayer = AudioStreamPlayer.new()


func _ready() -> void:
	add_child(_sfx_player)
	add_child(_music_player)
	_sfx_player.bus = "Master"
	_music_player.bus = "Master"


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.volume_db = volume_db
	_sfx_player.play()


func play_music(stream: AudioStream, volume_db: float = -6.0) -> void:
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()
