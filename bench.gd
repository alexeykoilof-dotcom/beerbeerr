# Интерактивная лавочка: передаёт игроку точки посадки и безопасного выхода.
extends StaticBody3D

@onready var seat_point: Node3D = $SeatPoint
@onready var exit_point: Node3D = $ExitPoint


func interact(player: Node) -> void:
	if player and player.has_method("sit_on_bench"):
		player.call("sit_on_bench", seat_point, exit_point)


func get_interaction_text() -> String:
	return Localization.get_text("bench.sit")
