# Один перетаскиваемый слот. Данные предметов остаются в player.gd.
extends Button

@export_enum("hotbar", "storage") var slot_group := "storage"
@export var slot_index := 0


func _get_drag_data(_at_position: Vector2) -> Variant:
	var ui := get_tree().get_first_node_in_group("inventory_ui")
	if ui == null or not bool(ui.call("slot_has_item", slot_group, slot_index)):
		return null

	var preview := Label.new()
	preview.custom_minimum_size = size
	preview.text = text
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.add_theme_color_override("font_color", Color.WHITE)
	preview.add_theme_font_size_override("font_size", 12)
	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color = Color(0.12, 0.12, 0.12, 0.72)
	preview_style.border_color = Color(1, 1, 1, 0.9)
	preview_style.set_border_width_all(1)
	preview_style.set_corner_radius_all(6)
	preview.add_theme_stylebox_override("normal", preview_style)
	set_drag_preview(preview)
	return {"group": slot_group, "index": slot_index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("group") and data.has("index")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var ui := get_tree().get_first_node_in_group("inventory_ui")
	if ui:
		ui.call(
			"move_inventory_item",
			String(data["group"]),
			int(data["index"]),
			slot_group,
			slot_index
		)
