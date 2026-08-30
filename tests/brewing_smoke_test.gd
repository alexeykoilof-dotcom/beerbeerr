# Автоматическая проверка полной цепочки варки: стол, предметы, бросок и рецепт.
extends SceneTree

# Все проваленные условия накапливаются здесь.
var failures: Array[String] = []


# Откладывает выполнение до готовности SceneTree.
func _init() -> void:
	call_deferred("_run")


# Создаёт главную сцену и имитирует действия игрока.
func _run() -> void:
	var main := (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	await physics_frame
	await physics_frame

	# Станция и её основные физические узлы обязаны существовать.
	var station := main.get_node_or_null("BrewingStation") as Node3D
	_check(station != null, "brewing station was not created")
	if station == null:
		_finish()
		return

	var ingredients := get_nodes_in_group("brew_ingredient")
	_check(ingredients.size() == 4, "recipe should spawn exactly four ingredients")
	_check(station.get_node_or_null("BrewingVat") is StaticBody3D, "brewing vat has no static collision body")
	_check(station.get_node_or_null("IngredientDetector") is Area3D, "brewing vat has no ingredient detector")
	_check(station.get_node_or_null("IngredientTable") is StaticBody3D, "ingredient table has no static collision body")
	var detector_shape := (station.get_node("IngredientDetector/CollisionShape3D") as CollisionShape3D).shape as CylinderShape3D
	_check(detector_shape.radius < 0.8, "brewing vat was not made more compact")
	# Проверяем, что все четыре ингредиента изначально лежат над столешницей.
	var table_top := station.get_node("IngredientTable/TableTop") as MeshInstance3D
	var table_top_mesh := table_top.mesh as BoxMesh
	var table_surface_y := table_top.global_position.y + table_top_mesh.size.y * 0.5
	for ingredient in ingredients:
		var body := ingredient as RigidBody3D
		_check(body.freeze, "ingredient is not aligned on the table before pickup")
		_check(body.global_position.y > table_surface_y, "ingredient is not resting above the table surface")

	# Направляем игрока на первый ингредиент и имитируем нажатие E.
	var player := main.get_node("Player") as CharacterBody3D
	var camera := player.get_node("Camera3D") as Camera3D
	var first_ingredient := ingredients[0] as RigidBody3D
	var original_parent := first_ingredient.get_parent()
	player.global_position = first_ingredient.global_position + Vector3(-1.5, 0, 0)
	camera.look_at(first_ingredient.global_position, Vector3.UP)
	player.call("_interact_with_ingredient")
	_check(player.get("held_item") == first_ingredient, "E interaction did not pick up the ingredient")
	_check(first_ingredient.get_parent() == original_parent, "physical held ingredient was reparented away from the world")
	_check(not first_ingredient.freeze, "held ingredient physics is frozen")
	_check(first_ingredient.collision_mask == 1, "held ingredient no longer collides with the world")
	_check(first_ingredient.gravity_scale > 0.0, "held ingredient has no gravity")
	# За несколько кадров физическая пружина должна приблизить предмет к камере.
	var hold_target := camera.global_position - camera.global_basis.z * 1.15 + Vector3.DOWN * 0.12
	var distance_before_hold_physics := first_ingredient.global_position.distance_to(hold_target)
	for frame in 5:
		await physics_frame
	var distance_after_hold_physics := first_ingredient.global_position.distance_to(hold_target)
	_check(distance_after_hold_physics < distance_before_hold_physics, "held ingredient does not follow the physical hold spring")

	# Второе E бросает предмет и возвращает его исходные слои коллизии.
	player.call("_interact_with_ingredient")
	_check(player.get("held_item") == null, "second E interaction did not release the ingredient")
	_check(first_ingredient.get_parent() == original_parent, "thrown ingredient was not returned to the world")
	_check(first_ingredient.collision_layer == 2, "thrown ingredient collision layer was not restored")
	_check(first_ingredient.linear_velocity.length() > 1.0, "released ingredient was not thrown")

	# Перемещаем все ингредиенты в область чана и даём физике зарегистрировать вход.
	var detector_collision := station.get_node("IngredientDetector/CollisionShape3D") as CollisionShape3D
	var drop_target := detector_collision.global_position + Vector3.UP * 0.2
	for ingredient in ingredients:
		if not is_instance_valid(ingredient):
			continue
		var body := ingredient as RigidBody3D
		body.freeze = true
		body.global_position = drop_target
		body.freeze = false
		body.linear_velocity = Vector3.DOWN
		await physics_frame
		await physics_frame

	# После четырёх предметов счётчики и поверхность пива должны показать результат.
	var counts: Dictionary = station.get("ingredient_counts")
	_check(counts["malt"] == 2, "vat did not count both malt portions")
	_check(counts["hops"] == 1, "vat did not count hops")
	_check(counts["yeast"] == 1, "vat did not count yeast")
	_check(station.get("brew_complete") == true, "completed recipe did not produce beer")
	var beer_surface := station.get_node("BeerSurface") as MeshInstance3D
	_check(beer_surface.visible, "finished beer is not visible in the vat")

	main.queue_free()
	await process_frame
	_finish()


# Сохраняет сообщение о неудачной проверке.
func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


# Завершает тест подходящим кодом выхода.
func _finish() -> void:
	if failures.is_empty():
		print("Brewing smoke test passed")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
