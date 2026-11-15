extends Node

var health_bonus: int = 0

func add_health_upgrade() -> void:
	health_bonus += 20
	print("Health bonus: +", health_bonus)

	
