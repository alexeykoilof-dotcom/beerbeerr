# Неподвижная водокачка. Работает только с предметом, который умеет
# fill_with_water(), поэтому кружка и остальные предметы сюда не подходят.
extends StaticBody3D


func get_interaction_text() -> String:
	return Localization.get_text("pump.prompt")


func interact_with_item(player: Node, item: Node) -> bool:
	if item == null or not item.has_method("fill_with_water"):
		return false
	if item.has_method("has_water") and bool(item.call("has_water")):
		_show_player_message(player, Localization.get_text("pump.bucket_full_message"))
		return true
	if bool(item.call("fill_with_water", player)):
		_show_player_message(player, Localization.get_text("pump.bucket_filled_message"))
	return true


func get_item_interaction_text(item: Node) -> String:
	if item == null or not item.has_method("fill_with_water"):
		return ""
	if item.has_method("has_water") and bool(item.call("has_water")):
		return Localization.get_text("pump.bucket_full")
	return Localization.get_text("pump.fill")


func _show_player_message(player: Node, text: String) -> void:
	if player == null:
		return
	if player.has_method("show_action_message"):
		player.call("show_action_message", text, 1400)
