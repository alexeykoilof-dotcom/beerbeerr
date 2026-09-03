# Логика станции варки: принимает ингредиенты, считает рецепт и обновляет интерфейс.
extends Node3D

# Требуемое количество каждого типа ингредиента.
const RECIPE := {
	"malt": 2,
	"hops": 1,
	"yeast": 1,
}

# Пять хорошо различимых состояний жидкости: чистая вода и новый цвет после
# каждой из четырёх порций рецепта. Последний цвет — готовое янтарное пиво.
const LIQUID_STAGE_COLORS: Array[Color] = [
	Color(0.12, 0.48, 0.92, 0.72),
	Color(0.68, 0.58, 0.25, 0.78),
	Color(0.76, 0.43, 0.12, 0.8),
	Color(0.86, 0.3, 0.055, 0.84),
	Color(0.95, 0.5, 0.055, 0.88),
]

# Смешной объект, который чан выплёвывает после специального цветка.
# PackedScene можно заменить в Inspector на любую другую сцену-сюрприз.
@export_category("Смешной цветок")
@export var funny_surprise_scene: PackedScene = preload("res://funny_duck.tscn")
@export_range(1.0, 20.0, 0.5) var funny_launch_force := 8.0

# Текущее количество уже добавленных ингредиентов.
var ingredient_counts := {
	"malt": 0,
	"hops": 0,
	"yeast": 0,
}

# Вода обязательна: до наполнения чана рецепт не принимает ингредиенты.
var has_water := false

# Узлы интерфейса и вся перемещаемая механика внутри единого узла чана.
@onready var status_label: Label = $BrewingHUD/StatusLabel
@onready var message_label: Label = $BrewingHUD/MessageLabel
@onready var beer_surface: MeshInstance3D = $BrewingVat/BeerSurface
@onready var ingredient_detector: Area3D = $BrewingVat/IngredientDetector
var brew_complete := false

# При запуске сразу показывает пустой рецепт.
func _ready() -> void:
	# Материал делается локальным для этой станции, чтобы изменение цвета в игре
	# не перекрашивало ресурс сцены или второй чан, если он появится позже.
	if beer_surface.material_override:
		beer_surface.material_override = beer_surface.material_override.duplicate()
	beer_surface.visible = false
	_set_liquid_stage(0)
	Localization.language_changed.connect(_on_language_changed)
	_update_hud()


# Вызывается сигналом Area3D, когда физический предмет входит в область чана.
func _on_ingredient_entered(body: Node3D) -> void:
	# Для посторонних физических тел ничего не делаем.
	if not body.is_in_group("brew_ingredient"):
		return

	# Цветок — секретный ингредиент. Он обрабатывается отдельно и не меняет
	# количество солода, хмеля или дрожжей в обычном рецепте.
	if body.is_in_group("funny_flower"):
		_launch_funny_surprise(body)
		return

	if not has_water:
		_show_message(Localization.get_text("brew.need_water"))
		_eject_rejected_ingredient(body)
		return

	# После готовности пива обычные ингредиенты больше не засчитываются.
	if brew_complete:
		return

	var ingredient_id := String(body.get_meta("ingredient_id", ""))
	# Метаданные предмета должны содержать известный идентификатор рецепта.
	# Например, вылетевшую утку можно поднять и бросить, но funny_duck отсутствует
	# в RECIPE, поэтому повторное попадание утки в чан ничего не засчитывает.
	if not RECIPE.has(ingredient_id):
		return

	if ingredient_counts[ingredient_id] >= RECIPE[ingredient_id]:
		_show_message(Localization.get_text("brew.enough_ingredient"))
		return

	ingredient_counts[ingredient_id] += 1
	_set_liquid_stage(_total_ingredient_count())
	# Засчитанный предмет удаляется из мира, будто он упал внутрь чана.
	var ingredient_name := Localization.get_text("ingredient." + ingredient_id)
	body.queue_free()
	_show_message(Localization.get_text("brew.added", [ingredient_name]))
	_update_hud()

	if _is_recipe_complete():
		brew_complete = true
		_show_message(Localization.get_text("brew.ready"))
		_update_hud()


# Немного выталкивает предмет из сухого чана, чтобы он не застрял внутри Area3D
# и его можно было снова взять после добавления воды.
func _eject_rejected_ingredient(body: Node3D) -> void:
	if body is RigidBody3D:
		var rigid_body := body as RigidBody3D
		var away := (rigid_body.global_position - ingredient_detector.global_position)
		away.y = 0.0
		if away.length_squared() < 0.01:
			away = Vector3.FORWARD
		rigid_body.linear_velocity = away.normalized() * 2.2 + Vector3.UP * 3.2


# Удаляет попавший в чан цветок и выбрасывает утку вверх наружу.
func _launch_funny_surprise(flower: Node3D) -> void:
	flower.queue_free()
	if funny_surprise_scene == null:
		_show_message(Localization.get_text("brew.flower_no_surprise"))
		return

	# Сигнал Area3D приходит во время шага физики. Откладываем добавление нового
	# физического тела до конца кадра, чтобы PhysicsServer не менялся посреди расчёта.
	call_deferred("_spawn_funny_surprise")
	_show_message(Localization.get_text("brew.duck_surprise"))


# Создаёт и запускает назначенную сцену-сюрприз после завершения физического шага.
func _spawn_funny_surprise() -> void:
	var surprise := funny_surprise_scene.instantiate() as Node3D
	# Добавляем утку рядом со станцией, а не внутрь неё: после этого она живёт
	# как обычный независимый физический объект в главной сцене.
	get_parent().add_child(surprise)
	surprise.global_position = ingredient_detector.global_position + Vector3.UP * 0.45

	if surprise is RigidBody3D:
		# Небольшое случайное отклонение делает каждый вылет чуть разным.
		var sideways := Vector3(randf_range(-1.5, 1.5), 0.0, randf_range(-1.5, 1.5))
		surprise.apply_central_impulse(Vector3.UP * funny_launch_force + sideways)
		surprise.angular_velocity = Vector3(randf_range(-5.0, 5.0), randf_range(-7.0, 7.0), randf_range(-5.0, 5.0))


# Чан обрабатывает кружку отдельно от ингредиентов и не выбрасывает её из руки.
func try_fill_beer_mug(mug: Node, player: Node) -> bool:
	if not brew_complete:
		_show_message(Localization.get_text("brew.first_brew"))
		return true
	if bool(mug.get("is_filled")):
		_show_message(Localization.get_text("brew.mug_full"))
		return true
	if bool(mug.call("fill_with_beer", player)):
		_show_message(Localization.get_text("brew.mug_filled"))
	return true


# Переливает одну полную порцию воды из ведра. Повторно воду не расходует.
func try_add_water_from_bucket(bucket: Node, player: Node) -> bool:
	if has_water:
		_show_message(Localization.get_text("brew.water_enough"))
		return true
	if not bucket.has_method("has_water") or not bool(bucket.call("has_water")):
		_show_message(Localization.get_text("vat.need_water"))
		return true
	if not bucket.has_method("drain_water") or not bool(bucket.call("drain_water", player)):
		return true

	has_water = true
	beer_surface.visible = true
	_set_liquid_stage(0)
	_show_message(Localization.get_text("brew.water_added"))
	_update_hud()
	return true


# Возвращает true только тогда, когда выполнены все пункты RECIPE.
func _is_recipe_complete() -> bool:
	for ingredient_id in RECIPE:
		if ingredient_counts[ingredient_id] < RECIPE[ingredient_id]:
			return false
	return true


func _total_ingredient_count() -> int:
	return (
		int(ingredient_counts["malt"])
		+ int(ingredient_counts["hops"])
		+ int(ingredient_counts["yeast"])
	)


func _set_liquid_stage(stage: int) -> void:
	var material := beer_surface.material_override as StandardMaterial3D
	if material == null:
		return
	var safe_stage := clampi(stage, 0, LIQUID_STAGE_COLORS.size() - 1)
	var color := LIQUID_STAGE_COLORS[safe_stage]
	material.albedo_color = color
	material.emission = Color(color.r * 0.72, color.g * 0.62, color.b * 0.52, 1.0)


# Собирает многострочный текст счётчика в левом верхнем углу.
func _update_hud() -> void:
	var water_text := Localization.get_text("brew.water_yes" if has_water else "brew.water_no")
	status_label.text = Localization.get_text("brew.status", [
		water_text,
		ingredient_counts["malt"], RECIPE["malt"],
		ingredient_counts["hops"], RECIPE["hops"],
		ingredient_counts["yeast"], RECIPE["yeast"],
	])
	if brew_complete:
		status_label.text += "\n" + Localization.get_text("brew.complete")


func _on_language_changed(_language_code: String) -> void:
	_update_hud()


# Временно показывает короткое сообщение и очищает только именно это сообщение.
func _show_message(text: String) -> void:
	message_label.text = text
	var timer := get_tree().create_timer(2.0)
	# Анонимная функция сработает через две секунды и не затрёт более новое сообщение.
	timer.timeout.connect(func():
		if is_instance_valid(message_label) and message_label.text == text:
			message_label.text = ""
	)
