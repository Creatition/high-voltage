extends Control
class_name MainMenu
## The first thing the player sees. New Run / Continue / Quit.

@onready var _new_run: Button = $Center/VBox/NewRun
@onready var _continue_run: Button = $Center/VBox/Continue
@onready var _time_bank: Button = $Center/VBox/TimeBank
@onready var _boss_rush: Button = $Center/VBox/BossRush
@onready var _quit: Button = $Center/VBox/Quit
@onready var _meta_label: Label = $Center/VBox/MetaLabel


func _ready() -> void:
	_new_run.pressed.connect(_on_new_run)
	_continue_run.pressed.connect(_on_continue)
	_time_bank.pressed.connect(_on_time_bank)
	_boss_rush.pressed.connect(_on_boss_rush)
	_quit.pressed.connect(_on_quit)
	_meta_label.text = "Banked credits: $%d" % GameState.meta_currency
	# "Continue" only makes sense when there's an active dungeon queue.
	_continue_run.disabled = GameState.current_room_path() == ""
	# Day-28: grab focus on the first enabled button so gamepad / keyboard
	# navigation works the instant the menu opens. Without this nothing has
	# focus and pressing A/Enter/dpad does nothing.
	call_deferred("_grab_first_focus")


func _grab_first_focus() -> void:
	for btn in [_new_run, _continue_run, _time_bank, _boss_rush, _quit]:
		if btn != null and not btn.disabled:
			btn.focus_mode = Control.FOCUS_ALL
			btn.grab_focus()
			return


func _on_new_run() -> void:
	GameState.reset_run()
	# Day 16: route through character select first.
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")


func _on_continue() -> void:
	var path := GameState.current_room_path()
	if path != "" and ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		get_tree().change_scene_to_file("res://scenes/ui/era_picker.tscn")


func _on_time_bank() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/meta_menu.tscn")


func _on_boss_rush() -> void:
	GameState.reset_run()
	GameState.current_era = "boss_rush"
	GameState.dungeon_queue = [
		"res://scenes/rooms/present_boss.tscn",
		"res://scenes/rooms/aztec_boss.tscn",
		"res://scenes/rooms/medieval_boss.tscn",
		"res://scenes/rooms/prehistoric_boss.tscn",
		"res://scenes/rooms/cyberpunk_boss.tscn",
		"res://scenes/rooms/alien_boss.tscn",
	]
	GameState.dungeon_index = 0
	get_tree().change_scene_to_file(GameState.current_room_path())


func _on_quit() -> void:
	get_tree().quit()
