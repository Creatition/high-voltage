extends Node
## Registers all gameplay input actions at startup.
## Bindings cover keyboard + mouse + Xbox/DualSense/generic gamepad.
## Player rebinding (future feature) will override these at runtime via InputMap API.

const ACTIONS := {
	# Movement (twin-stick: left stick / WASD)
	"move_up":    [{"key": KEY_W}, {"key": KEY_UP},    {"joy_axis": JOY_AXIS_LEFT_Y, "value": -1.0}],
	"move_down":  [{"key": KEY_S}, {"key": KEY_DOWN},  {"joy_axis": JOY_AXIS_LEFT_Y, "value":  1.0}],
	"move_left":  [{"key": KEY_A}, {"key": KEY_LEFT},  {"joy_axis": JOY_AXIS_LEFT_X, "value": -1.0}],
	"move_right": [{"key": KEY_D}, {"key": KEY_RIGHT}, {"joy_axis": JOY_AXIS_LEFT_X, "value":  1.0}],

	# Aim (right stick on gamepad; mouse handles aim on keyboard)
	"aim_up":    [{"joy_axis": JOY_AXIS_RIGHT_Y, "value": -1.0}],
	"aim_down":  [{"joy_axis": JOY_AXIS_RIGHT_Y, "value":  1.0}],
	"aim_left":  [{"joy_axis": JOY_AXIS_RIGHT_X, "value": -1.0}],
	"aim_right": [{"joy_axis": JOY_AXIS_RIGHT_X, "value":  1.0}],

	# Shoot: mouse left + right trigger + right bumper
	"shoot": [
		{"mouse": MOUSE_BUTTON_LEFT},
		{"joy_axis": JOY_AXIS_TRIGGER_RIGHT, "value": 1.0},
		{"joy_button": JOY_BUTTON_RIGHT_SHOULDER},
	],

	# Dodge roll: spacebar + A (Xbox) / Cross (PS)
	"dodge": [{"key": KEY_SPACE}, {"joy_button": JOY_BUTTON_A}],

	# Interact / pick up: E + X (Xbox) / Square (PS)
	"interact": [{"key": KEY_E}, {"joy_button": JOY_BUTTON_X}],

	# Reload (used later when reload mechanic is added)
	"reload": [{"key": KEY_R}, {"joy_button": JOY_BUTTON_B}],

	# Pause menu
	"pause": [{"key": KEY_ESCAPE}, {"joy_button": JOY_BUTTON_START}],
}

const DEADZONE := 0.2


func _ready() -> void:
	_register_actions()


func _register_actions() -> void:
	for action_name in ACTIONS.keys():
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)
		InputMap.add_action(action_name, DEADZONE)
		for binding in ACTIONS[action_name]:
			var event := _create_event(binding)
			if event != null:
				InputMap.action_add_event(action_name, event)


func _create_event(binding: Dictionary) -> InputEvent:
	if binding.has("key"):
		var ev := InputEventKey.new()
		ev.physical_keycode = binding["key"]
		return ev
	if binding.has("mouse"):
		var ev := InputEventMouseButton.new()
		ev.button_index = binding["mouse"]
		return ev
	if binding.has("joy_button"):
		var ev := InputEventJoypadButton.new()
		ev.button_index = binding["joy_button"]
		return ev
	if binding.has("joy_axis"):
		var ev := InputEventJoypadMotion.new()
		ev.axis = binding["joy_axis"]
		ev.axis_value = binding["value"]
		return ev
	return null


## Returns the current movement vector from any active input source.
func get_move_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


## Returns the current aim vector. Falls back to mouse aim relative to a node
## when the right stick is idle.
##
## IMPORTANT: `viewport.get_mouse_position()` returns *screen-space* coords,
## but `from_position` is the player's *world-space* global_position. When the
## camera scrolls or zooms (which it does once we're in a real dungeon) the
## two coordinate spaces diverge and bullets drift away from the cursor.
## We fix that by mapping the mouse through the inverse canvas transform so
## both vectors live in world space.
func get_aim_vector(from_position: Vector2, viewport: Viewport) -> Vector2:
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick.length() > DEADZONE:
		return stick.normalized()
	var screen_mouse := viewport.get_mouse_position()
	var canvas_xform := viewport.get_canvas_transform()
	var world_mouse := canvas_xform.affine_inverse() * screen_mouse
	var direction := world_mouse - from_position
	if direction.length() < 1.0:
		return Vector2.RIGHT
	return direction.normalized()
