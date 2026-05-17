extends CharacterBody2D
class_name EnemyBase
## Base class for all enemies. Wires up damage flash, death, and
## currency drop on kill. Subclasses add AI in _physics_process.

@export var currency_on_death: int = 1
## When non-zero, spawns this many TimeShard pickups instead of (or in
## addition to) the direct currency grant. Useful for bosses to leave a
## visible "loot pile."
@export var shard_drops_on_death: int = 0
@export var shard_value: int = 5
@export var shard_scene: PackedScene = preload("res://scenes/pickups/time_shard.tscn")
@export var flash_color: Color = Color(1.5, 1.5, 1.5, 1.0)
@export var flash_duration: float = 0.08
## Visual scale for the enemy sprite. Bumped slightly so enemies read at the
## new wider camera zoom without enlarging their collision shapes.
@export var sprite_scale: float = 1.2

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var health: HealthComponent = get_node_or_null("HealthComponent") as HealthComponent

var _flash_tween: Tween


func _ready() -> void:
	if sprite != null and sprite_scale != 1.0:
		sprite.scale = Vector2(sprite_scale, sprite_scale)
	if health != null:
		health.damaged.connect(_on_damaged)
		health.died.connect(_on_died)


func _on_damaged(_amount: int, _current: int, _max_value: int) -> void:
	_flash()
	# Day 17/18: juice + audio on every enemy hit.
	var juice := get_node_or_null("/root/Juice")
	if juice != null:
		juice.shake(0.18)
		juice.hit_pause(0.025, 0.0)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play"):
		audio.play("hit", -6.0)


func _flash() -> void:
	if sprite == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	sprite.modulate = flash_color
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, flash_duration)


func _on_died() -> void:
	if currency_on_death > 0:
		GameState.add_currency(currency_on_death)
	_spawn_shards()
	# Bosses kick a bigger shake; regular mobs a small puff.
	var juice := get_node_or_null("/root/Juice")
	if juice != null:
		var amount := 0.85 if is_in_group("bosses") else 0.30
		juice.shake(amount)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play"):
		audio.play("enemy_death", -4.0)
	# Brief death feedback then despawn.
	if sprite != null:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
		tween.tween_callback(queue_free)
	else:
		queue_free()


func _spawn_shards() -> void:
	if shard_drops_on_death <= 0 or shard_scene == null:
		return
	var parent := get_tree().current_scene
	if parent == null:
		return
	for i in shard_drops_on_death:
		var s := shard_scene.instantiate()
		parent.add_child(s)
		var angle := randf() * TAU
		var dist := randf_range(20.0, 80.0)
		s.global_position = global_position + Vector2.RIGHT.rotated(angle) * dist
		if "value" in s:
			s.value = shard_value
