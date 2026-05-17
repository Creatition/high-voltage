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
	# Day-28: confine the player's Camera2D to the room's wall bounds so the
	# viewport never reveals the empty void outside the room. Deferred so the
	# Player instance has had its _ready, and so any procgen wall placement
	# is already in the tree.
	call_deferred("_apply_camera_bounds")
	# Day-28: fade in from black on entry so room transitions feel like
	# crossing a doorway rather than a hard scene cut. Sells the "one
	# connected dungeon" feel even though the scenes are still separate.
	_play_entry_fade()


func _play_entry_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100   # above HUD
	add_child(layer)
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.anchor_right = 1.0
	fade.anchor_bottom = 1.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)
	var t := create_tween()
	t.tween_property(fade, "color:a", 0.0, 0.35)
	t.tween_callback(layer.queue_free)


func _apply_camera_bounds() -> void:
	## Walks the room tree looking for StaticBody2D children whose names start
	## with "Wall", aggregates their world-space AABB, then sets limit_* on the
	## player's Camera2D. Falls back to a 1280x720 default if no walls are
	## found (e.g. boss arenas that use a different convention).
	var bounds: Dictionary = {"min": Vector2.INF, "max": -Vector2.INF}
	_collect_wall_bounds_d(self, bounds)
	var min_pos: Vector2 = bounds["min"]
	var max_pos: Vector2 = bounds["max"]
	if min_pos.x == INF or max_pos.x == -INF:
		min_pos = Vector2(0, 0)
		max_pos = Vector2(1280, 720)
	var cam: Camera2D = _find_player_camera()
	if cam == null:
		return
	cam.limit_left = int(min_pos.x)
	cam.limit_top = int(min_pos.y)
	cam.limit_right = int(max_pos.x)
	cam.limit_bottom = int(max_pos.y)
	cam.reset_smoothing()


func _collect_wall_bounds_d(node: Node, bounds: Dictionary) -> void:
	for c in node.get_children():
		if c is StaticBody2D and String(c.name).begins_with("Wall"):
			var aabb := _node_world_aabb(c)
			if aabb.size != Vector2.ZERO:
				bounds["min"] = bounds["min"].min(aabb.position)
				bounds["max"] = bounds["max"].max(aabb.position + aabb.size)
		if c.get_child_count() > 0:
			_collect_wall_bounds_d(c, bounds)


func _node_world_aabb(node: Node) -> Rect2:
	var origin: Vector2 = Vector2.ZERO
	if node is Node2D:
		origin = (node as Node2D).global_position
	var min_p := Vector2.INF
	var max_p := -Vector2.INF
	for c in node.get_children():
		if c is ColorRect:
			var cr := c as ColorRect
			var tl := origin + Vector2(cr.offset_left, cr.offset_top)
			var br := origin + Vector2(cr.offset_right, cr.offset_bottom)
			min_p = min_p.min(tl)
			max_p = max_p.max(br)
		elif c is CollisionShape2D:
			var cs := c as CollisionShape2D
			var shape := cs.shape
			if shape is RectangleShape2D:
				var half: Vector2 = (shape as RectangleShape2D).size * 0.5
				var centre: Vector2 = origin + cs.position
				min_p = min_p.min(centre - half)
				max_p = max_p.max(centre + half)
	if min_p.x == INF or max_p.x == -INF:
		return Rect2(origin, Vector2.ZERO)
	return Rect2(min_p, max_p - min_p)


func _find_player_camera() -> Camera2D:
	var players := get_tree().get_nodes_in_group("players")
	for p in players:
		if not (p is Node):
			continue
		var cam: Camera2D = _first_descendant_of_type(p, "Camera2D") as Camera2D
		if cam != null:
			return cam
	return null


func _first_descendant_of_type(node: Node, type_name: String) -> Node:
	for c in node.get_children():
		if c.get_class() == type_name:
			return c
		var hit: Node = _first_descendant_of_type(c, type_name)
		if hit != null:
			return hit
	return null


func _start_spawners() -> void:
	if _spawners_started:
		return
	_spawners_started = true
	for s in _find_all_spawners():
		if s.has_method("set_owner_room"):
			s.set_owner_room(self)
		_pending_waves += 1
		s.spawn_all(self)


func _initial_track() -> void:
	await get_tree().process_frame
	for n in get_tree().get_nodes_in_group("enemies"):
		if _is_descendant(n, self):
			track_enemy(n)
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
