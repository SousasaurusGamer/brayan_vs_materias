extends StaticBody2D

@export var projectile_scene: PackedScene
@export var formula_textures: Array[Texture2D] = []

@onready var boss_health_bar: ProgressBar = $BossHealthBar

@export var shoot_interval: float = 2.0
@export var min_speed: float = 180.0
@export var max_speed: float = 380.0

@export var max_health: int = 300
@onready var current_health: int = max_health

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var shoot_timer: Timer = $ShootTimer

@onready var player: CharacterBody2D = get_parent().get_node_or_null("player") as CharacterBody2D


func _ready() -> void:
    shoot_timer.one_shot = false
    shoot_timer.timeout.connect(shoot_formula)
    shoot_timer.start(max(shoot_interval, 0.1))
    boss_health_bar.max_value = max_health
    boss_health_bar.value = current_health


func shoot_formula() -> void:
    if player == null:
        return

    if projectile_scene == null:
        return

    if formula_textures.is_empty():
        return


    var projectile: FormulaProjectile = projectile_scene.instantiate() as FormulaProjectile

    if projectile == null:
        return

    get_tree().current_scene.add_child(projectile)

    
    projectile.global_position = spawn_point.global_position


    projectile.direction = (
        player.global_position - spawn_point.global_position
    ).normalized()

    
    projectile.speed = randf_range(min_speed, max_speed)

    
    var random_texture: Texture2D = formula_textures.pick_random()
    projectile.change_image(random_texture)


func take_damage(amount: int) -> void:
    current_health = maxi(0, current_health - amount)

    boss_health_bar.value = current_health

    print("Boss health: ", current_health)

    if current_health <= 0:
        set_deferred("collision_layer", 0)
        get_tree().change_scene_to_file.call_deferred(
            "res://victory_screen.tscn"
        )