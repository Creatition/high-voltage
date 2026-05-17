extends Node2D
class_name WaveSpawner
## Spawns sequences of enemies at child Marker2D positions.
##
## Each entry in `waves` is a Dictionary:
##   { "delay": float, "spawns": [ {"scene": PackedScene, "marker": StringName} , ... ] }
##
## Marker names match child Marker2D node names. If a wave's marker name is
## empty, a random Marker2D child is chosen.
##
## The spawner notifies its owning Room when all waves have finished so the
## room only reports "cleared" once every wave has actually spawned + died.

@export var waves: Array = []
@export var auto_start: bool = false   # rooms call spawn_all explicitly

var _room: Node = null


func set_owner_room(room: Node) -> void:
	_room = room


func _ready() -> void:
	if auto_start and _room == null:
		# Standalone use (e.g. test scene without a Room parent).
		call_deferred("spawn_all", get_parent())


func spawn_all(room: Node) -> void:
	_room = room
	for wave in waves:
		var delay: float = wave.get("delay", 0.0)
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
		_spawn_wave(wave.get("spawns", []))
	if _room != null and _room.has_method("notify_wave_done"):
		_room.notify_wave_done()


func _spawn_wave(spawns: Array) -> void:
	for entry in spawns:
		var scene: PackedScene = entry.get("scene")
		if scene == null:
			continue
		var marker := _pick_marker(entry.get("marker", ""))
		var inst := scene.instantiate()
		if _room != null:
			_room.add_child(inst)
		else:
			get_tree().current_scene.add_child(inst)
		if marker != null:
			inst.global_position = marker.global_position
		if _room != null and _room.has_method("track_enemy"):
			_room.track_enemy(inst)


func _pick_marker(name_hint: String) -> Marker2D:
	var markers: Array = []
	for c in get_children():
		if c is Marker2D:
			markers.append(c)
	if markers.is_empty():
		return null
	if name_hint != "":
		for m in markers:
			if m.name == name_hint:
				return m
	return markers[randi() % markers.size()]
