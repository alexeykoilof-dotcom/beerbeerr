# Автоматическая проверка коллизий игрока, рельефа, гаража, камней и ворот.
extends SceneTree

# Общий список найденных проблем.
var failures: Array[String] = []


# Запускает тест после готовности дерева сцены.
func _init() -> void:
	call_deferred("_run")


# Загружает настоящую main.tscn и проверяет её как во время игры.
func _run() -> void:
	# Если сцена не загрузилась, дальнейшие обращения к узлам бессмысленны.
	var packed_scene := load("res://main.tscn") as PackedScene
	_check(packed_scene != null, "main.tscn could not be loaded")
	if packed_scene == null:
		_finish()
		return

	var main := packed_scene.instantiate() as Node3D
	root.add_child(main)
	await physics_frame
	await physics_frame

	# Размер и центр капсулы должны совпадать с параметрами контроллера.
	var player := main.get_node("Player") as CharacterBody3D
	var player_collision := player.get_node("CollisionShape3D") as CollisionShape3D
	var player_shape := player_collision.shape as CapsuleShape3D
	_check(is_equal_approx(player_shape.radius, 0.35), "player capsule radius is incorrect")
	_check(is_equal_approx(player_shape.height, 1.8), "player standing height is incorrect")
	_check(player_collision.position.is_equal_approx(Vector3.ZERO), "player collider is offset from the body")

	# Старый плоский пол хранится для редактирования, но не участвует в игре.
	var floor_body := main.get_node("Floor") as StaticBody3D
	var floor_collision := floor_body.get_node("CollisionShape3D") as CollisionShape3D
	var floor_visual := floor_body.get_node("MeshInstance3D") as MeshInstance3D
	var floor_shape := floor_collision.shape as BoxShape3D
	var floor_mesh := floor_visual.mesh as BoxMesh
	_check(floor_shape.size.is_equal_approx(floor_mesh.size), "floor collider size does not match the mesh")
	_check(floor_collision.disabled, "old flat floor collision is still enabled")
	_check(not floor_visual.visible, "old flat floor is still visible")

	# Проверяем визуальную сетку рельефа, материалы и точную треугольную коллизию.
	var terrain := main.get_node_or_null("Terrain") as Node3D
	_check(terrain != null, "editable terrain scene is missing")
	if terrain:
		var terrain_mesh := terrain.get_node_or_null("TerrainMesh") as MeshInstance3D
		_check(terrain_mesh != null and terrain_mesh.mesh is ArrayMesh, "terrain has no continuous editable mesh")
		if terrain_mesh and terrain_mesh.mesh:
			var vertex_count: int = terrain_mesh.mesh.surface_get_array_len(0)
			_check(vertex_count >= 4000, "terrain mesh is not detailed enough")
			var grass_material := terrain_mesh.get_active_material(0) as StandardMaterial3D
			_check(grass_material != null and grass_material.albedo_texture != null, "terrain has no editable grass texture")
			if grass_material and grass_material.albedo_texture:
				_check(grass_material.albedo_texture.resource_path.ends_with("grass_ground_v1.png"), "terrain is not using the visible grass texture asset")
				_check(grass_material.cull_mode == BaseMaterial3D.CULL_DISABLED, "terrain material can be culled from the player side")
		var terrain_collision := terrain.get_node("TerrainBody/TerrainCollision") as CollisionShape3D
		var terrain_shape := terrain_collision.shape as ConcavePolygonShape3D
		_check(terrain_shape != null, "terrain has no exact triangle collision")
		if terrain_shape:
			_check(terrain_shape.get_faces().size() >= 12000, "terrain triangle collision is incomplete")
			_check(terrain_shape.backface_collision, "terrain collision can drop the player through triangle backs")
		_check(is_zero_approx(terrain.call("_garage_terrain_influence", 7.1, -43.0)), "terrain is not flat under the garage")
		_check(terrain.call("_edge_rise", 58.9, 0.0) > 2.0, "terrain edges are not raised enough")

	# Вертикальный луч в центре карты обязан попасть именно в новый TerrainBody.
	var ray := PhysicsRayQueryParameters3D.create(Vector3(0, 5, 0), Vector3(0, -5, 0))
	ray.exclude = [player.get_rid()]
	var floor_hit := main.get_world_3d().direct_space_state.intersect_ray(ray)
	_check(not floor_hit.is_empty(), "terrain is missing from the physics world")
	if not floor_hit.is_empty():
		_check(floor_hit["collider"] == terrain.get_node("TerrainBody"), "the terrain ray hit an unexpected collider")

	# Импортированные GLB-модели должны получить физические StaticBody3D.
	_check(_count_static_bodies(main.get_node("Sketchfab_Scene")) > 0, "stone meshes have no generated collision")
	_check(_count_static_bodies(main.get_node("garage")) > 0, "garage meshes have no generated collision")
	_check(_count_static_bodies(main.get_node("GarageGate")) > 0, "gate meshes have no generated collision")

	# При приседании высота капсулы уменьшается до заданного значения.
	Input.action_press("crouch")
	player.call("_update_crouch", 1.0)
	Input.action_release("crouch")
	_check(is_equal_approx(player_shape.height, 1.0), "crouching does not resize the capsule")

	# Искусственный потолок проверяет запрет вставания в тесном месте.
	var ceiling := StaticBody3D.new()
	var ceiling_collision := CollisionShape3D.new()
	var ceiling_shape := BoxShape3D.new()
	ceiling_shape.size = Vector3(1.0, 0.2, 1.0)
	ceiling_collision.shape = ceiling_shape
	ceiling.add_child(ceiling_collision)
	main.add_child(ceiling)
	ceiling.global_position = player.global_position + Vector3.UP * 0.65
	await physics_frame

	Input.action_press("crouch")
	player.call("_update_crouch", 1.0)
	Input.action_release("crouch")
	player.call("_update_crouch", 1.0)
	_check(player.get("is_crouching") == true, "player can stand inside a ceiling")
	_check(is_equal_approx(player_shape.height, 1.0), "ceiling check expands the capsule")

	Input.action_release("crouch")
	main.queue_free()
	await process_frame
	_finish()


# Рекурсивно считает StaticBody3D внутри импортированной модели.
func _count_static_bodies(node: Node) -> int:
	var count := 1 if node is StaticBody3D else 0
	for child in node.get_children():
		count += _count_static_bodies(child)
	return count


# Записывает сообщение, если условие не выполнено.
func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


# Печатает итог и возвращает операционной системе код результата.
func _finish() -> void:
	if failures.is_empty():
		print("Collision smoke test passed")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
