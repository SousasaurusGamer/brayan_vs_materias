extends CanvasLayer

@onready var player = get_parent().get_node("player")
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:

	player.health_changed.connect(update_health)
	player.died.connect(show_game_over)

	health_bar.max_value = player.max_health
	health_bar.value = player.current_health


func update_health(current_health: int, maximum_health: int) -> void:
	health_bar.max_value = maximum_health
	health_bar.value = current_health



func show_game_over() -> void:
	get_tree().change_scene_to_file.call_deferred(
		"res://game_over_screen.tscn"
	)
