# Одна интерактивная ячейка грядки: принимает семечко, постепенно выращивает
# растение и после созревания выдаёт физический сноп урожая.
extends StaticBody3D

enum GrowthState {
	EMPTY,
	GROWING,
	MATURE,
}

@export_range(1.0, 300.0, 1.0) var growth_duration := 30.0
@export var harvest_scene: PackedScene = preload("res://garden_harvest.tscn")

@onready var plant_visual: Node3D = $PlantVisual

var state := GrowthState.EMPTY
var growth_elapsed := 0.0


func _ready() -> void:
	_update_visual()


func _process(delta: float) -> void:
	if state != GrowthState.GROWING:
		return

	growth_elapsed = minf(growth_elapsed + delta, growth_duration)
	if growth_elapsed >= growth_duration:
		state = GrowthState.MATURE
	_update_visual()


func get_interaction_text() -> String:
	match state:
		GrowthState.EMPTY:
			return Localization.get_text("garden.empty")
		GrowthState.GROWING:
			return Localization.get_text("garden.growing", [roundi(get_growth_ratio() * 100.0)])
		GrowthState.MATURE:
			return Localization.get_text("garden.harvest")
	return ""


func get_item_interaction_text(item: Node) -> String:
	if state == GrowthState.EMPTY and _is_seed(item):
		return Localization.get_text("garden.plant")
	return ""


func interact_with_item(player: Node, item: Node) -> bool:
	if state != GrowthState.EMPTY or not _is_seed(item):
		return false

	state = GrowthState.GROWING
	growth_elapsed = 0.0
	item.queue_free()
	_update_visual()
	_show_player_message(player, Localization.get_text("garden.planted"))
	if player and player.has_method("notify_inventory_changed"):
		player.call_deferred("notify_inventory_changed")
	return true


func interact(player: Node = null) -> void:
	if state != GrowthState.MATURE:
		return
	_spawn_harvest()
	state = GrowthState.EMPTY
	growth_elapsed = 0.0
	_update_visual()
	_show_player_message(player, Localization.get_text("garden.harvested"))


func get_growth_ratio() -> float:
	if state == GrowthState.MATURE:
		return 1.0
	if state == GrowthState.EMPTY:
		return 0.0
	return clampf(growth_elapsed / maxf(growth_duration, 0.001), 0.0, 1.0)


func is_empty() -> bool:
	return state == GrowthState.EMPTY


func is_growing() -> bool:
	return state == GrowthState.GROWING


func is_mature() -> bool:
	return state == GrowthState.MATURE


func _is_seed(item: Node) -> bool:
	return item != null and (
		item.is_in_group("garden_seed")
		or String(item.get_meta("item_kind", "")) == "garden_seed"
	)


func _update_visual() -> void:
	if not is_instance_valid(plant_visual):
		return
	if state == GrowthState.EMPTY:
		plant_visual.visible = false
		return

	var ratio := get_growth_ratio()
	plant_visual.visible = true
	plant_visual.scale = Vector3(
		lerpf(0.3, 1.0, ratio),
		lerpf(0.08, 1.0, ratio),
		lerpf(0.3, 1.0, ratio)
	)


func _spawn_harvest() -> void:
	if harvest_scene == null:
		return
	var harvest := harvest_scene.instantiate() as RigidBody3D
	if harvest == null:
		return
	var garden_root := get_parent().get_parent()
	garden_root.add_child(harvest)
	harvest.global_position = global_position + Vector3.UP * 0.85 + global_basis.z * 0.55
	harvest.global_rotation = Vector3(0.0, global_rotation.y, 0.18)
	harvest.apply_central_impulse(Vector3.UP * 0.7 + global_basis.z * 0.35)


func _show_player_message(player: Node, text: String) -> void:
	if player and player.has_method("show_action_message"):
		player.call("show_action_message", text, 1400)
