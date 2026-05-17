extends CanvasLayer
class_name PauseMenu
## Toggleable pause overlay. Listens for the "pause" input on any node
## (HUD or test_room can instance it). When visible, pauses the tree.

@onready var _root: Control = $Root
@onready var _resume: Button = $Root/Center/VBox/Resume
@onready var _menu: Button = $Root/Center/VBox/Menu
@onready var _quit: Button = $Root/Center/VBox/Quit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_resume.pressed.connect(_on_resume)
	_menu.pressed.connect(_on_menu)
	_quit.pressed.connect(_on_quit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	_root.visible = not _root.visible
	get_tree().paused = _root.visible


func _on_resume() -> void:
	_toggle()


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_quit() -> void:
	get_tree().quit()
