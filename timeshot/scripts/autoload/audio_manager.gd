extends Node
## Centralized audio playback.
##
## Day 18 update: adds a `play(name)` named-SFX API. Sounds are synthesized at
## startup as short procedural blips so the prototype is audible without
## requiring asset files. Replace `_synthesize_*` with `preload(...)` of real
## .wav / .ogg files when the sound pack lands.

const SAMPLE_RATE := 22050

@onready var _sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var _sfx_player_alt: AudioStreamPlayer = AudioStreamPlayer.new()   # alternates to avoid cutting itself off
@onready var _music_player: AudioStreamPlayer = AudioStreamPlayer.new()

var _next_player_is_alt: bool = false
var _named_sfx: Dictionary = {}


func _ready() -> void:
	add_child(_sfx_player)
	add_child(_sfx_player_alt)
	add_child(_music_player)
	_sfx_player.bus = "Master"
	_sfx_player_alt.bus = "Master"
	_music_player.bus = "Master"
	_build_named_library()


# ---------- Public API ----------

func play(name: String, volume_db: float = -8.0) -> void:
	var stream := _named_sfx.get(name, null) as AudioStream
	if stream == null:
		return
	var p := _sfx_player_alt if _next_player_is_alt else _sfx_player
	_next_player_is_alt = not _next_player_is_alt
	p.stream = stream
	p.volume_db = volume_db
	p.play()


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


# ---------- Named library ----------

func _build_named_library() -> void:
	_named_sfx["shoot"] = _synthesize(0.06, 880.0, 220.0, 0.18, "square")
	_named_sfx["enemy_shoot"] = _synthesize(0.08, 520.0, 140.0, 0.20, "square")
	_named_sfx["hit"] = _synthesize(0.07, 220.0, 60.0, 0.30, "noise")
	_named_sfx["enemy_death"] = _synthesize(0.18, 400.0, 80.0, 0.35, "noise")
	_named_sfx["player_hurt"] = _synthesize(0.18, 180.0, 60.0, 0.40, "square")
	_named_sfx["pickup"] = _synthesize(0.07, 1200.0, 1800.0, 0.22, "square")
	_named_sfx["door"] = _synthesize(0.12, 320.0, 480.0, 0.25, "triangle")
	_named_sfx["portal"] = _synthesize(0.22, 660.0, 1200.0, 0.20, "triangle")
	_named_sfx["menu"] = _synthesize(0.05, 900.0, 900.0, 0.18, "square")
	_named_sfx["upgrade"] = _synthesize(0.18, 660.0, 1320.0, 0.25, "triangle")


# Cheap WAV synthesizer. duration in seconds; freq_start/end Hz (linear glide);
# amplitude in 0..1; wave in {"square","triangle","noise"}.
func _synthesize(duration: float, freq_start: float, freq_end: float, amplitude: float, wave: String) -> AudioStreamWAV:
	var n := int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in n:
		var t := float(i) / float(n)
		var freq: float = lerpf(freq_start, freq_end, t)
		# Envelope: quick attack, exponential decay.
		var env: float = 1.0
		if t < 0.03:
			env = t / 0.03
		else:
			env = pow(1.0 - t, 1.2)
		phase += (freq * TAU) / float(SAMPLE_RATE)
		var sample: float = 0.0
		match wave:
			"square":
				sample = 1.0 if sin(phase) >= 0.0 else -1.0
			"triangle":
				sample = (2.0 / PI) * asin(sin(phase))
			"noise":
				sample = rng.randf_range(-1.0, 1.0)
			_:
				sample = sin(phase)
		var s_int := clampi(int(sample * env * amplitude * 32760.0), -32768, 32767)
		bytes[i * 2] = s_int & 0xFF
		bytes[i * 2 + 1] = (s_int >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
