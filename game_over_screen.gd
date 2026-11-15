extends Control

@onready var upgrade_button: Button = get_node("CenterContainer/VBoxContainer/UpgradeHealthButton")
@onready var restart_button: Button = get_node("CenterContainer/VBoxContainer/RestartButton")
@onready var upgrade_info: Label = get_node("CenterContainer/VBoxContainer/UpgradeInfo")

func _ready() -> void:
	restart_button.disabled = true
	upgrade_button.disabled = false

	upgrade_button.pressed.connect(_on_upgrade_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

	upgrade_info.text = "Choose +20 HP before restarting"


func _on_upgrade_pressed() -> void:
	if upgrade_button.disabled:
		return

	UpgradeData.add_health_upgrade()

	upgrade_button.disabled = true

	restart_button.disabled = false

	upgrade_info.text = "Total health bonus: +%d HP" % UpgradeData.health_bonus


func _on_restart_pressed() -> void:
	if restart_button.disabled:
		return

	get_tree().change_scene_to_file("res://mat_level.tscn")	
