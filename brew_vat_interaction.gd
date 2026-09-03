# Контекстная подсказка чана, которую HUD показывает только при наведении прицела.
extends StaticBody3D


# Player вызывает этот метод после попадания луча прицела в физический корпус чана.
# Постоянный Label3D больше не нужен: текст появляется в общем интерфейсе игрока.
func get_interaction_text() -> String:
	var station := get_parent()
	if station and not bool(station.get("has_water")):
		return Localization.get_text("vat.dry")
	return Localization.get_text("vat.ready")


# Предмет в руке получает отдельное действие до обычного броска.
func interact_with_item(player: Node, item: Node) -> bool:
	if item == null:
		return false
	var station := get_parent()
	if item.has_method("drain_water") and station and station.has_method("try_add_water_from_bucket"):
		return bool(station.call("try_add_water_from_bucket", item, player))
	if not item.has_method("fill_with_beer"):
		return false
	if station and station.has_method("try_fill_beer_mug"):
		return bool(station.call("try_fill_beer_mug", item, player))
	return false


func get_item_interaction_text(item: Node) -> String:
	if item and item.has_method("drain_water"):
		if item.has_method("has_water") and bool(item.call("has_water")):
			return Localization.get_text("vat.add_water")
		return Localization.get_text("vat.need_water")
	if item and item.has_method("fill_with_beer"):
		return Localization.get_text("vat.fill_mug")
	return ""
