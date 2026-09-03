# Наружная кнопка ручного управления воротами гаража.
extends StaticBody3D

@export var gate_controller_path := NodePath("../..")
@export var outside_minimum_distance := 0.15

@onready var button_visual: MeshInstance3D = $"../Button"
@onready var indicator: MeshInstance3D = $"../Indicator"

var button_material: StandardMaterial3D
var indicator_material: StandardMaterial3D


func _ready() -> void:
	button_material = _make_local_material(button_visual)
	indicator_material = _make_local_material(indicator)
	_apply_state()


func interact(player: CharacterBody3D) -> void:
	var controller := get_node_or_null(gate_controller_path)
	if controller == null or not controller.has_method("toggle_garage_gate"):
		return
	# Когда ворота открыты, закрыть их можно только стоя перед наружной
	# стороной кнопки. Игрок внутри гаража не сможет запереть сам себя.
	if _gate_is_open() and not _is_player_outside(player):
		if player and player.has_method("show_action_message"):
			player.call("show_action_message", Localization.get_text("gate.close_outside"))
		return
	controller.call("toggle_garage_gate")
	_apply_state()
	if player and player.has_method("show_action_message"):
		player.call(
			"show_action_message",
			Localization.get_text("gate.opening" if _gate_is_open() else "gate.closing")
		)


func get_interaction_text() -> String:
	if _gate_is_open() and not _is_player_outside(_find_player()):
		return Localization.get_text("gate.close_outside")
	return Localization.get_text("gate.close" if _gate_is_open() else "gate.open")


func _find_player() -> CharacterBody3D:
	return get_tree().get_first_node_in_group("player") as CharacterBody3D


func _is_player_outside(player: CharacterBody3D) -> bool:
	if player == null:
		return false
	# Локальная +Z кнопки направлена на улицу. Это продолжит работать,
	# даже если всю стойку передвинуть или повернуть в 3D-редакторе.
	return to_local(player.global_position).z >= outside_minimum_distance


func _gate_is_open() -> bool:
	var controller := get_node_or_null(gate_controller_path)
	return controller != null and bool(controller.get("gate_is_open"))


func _apply_state() -> void:
	var is_open := _gate_is_open()
	button_visual.position.z = 0.105 if is_open else 0.13
	if button_material:
		button_material.albedo_color = Color(0.18, 0.72, 0.32, 1.0) if is_open else Color(0.95, 0.34, 0.08, 1.0)
	if indicator_material:
		var color := Color(0.26, 1.0, 0.45, 1.0) if is_open else Color(1.0, 0.24, 0.1, 1.0)
		indicator_material.albedo_color = color
		indicator_material.emission = color


func _make_local_material(mesh: MeshInstance3D) -> StandardMaterial3D:
	var source := mesh.material_override as StandardMaterial3D
	if source == null:
		return null
	var local_material := source.duplicate() as StandardMaterial3D
	mesh.material_override = local_material
	return local_material
