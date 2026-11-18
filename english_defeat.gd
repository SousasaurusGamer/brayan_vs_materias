extends Control

@onready var retry_button: Button = $CenterContainer/VBoxContainer/RetryButton
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton


func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://english_level.tscn")


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
