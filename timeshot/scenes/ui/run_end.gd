extends Control
class_name RunEnd
## Post-run screen. Shows banked credits and upgrades collected during the run.

@onready var _credits: Label = $Center/Panel/Margin/VBox/Credits
@onready var _upgrades: Label = $Center/Panel/Margin/VBox/UpgradesList
@onready var _again: Button = $Center/Panel/Margin/VBox/AgainBtn
@onready var _menu: Button = $Center/Panel/Margin/VBox/MenuBtn


func _ready() -> void:
	_credits.text = "Banked Credits: $%d  (this run: $%d)" % [GameState.meta_currency, GameState.last_run_currency]
	var names: Array = []
	for upgrade_id in GameState.last_run_upgrades:
		var data := UpgradePool.get_by_id(upgrade_id)
		if data.is_empty():
			names.append(upgrade_id)
		else:
			names.append(data.get("name", upgrade_id))
	if names.is_empty():
		_upgrades.text = "(no upgrades collected this run)"
	else:
		_upgrades.text = "Upgrades: " + ", ".join(names)
	_again.pressed.connect(_on_again)
	_menu.pressed.connect(_on_menu)


func _on_again() -> void:
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/hub/time_machine_hub.tscn")


func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
