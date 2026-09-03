# Упрощённый цикл пивного бизнеса.
# Сырьё покупается в складе-магазине, остальные станции находятся на учебной площадке.
extends Node3D

@export_group("Старт")
@export var starting_money := 180
@export var starting_raw_materials := 1

@export_group("Цены")
@export var raw_batch_cost := 20
@export var raw_batch_size := 3
@export var experiment_cost := 30
@export var upgrade_base_cost := 80
@export var packaging_cost := 2
@export var cleaning_cost := 5

@export_group("Продажа")
@export var beer_price := 35

@export_group("Скорость производства")
@export_range(0.5, 10.0, 0.1) var base_brew_time := 2.0
@export_range(0.0, 1.0, 0.05) var brew_time_reduction_per_level := 0.4

@onready var state_label: Label3D = $StateBoard/StateLabel
@onready var message_label: Label3D = $StateBoard/MessageLabel
@onready var beer_timer: Timer = $ProductionTimers/BeerTimer

var money := 0
var raw_materials := 0
var equipment_level := 1
var recipe_level := 1
var cleanliness := 100
var total_revenue := 0
var total_expenses := 0
var bulk_beer := 0
var packed_beer := 0
var refresh_timer := 0.0
var last_message_key := ""
var last_message_values: Array = []


func _ready() -> void:
	money = starting_money
	raw_materials = starting_raw_materials
	beer_timer.timeout.connect(_finish_beer)
	Localization.language_changed.connect(_on_language_changed)
	_set_localized_message("business.raw_at_warehouse")
	_update_state_label()


func _process(delta: float) -> void:
	refresh_timer += delta
	if refresh_timer >= 0.2:
		refresh_timer = 0.0
		_update_state_label()


# Номер приходит из mechanics_station.gd и совпадает с простым пивным циклом.
func perform_action(action: int) -> void:
	match action:
		0:
			_buy_raw_materials()
		1:
			_start_beer()
		2:
			_package_beer()
		3:
			_sell_beer()
		4:
			_upgrade_equipment()
		5:
			_experiment_with_recipe()
		6:
			_clean_equipment()
	_update_state_label()


func _buy_raw_materials() -> void:
	if money < raw_batch_cost:
		_set_localized_message("business.no_money_raw")
		return
	_pay(raw_batch_cost)
	raw_materials += raw_batch_size
	_set_localized_message("business.bought_raw", [raw_batch_size, raw_batch_cost])


func _start_beer() -> void:
	if beer_timer.time_left > 0.0:
		_set_localized_message("business.already_brewing", [beer_timer.time_left])
		return
	if raw_materials <= 0:
		_set_localized_message("business.need_raw")
		return
	raw_materials -= 1
	cleanliness = maxi(cleanliness - 15, 0)
	beer_timer.wait_time = maxf(
		base_brew_time - float(equipment_level - 1) * brew_time_reduction_per_level,
		0.5
	)
	beer_timer.start()
	_set_localized_message("business.brew_started", [beer_timer.wait_time])


func _finish_beer() -> void:
	bulk_beer += 1
	_set_localized_message("business.beer_ready")
	_update_state_label()


func _package_beer() -> void:
	if bulk_beer <= 0:
		_set_localized_message("business.first_brew")
		return
	if money < packaging_cost:
		_set_localized_message("business.no_bottle_money", [packaging_cost])
		return
	bulk_beer -= 1
	packed_beer += 1
	_pay(packaging_cost)
	_set_localized_message("business.packaged")


func _sell_beer() -> void:
	if packed_beer <= 0:
		_set_localized_message("business.need_packaged")
		return
	packed_beer -= 1
	var income := _quality_price(beer_price)
	money += income
	total_revenue += income
	_set_localized_message("business.sold", [income])


func _upgrade_equipment() -> void:
	if equipment_level >= 3:
		_set_localized_message("business.max_equipment")
		return
	var cost := upgrade_base_cost * equipment_level
	if money < cost:
		_set_localized_message("business.need_upgrade_money", [cost])
		return
	_pay(cost)
	equipment_level += 1
	_set_localized_message("business.upgraded", [equipment_level])


func _experiment_with_recipe() -> void:
	if recipe_level >= 3:
		_set_localized_message("business.all_recipes")
		return
	if raw_materials <= 0 or money < experiment_cost:
		_set_localized_message("business.need_experiment", [experiment_cost])
		return
	raw_materials -= 1
	_pay(experiment_cost)
	recipe_level += 1
	_set_localized_message("business.recipe_opened", [recipe_level])


func _clean_equipment() -> void:
	if cleanliness >= 100:
		_set_localized_message("business.already_clean")
		return
	if money < cleaning_cost:
		_set_localized_message("business.need_clean_money", [cleaning_cost])
		return
	_pay(cleaning_cost)
	cleanliness = 100
	_set_localized_message("business.cleaned")


func _quality_price(base_price: int) -> int:
	var quality_bonus := float(equipment_level + recipe_level - 2) * 0.15
	var cleanliness_multiplier := 0.7 + float(cleanliness) / 100.0 * 0.3
	return roundi(float(base_price) * (1.0 + quality_bonus) * cleanliness_multiplier)


func _pay(amount: int) -> void:
	money -= amount
	total_expenses += amount


func _tier_name() -> String:
	if equipment_level >= 3:
		return Localization.get_text("business.tier_3")
	if equipment_level >= 2:
		return Localization.get_text("business.tier_2")
	return Localization.get_text("business.tier_1")


func _timer_text() -> String:
	if beer_timer.time_left <= 0.0:
		return Localization.get_text("business.timer_ready")
	return Localization.get_text("business.timer_seconds", [beer_timer.time_left])


func _set_message(text: String) -> void:
	if message_label:
		message_label.text = text


func _set_localized_message(key: String, values: Array = []) -> void:
	last_message_key = key
	last_message_values = values.duplicate()
	_set_message(Localization.get_text(key, values))


func _update_state_label() -> void:
	if state_label == null:
		return
	var net_result := total_revenue - total_expenses
	state_label.text = Localization.get_text("business.state", [
		money, raw_materials, net_result,
		equipment_level, recipe_level, cleanliness,
		_timer_text(), bulk_beer, packed_beer,
		_tier_name(),
	])


func _on_language_changed(_language_code: String) -> void:
	_update_state_label()
	if not last_message_key.is_empty():
		_set_message(Localization.get_text(last_message_key, last_message_values))
