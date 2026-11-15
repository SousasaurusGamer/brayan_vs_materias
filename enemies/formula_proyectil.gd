
class_name FormulaProjectile
extends Area2D

@export var damage: int = 20

var speed: float = 250.0
var direction: Vector2 = Vector2.LEFT
var lifetime: float = 8.0

var from_player: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: CollisionShape2D = $CollisionShape2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    screen_notifier.screen_exited.connect(queue_free)


func _physics_process(delta: float) -> void:
    global_position += direction * speed * delta

    lifetime -= delta

    if lifetime <= 0.0:
        queue_free()


func change_image(new_texture: Texture2D) -> void:
    sprite.texture = new_texture

    var rectangle := RectangleShape2D.new()
    rectangle.size = new_texture.get_size() * sprite.scale.abs()
    hitbox.shape = rectangle


func _on_body_entered(body: Node2D) -> void:
    if from_player:
        if body is StaticBody2D and body.name == "ExamBoss":
            if body.has_method("take_damage"):
                body.take_damage(damage)

            queue_free()
    else:
        if body is CharacterBody2D:
            if body.has_method("take_damage"):
                body.take_damage(damage)

            queue_free()