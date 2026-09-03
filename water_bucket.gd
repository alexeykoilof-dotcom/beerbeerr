# Переносимое ведро. Оно хранит только одно состояние: пустое или с водой.
extends RigidBody3D

@onready var water_visual: MeshInstance3D = $Water

var is_filled_with_water := false


func _ready() -> void:
	_update_bucket_state()


# Водокачка вызывает этот метод, когда игрок держит рядом пустое ведро.
func fill_with_water(player: Node = null) -> bool:
	if is_filled_with_water:
		return false
	is_filled_with_water = true
	_update_bucket_state()
	_notify_player(player)
	return true


# Чан вызывает этот метод только после всех собственных проверок.
func drain_water(player: Node = null) -> bool:
	if not is_filled_with_water:
		return false
	is_filled_with_water = false
	_update_bucket_state()
	_notify_player(player)
	return true


func has_water() -> bool:
	return is_filled_with_water


func _update_bucket_state() -> void:
	water_visual.visible = is_filled_with_water
	set_meta("item_key", "item.bucket_water" if is_filled_with_water else "item.bucket_empty")
	set_meta("item_name", Localization.get_text(String(get_meta("item_key"))))


func _notify_player(player: Node) -> void:
	if player and player.has_method("notify_inventory_changed"):
		player.call("notify_inventory_changed")
