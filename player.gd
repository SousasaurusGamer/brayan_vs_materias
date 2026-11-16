
extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal died

@export var speed: float = 250.0
@export var jump_velocity: float = -600.0
@export var max_health: int = 100

@export var shot_speed: float = 500.0
@export var shot_damage: int = 10


const PROJECTILE_SCENE: PackedScene = preload(
    "res://enemies/formula_proyectil.tscn"
)

var current_health: int
var is_dead: bool = false

@onready var skin: AnimatedSprite2D = $skin
@onready var shoot_point: Marker2D = $ShootPoint
@onready var shoot_cooldown: Timer = $ShootCooldown


func _ready() -> void:
    max_health += UpgradeData.health_bonus
    current_health = max_health

    skin.animation_finished.connect(_on_animation_finished)
    skin.play("move")


func _physics_process(delta: float) -> void:
    if is_dead:
        return

    # Gravity
    if not is_on_floor():
        velocity += get_gravity() * delta

    # Jump
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    # Horizontal movement
    var direction: float = Input.get_axis("move_left", "move_right")

    if direction != 0.0:
        velocity.x = direction * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed)

    # Shoot with F
    if Input.is_action_just_pressed("shoot"):
        shoot()

    move_and_slide()


func shoot() -> void:
    if not shoot_cooldown.is_stopped():
        return

    var boss = get_parent().get_node_or_null("ExamBoss")

    if boss == null:
        return

    # Use the same formula textures as the boss
    var textures: Array = boss.get("formula_textures")

    if textures.is_empty():
        return

    var projectile: FormulaProjectile = PROJECTILE_SCENE.instantiate() as FormulaProjectile

    if projectile == null:
        return

    get_tree().current_scene.add_child(projectile)

    projectile.global_position = shoot_point.global_position

    # Aim at the boss
    projectile.direction = (
        boss.global_position - shoot_point.global_position
    ).normalized()

    projectile.speed = shot_speed
    projectile.damage = shot_damage
    projectile.from_player = true

    # Detect only collision layer 4
    projectile.collision_mask = 1 << 3

    # Choose a random formula
    var texture: Texture2D = textures.pick_random()
    projectile.change_image(texture)

    # Play shooting animation
    skin.play("shoot")
    shoot_cooldown.start()


func _on_animation_finished() -> void:
    if skin.animation == "shoot":
        skin.play("move")


func take_damage(amount: int) -> void:
    if is_dead:
        return

    current_health = clampi(
        current_health - max(amount, 0),
        0,
        max_health
    )

    health_changed.emit(current_health, max_health)

    if current_health <= 0:
        die()


func die() -> void:
    is_dead = true
    velocity = Vector2.ZERO
    died.emit()
