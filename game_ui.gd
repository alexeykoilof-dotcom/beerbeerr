# Компактный HUD, перетаскиваемый инвентарь и Esc-пауза.
extends CanvasLayer

const HOTBAR_SIZE := 4
const STORAGE_SIZE := 8

@onready var hotbar: Control = $Hotbar
@onready var inventory_overlay: Control = $InventoryOverlay
@onready var pause_overlay: Control = $PauseOverlay
@onready var resume_button: Button = $PauseOverlay/Center/Panel/Margin/Content/Resume
@onready var quit_button: Button = $PauseOverlay/Center/Panel/Margin/Content/Quit
@onready var language_label: Label = $PauseOverlay/Center/Panel/Margin/Content/LanguageRow/Label
@onready var language_selector: OptionButton = $PauseOverlay/Center/Panel/Margin/Content/LanguageRow/Selector

var player: CharacterBody3D
var hotbar_slots: Array[Button] = []
var editor_hotbar_slots: Array[Button] = []
var storage_slots: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	for slot_index in HOTBAR_SIZE:
		hotbar_slots.append(get_node("Hotbar/Slots/Slot%d" % (slot_index + 1)) as Button)
		editor_hotbar_slots.append(get_node(
			"InventoryOverlay/Center/Panel/Margin/Content/ActiveSlots/Slot%d" % (slot_index + 1)
		) as Button)
	for slot_index in STORAGE_SIZE:
		storage_slots.append(get_node(
			"InventoryOverlay/Center/Panel/Margin/Content/StorageSlots/Slot%d" % (slot_index + 1)
		) as Button)

	resume_button.pressed.connect(close_pause_menu)
	quit_button.pressed.connect(func(): get_tree().quit())
	_setup_language_selector()
	Localization.language_changed.connect(_on_language_changed)
	if player:
		player.inventory_changed.connect(_refresh_inventory)
	_refresh_language()
	_refresh_inventory()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.physical_keycode == KEY_TAB:
		if not pause_overlay.visible:
			toggle_inventory()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		var dialogue := get_tree().get_first_node_in_group("modal_dialogue") as Control
		if dialogue and dialogue.visible:
			return
		if inventory_overlay.visible:
			close_inventory()
		elif pause_overlay.visible:
			close_pause_menu()
		else:
			open_pause_menu()
		get_viewport().set_input_as_handled()
		return

	var slot_index := _slot_index_from_key(event.physical_keycode)
	if slot_index >= 0 and player:
		player.call("select_inventory_slot", slot_index)
		get_viewport().set_input_as_handled()


func toggle_inventory() -> void:
	if inventory_overlay.visible:
		close_inventory()
	else:
		open_inventory()


func open_inventory() -> void:
	pause_overlay.hide()
	inventory_overlay.show()
	hotbar.hide()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_aim_hud_visible(false)
	_refresh_inventory()


func close_inventory() -> void:
	inventory_overlay.hide()
	hotbar.show()
	_resume_gameplay()


func open_pause_menu() -> void:
	inventory_overlay.hide()
	pause_overlay.show()
	hotbar.hide()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_aim_hud_visible(false)
	resume_button.grab_focus()


func close_pause_menu() -> void:
	pause_overlay.hide()
	hotbar.show()
	_resume_gameplay()


func _resume_gameplay() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_set_aim_hud_visible(true)


func _set_aim_hud_visible(is_visible: bool) -> void:
	var crosshair := get_tree().get_first_node_in_group("interaction_crosshair") as Control
	var prompt := get_tree().get_first_node_in_group("interaction_prompt") as Control
	if crosshair:
		crosshair.visible = is_visible
	if prompt:
		prompt.hide()


func slot_has_item(slot_group: String, slot_index: int) -> bool:
	return player != null and bool(player.call("inventory_slot_has_item", slot_group, slot_index))


func move_inventory_item(source_group: String, source_index: int, target_group: String, target_index: int) -> void:
	if player:
		player.call("move_inventory_item", source_group, source_index, target_group, target_index)


func _refresh_inventory() -> void:
	if player == null:
		return
	var selected_slot := int(player.get("selected_inventory_slot"))

	for slot_index in HOTBAR_SIZE:
		var item_name := String(player.call("get_slot_item_name", "hotbar", slot_index))
		var slot_text := str(slot_index + 1) if item_name.is_empty() else "%d\n%s" % [slot_index + 1, _compact_name(item_name)]
		hotbar_slots[slot_index].text = slot_text
		editor_hotbar_slots[slot_index].text = slot_text
		_apply_slot_style(hotbar_slots[slot_index], slot_index == selected_slot)
		_apply_slot_style(editor_hotbar_slots[slot_index], slot_index == selected_slot)

	for slot_index in STORAGE_SIZE:
		var item_name := String(player.call("get_slot_item_name", "storage", slot_index))
		storage_slots[slot_index].text = "" if item_name.is_empty() else _compact_name(item_name)
		_apply_slot_style(storage_slots[slot_index], false)


func _setup_language_selector() -> void:
	language_selector.clear()
	for language_code in Localization.SUPPORTED_LANGUAGES:
		language_selector.add_item(Localization.get_language_name(language_code))
		var item_index := language_selector.item_count - 1
		language_selector.set_item_metadata(item_index, language_code)
	language_selector.select(Localization.get_language_index())
	language_selector.item_selected.connect(_on_language_selected)


func _on_language_selected(item_index: int) -> void:
	var language_code := String(language_selector.get_item_metadata(item_index))
	Localization.set_language(language_code)


func _on_language_changed(_language_code: String) -> void:
	_refresh_language()
	_refresh_inventory()


func _refresh_language() -> void:
	$InventoryOverlay/Center/Panel/Margin/Content/Title.text = Localization.get_text("ui.inventory")
	$InventoryOverlay/Center/Panel/Margin/Content/ActiveLabel.text = Localization.get_text("ui.active")
	$InventoryOverlay/Center/Panel/Margin/Content/StorageLabel.text = Localization.get_text("ui.items")
	$PauseOverlay/Center/Panel/Margin/Content/Title.text = Localization.get_text("ui.pause")
	resume_button.text = Localization.get_text("ui.resume")
	quit_button.text = Localization.get_text("ui.quit")
	language_label.text = Localization.get_text("ui.language")
	language_selector.select(Localization.get_language_index())


func _apply_slot_style(button: Button, selected: bool) -> void:
	var border_alpha := 0.92 if selected else 0.38
	var border_width := 2 if selected else 1
	button.add_theme_stylebox_override("normal", _make_slot_style(border_alpha, border_width, 0.025))
	button.add_theme_stylebox_override("hover", _make_slot_style(0.82, 1, 0.07))
	button.add_theme_stylebox_override("pressed", _make_slot_style(1.0, 2, 0.1))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color(1, 1, 1, 0.96 if selected else 0.68))
	button.add_theme_color_override("font_hover_color", Color.WHITE)


func _make_slot_style(border_alpha: float, border_width: int, background_alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, background_alpha)
	style.border_color = Color(1, 1, 1, border_alpha)
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	return style


func _compact_name(item_name: String) -> String:
	var clean_name := item_name.to_upper()
	return clean_name.left(9) + "…" if clean_name.length() > 10 else clean_name


func _slot_index_from_key(keycode: Key) -> int:
	match keycode:
		KEY_1:
			return 0
		KEY_2:
			return 1
		KEY_3:
			return 2
		KEY_4:
			return 3
	return -1
