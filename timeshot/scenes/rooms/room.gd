extends Node2D
class_name Room
## Base script for a single combat room. Tracks remaining enemies and
## unlocks doors + spawns a reward shrine when cleared.
##
## Convention:
##   - Doors and WaveSpawners are detected by duck-typed method probes
##     (set_locked / spawn_all). They can live anywhere in the room tree.
##   - WaveSpawner instances register themselves with the room on _ready
##     so the room never reports "cleared" while waves are still pending.

@export var room_id: String = ""
@export var era: String = "present"
## Flip to true on the final room of an era so clearing it marks the era as
## completed in GameState (drives the era picker's "remaining" count).
@export var is_boss_room: bool = false
@export var clear_to_unlock_doors: bool = true
@export var spawn_reward_on_clear: bool = true
@export var reward_position: Vector2 = Vector2(640, 360)

signal room_cleared

const REWARD_SHRINE_SCENE := preload("res://scenes/rooms/reward_shrine.tscn")

var _tracked_enemies: Array = []
var _is_cleared: bool = false
var _pending_waves: int = 0
var _spawners_started: bool = false


func _ready() -> void:
	if clear_to_unlock_doors:
		for d in _find_all_doors():
			d.set_locked(true)
	# Trigger wave spawners on the next frame so they finish _ready first.
	call_deferred("_start_spawners")
	call_deferred("_initial_track")


func _start_spawners() -> void:
	if _spawners_started:
		return
	_spawners_started = true
	for s in _find_all_spawners():
		# Tell the spawner we're its owning room so it can hand back enemies
		# and bump the pending-waves counter.
		if s.has_method("set_owner_room"):
			s.set_owner_room(self)
		_pending_waves += 1
		s.spawn_all(self)


func _initial_track() -> void:
	await get_tree().process_frame
	for n in get_tree().get_nodes_in_group("enemies"):
		if _is_descendant(n, self):
			track_enemy(n)
	# A genuinely empty room (no enemies, no spawners) is cleared immediately.
	_check_clear()


func notify_wave_done() -> void:
	_pending_waves = maxi(0, _pending_waves - 1)
	_check_clear()


func track_enemy(enemy: Node) -> void:
	if enemy in _tracked_enemies:
		return
	_tracked_enemies.append(enemy)
	if enemy.has_node("HealthComponent"):
		var health := enemy.get_node("HealthComponent") as HealthComponent
		if health != null:
			health.died.connect(_on_tracked_enemy_died.bind(enemy))
	enemy.tree_exited.connect(_on_tracked_enemy_exited.bind(enemy))


func _on_tracked_enemy_died(enemy: Node) -> void:
	_tracked_enemies.erase(enemy)
	_check_clear()


func _on_tracked_enemy_exited(enemy: Node) -> void:
	_tracked_enemies.erase(enemy)
	_check_clear()


func _check_clear() -> void:
	if _is_cleared:
		return
	if _pending_waves > 0:
		return
	if _tracked_enemies.is_empty():
		_on_room_clear()


func _on_room_clear() -> void:
	_is_cleared = true
	for d in _find_all_doors():
		d.set_locked(false)
	if spawn_reward_on_clear:
		var shrine := REWARD_SHRINE_SCENE.instantiate()
		shrine.era = era
		add_child(shrine)
		shrine.position = reward_position
	if is_boss_room and GameState.has_method("mark_era_complete"):
		GameState.mark_era_complete(era)
	room_cleared.emit()


func _find_all_doors() -> Array:
	var out: Array = []
	_collect_by_class(self, "Door", out)
	return out


func _find_all_spawners() -> Array:
	var out: Array = []
	_collect_by_class(self, "WaveSpawner", out)
	return out


func _collect_by_class(node: Node, class_name_str: String, out: Array) -> void:
	# Duck-typed match — we look for a method that uniquely identifies the type.
	for c in node.get_children():
		if class_name_str == "Door" and c.has_method("set_locked") and c.has_method("is_locked"):
			out.append(c)
		elif class_name_str == "WaveSpawner" and c.has_method("spawn_all"):
			out.append(c)
		if c.get_child_count() > 0:
			_collect_by_class(c, class_name_str, out)


func _is_descendant(node: Node, ancestor: Node) -> bool:
	var p := node.get_parent()
	while p != null:
		if p == ancestor:
			return true
		p = p.get_parent()
	return false
