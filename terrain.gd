# Скрипт работает и в редакторе благодаря @tool: рельеф виден до запуска игры.
@tool
extends Node3D

# Размер сетки, число вершин и базовая высота всей земли.
@export_group("Размер и детализация")
@export var terrain_size := Vector2(117.9, 125.02)
@export_range(17, 129, 2) var resolution_x := 65
@export_range(17, 129, 2) var resolution_z := 69
@export var base_height := -0.43

# Два слоя шума создают крупные холмы и небольшие неровности.
@export_group("Форма рельефа")
@export var noise_seed := 7331
@export_range(0.001, 0.08, 0.001) var hill_frequency := 0.018
@export_range(0.0, 3.0, 0.05) var hill_height := 1.15
@export_range(0.0, 1.0, 0.01) var detail_height := 0.1

# Края карты поднимаются, чтобы визуально ограничить локацию.
@export_group("Выраженные края карты")
@export_range(0.4, 0.9, 0.01) var edge_rise_start := 0.62
@export_range(0.0, 6.0, 0.1) var edge_height := 2.6

# В этой большой области высота плавно сводится к base_height.
@export_group("Ровная площадка гаража")
@export var garage_flat_center := Vector2(7.1, -43.0)
@export var garage_flat_half_size := Vector2(15.0, 18.0)
@export_range(1.0, 20.0, 0.5) var garage_blend_distance := 8.0

# Дорога к складу остаётся прямой в плане, а по высоте плавно поднимается
# от существующего асфальта до порога здания. Земля под ней повторяет уклон.
@export_group("Дорога и площадка склада")
@export var warehouse_route_start := Vector3(-17.0, -0.4, -22.9)
@export var warehouse_route_end := Vector3(-22.5, 0.065, -7.43)
@export var warehouse_route_half_width := 2.85
@export var warehouse_route_blend_distance := 2.5
@export var warehouse_pad_center := Vector2(-26.4, -7.43)
@export var warehouse_pad_half_size := Vector2(4.3, 7.0)
@export var warehouse_pad_height := 0.065
@export var warehouse_pad_blend_distance := 2.5

# Внутри гаража геометрия остаётся на том же уровне, но получает материал без травы.
@export_group("Чистый пол внутри гаража")
@export var garage_floor_center := Vector2(7.12, -44.56)
@export var garage_floor_half_size := Vector2(6.2, 9.4)
@export var garage_floor_material: Material

# Основной материал травяного грунта.
@export_group("Внешний вид")
@export var terrain_material: Material

# Кнопка в Inspector позволяет вручную пересобрать меш после настройки параметров.
@export_tool_button("Перестроить рельеф") var rebuild_button := _rebuild_terrain


# При входе в дерево сцены строит визуальный меш и соответствующую коллизию.
func _ready() -> void:
	_rebuild_terrain()


# Полностью генерирует непрерывный рельеф из массива вершин.
func _rebuild_terrain() -> void:
	# Без этих двух заранее созданных узлов строить и отображать рельеф негде.
	var terrain_mesh := get_node_or_null("TerrainMesh") as MeshInstance3D
	var terrain_collision := get_node_or_null("TerrainBody/TerrainCollision") as CollisionShape3D
	if terrain_mesh == null or terrain_collision == null:
		return

	var width: int = maxi(resolution_x, 3)
	var depth: int = maxi(resolution_z, 3)
	var step_x: float = terrain_size.x / float(width - 1)
	var step_z: float = terrain_size.y / float(depth - 1)
	var heights := PackedFloat32Array()
	heights.resize(width * depth)

	# Первый шум отвечает за плавные крупные формы поверхности.
	var broad_noise := FastNoiseLite.new()
	broad_noise.seed = noise_seed
	broad_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	broad_noise.frequency = hill_frequency
	broad_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	broad_noise.fractal_octaves = 4
	broad_noise.fractal_lacunarity = 2.05
	broad_noise.fractal_gain = 0.5

	# Второй шум имеет большую частоту и добавляет мелкие естественные детали.
	var detail_noise := FastNoiseLite.new()
	detail_noise.seed = noise_seed + 917
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.frequency = hill_frequency * 4.6
	detail_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	detail_noise.fractal_octaves = 2
	detail_noise.fractal_gain = 0.45

	# Сначала отдельно вычисляем высоту каждой вершины сетки.
	for z_index in depth:
		var z: float = -terrain_size.y * 0.5 + float(z_index) * step_z
		for x_index in width:
			var x: float = -terrain_size.x * 0.5 + float(x_index) * step_x
			var broad: float = broad_noise.get_noise_2d(x + 173.4, z - 91.7)
			var detail: float = detail_noise.get_noise_2d(x - 64.2, z + 118.6)
			var rolling_height: float = broad * hill_height + detail * detail_height + _edge_rise(x, z)
			var garage_influence: float = _garage_terrain_influence(x, z)
			var natural_height := base_height + rolling_height * garage_influence
			heights[z_index * width + x_index] = _warehouse_terrain_height(x, z, natural_height)

	# Эти массивы являются стандартными каналами ArrayMesh в Godot.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	vertices.resize(width * depth)
	normals.resize(width * depth)
	uvs.resize(width * depth)

	# Заполняем позиции, UV-развёртку и нормали для корректного освещения.
	for z_index in depth:
		var z: float = -terrain_size.y * 0.5 + float(z_index) * step_z
		for x_index in width:
			var x: float = -terrain_size.x * 0.5 + float(x_index) * step_x
			var index: int = z_index * width + x_index
			vertices[index] = Vector3(x, heights[index], z)
			# Меньший делитель повторяет травяной рисунок чаще: детали текстуры
			# становятся меньше и не выглядят растянутыми возле длинной дороги.
			uvs[index] = Vector2(x / 4.0, z / 4.0)

			# Нормаль вычисляется по перепаду высот между соседними вершинами.
			var left_height: float = heights[z_index * width + maxi(x_index - 1, 0)]
			var right_height: float = heights[z_index * width + mini(x_index + 1, width - 1)]
			var back_height: float = heights[maxi(z_index - 1, 0) * width + x_index]
			var front_height: float = heights[mini(z_index + 1, depth - 1) * width + x_index]
			var slope_x: float = (right_height - left_height) / (2.0 * step_x)
			var slope_z: float = (front_height - back_height) / (2.0 * step_z)
			normals[index] = Vector3(-slope_x, 1.0, -slope_z).normalized()

	# Треугольники пола гаража отделяются от травы, чтобы назначить другой материал.
	var terrain_indices := PackedInt32Array()
	var garage_floor_indices := PackedInt32Array()
	for z_index in depth - 1:
		for x_index in width - 1:
			var top_left: int = z_index * width + x_index
			var top_right: int = top_left + 1
			var bottom_left: int = top_left + width
			var bottom_right: int = bottom_left + 1
			var cell_center_x: float = -terrain_size.x * 0.5 + (float(x_index) + 0.5) * step_x
			var cell_center_z: float = -terrain_size.y * 0.5 + (float(z_index) + 0.5) * step_z
			# В Godot лицевая сторона этих треугольников задаётся обходом по часовой стрелке.
			if _is_inside_garage_floor(cell_center_x, cell_center_z):
				garage_floor_indices.append_array([top_left, top_right, bottom_left, top_right, bottom_right, bottom_left])
			else:
				terrain_indices.append_array([top_left, top_right, bottom_left, top_right, bottom_right, bottom_left])

	# Собираем основной набор данных меша.
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = terrain_indices

	# Поверхность 0 — трава, поверхность 1 — чистый пол внутри гаража.
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if terrain_material:
		mesh.surface_set_material(0, terrain_material)
	if not garage_floor_indices.is_empty():
		var garage_arrays := arrays.duplicate()
		garage_arrays[Mesh.ARRAY_INDEX] = garage_floor_indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, garage_arrays)
		if garage_floor_material:
			mesh.surface_set_material(1, garage_floor_material)
	terrain_mesh.mesh = mesh
	# material_override отключён, иначе он заменил бы оба раздельных материала одним.
	terrain_mesh.material_override = null

	# Коллизия строится из тех же треугольников, что исключает ходьбу по воздуху
	# и несовпадение физической поверхности с видимым рельефом.
	terrain_collision.scale = Vector3.ONE
	var triangle_shape := mesh.create_trimesh_shape() as ConcavePolygonShape3D
	triangle_shape.backface_collision = true
	terrain_collision.shape = triangle_shape


# Возвращает дополнительную высоту для точки рядом с краями карты.
func _edge_rise(x: float, z: float) -> float:
	var normalized_x: float = absf(x) / (terrain_size.x * 0.5)
	var normalized_z: float = absf(z) / (terrain_size.y * 0.5)
	var edge_factor: float = maxf(normalized_x, normalized_z)
	var rise_factor: float = smoothstep(edge_rise_start, 1.0, edge_factor)
	return rise_factor * rise_factor * edge_height


# Возвращает 0 внутри ровной зоны гаража и плавно возрастает до 1 снаружи.
func _garage_terrain_influence(x: float, z: float) -> float:
	var outside_x: float = absf(x - garage_flat_center.x) - garage_flat_half_size.x
	var outside_z: float = absf(z - garage_flat_center.y) - garage_flat_half_size.y
	var distance_from_flat_area: float = maxf(outside_x, outside_z)
	if distance_from_flat_area <= 0.0:
		return 0.0
	return smoothstep(0.0, garage_blend_distance, distance_from_flat_area)


# Подводит землю под прямую дорогу и создаёт ровную площадку под складом.
# Высота дороги линейно меняется между двумя концами, поэтому нет ступеней.
func _warehouse_terrain_height(x: float, z: float, natural_height: float) -> float:
	var point := Vector2(x, z)
	var route_start := Vector2(warehouse_route_start.x, warehouse_route_start.z)
	var route_end := Vector2(warehouse_route_end.x, warehouse_route_end.z)
	var route_vector := route_end - route_start
	var route_length_squared := route_vector.length_squared()
	var route_t := 0.0
	if route_length_squared > 0.001:
		route_t = clampf((point - route_start).dot(route_vector) / route_length_squared, 0.0, 1.0)
	var closest_route_point := route_start + route_vector * route_t
	var distance_to_route := point.distance_to(closest_route_point)
	var route_influence := 1.0 - smoothstep(
		warehouse_route_half_width,
		warehouse_route_half_width + warehouse_route_blend_distance,
		distance_to_route
	)
	var route_height := lerpf(warehouse_route_start.y, warehouse_route_end.y, route_t)
	var shaped_height := lerpf(natural_height, route_height, route_influence)

	var outside_pad_x := absf(x - warehouse_pad_center.x) - warehouse_pad_half_size.x
	var outside_pad_z := absf(z - warehouse_pad_center.y) - warehouse_pad_half_size.y
	var distance_from_pad := maxf(outside_pad_x, outside_pad_z)
	var pad_influence := 1.0 - smoothstep(
		0.0,
		warehouse_pad_blend_distance,
		maxf(distance_from_pad, 0.0)
	)
	return lerpf(shaped_height, warehouse_pad_height, pad_influence)


# Определяет, должен ли квадрат сетки использовать чистый материал пола.
func _is_inside_garage_floor(x: float, z: float) -> bool:
	return (
		absf(x - garage_floor_center.x) <= garage_floor_half_size.x
		and absf(z - garage_floor_center.y) <= garage_floor_half_size.y
	)
