# Физическая кружка: хранит состояние пива и умеет использоваться в руке.
extends RigidBody3D

@onready var beer_visual: MeshInstance3D = $Beer

var is_filled := false


func _ready() -> void:
	_update_mug_state()


func fill_with_beer(player: Node = null) -> bool:
	if is_filled:
		return false
	is_filled = true
	_update_mug_state()
	if player and player.has_method("notify_inventory_changed"):
		player.call("notify_inventory_changed")
	return true


# Player вызывает это по E, если полная кружка находится в активной руке.
func use_in_hand(player: Node) -> bool:
	if not is_filled:
		return false
	if player:
		if bool(player.get("drinking_from_mug")):
			return true
		if player.has_method("drink_from_mug"):
			player.call("drink_from_mug", self)
			return true
	consume_beer(player)
	return true


func consume_beer(player: Node = null) -> void:
	is_filled = false
	_update_mug_state()
	if player and player.has_method("notify_inventory_changed"):
		player.call("notify_inventory_changed")


func get_use_in_hand_text() -> String:
	return Localization.get_text("mug.drink") if is_filled else ""


func _update_mug_state() -> void:
	beer_visual.visible = is_filled
	set_meta("item_key", "item.mug_beer" if is_filled else "item.mug")
	set_meta("item_name", Localization.get_text(String(get_meta("item_key"))))
