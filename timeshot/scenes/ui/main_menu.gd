extends Control
class_name MainMenu
## The first thing the player sees. New Run / Continue / Quit.

@onready var _new_run: Button = $Center/VBox/NewRun
@onready var _continue_run: Button = $Center/VBox/Continue
@onready var _quit: Button = $Center/VBox/Quit
@onready var _meta_label: Label = $Center/VBox/MetaLabel


func _ready() -> void:
	_new_run.pressed.connect(_on_new_run)
	_continue_run.pressed.connect(_on_continue)
	_quit.pressed.connect(_on_quit)
	_meta_label.text = "Banked credits: $%d" % GameState.meta_currency
	# "Continue" only makes sense when there's an active dungeon queue.
	_continue_run.disabled = GameState.current_room_path() == ""


func _on_new_run() -> void:
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/hub/time_machine_hub.tscn")


func _on_continue() -> void:
	var path := GameState.current_room_path()
	if path != "" and ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		get_tree().change_scene_to_file("res://scenes/hub/time_machine_hub.tscn")


func _on_quit() -> void:
	get_tree().quit()
