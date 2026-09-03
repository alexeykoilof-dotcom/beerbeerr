@tool
extends Node3D

@export_group("Прямая дорога")
@export var start_point := Vector3(-17.0, -0.5, -22.9)
@export var end_point := Vector3(-22.5, -0.03, -7.43)
@export_range(3.0, 8.0, 0.1) var road_width := 4.8
@export_range(0.0, 2.0, 0.1) var shoulder_width := 0.7

@export_group("Материалы")
@export var road_material: Material
@export var line_material: Material
@export var shoulder_material: Material

@export_tool_button("Перестроить дорогу") var rebuild_button := _rebuild_route


func _ready() -> void:
	_rebuild_route()


func _rebuild_route() -> void:
	var road_mesh := get_node_or_null("RoadSurface") as MeshInstance3D
	var shoulder_mesh := get_node_or_null("Shoulders") as MeshInstance3D
	var left_line := get_node_or_null("LeftEdgeLine") as MeshInstance3D
	var right_line := get_node_or_null("RightEdgeLine") as MeshInstance3D
	var collision := get_node_or_null("RoadBody/Collision") as CollisionShape3D
	if road_mesh == null or shoulder_mesh == null or left_line == null or right_line == null or collision == null:
		return

	var road := _make_strip(road_width, 0.0, 0.0)
	var shoulders := _make_strip(road_width + shoulder_width * 2.0, 0.0, -0.025)
	var line_offset := road_width * 0.5 - 0.28
	var left := _make_strip(0.12, -line_offset, 0.018)
	var right := _make_strip(0.12, line_offset, 0.018)

	road.surface_set_material(0, road_material)
	shoulders.surface_set_material(0, shoulder_material)
	left.surface_set_material(0, line_material)
	right.surface_set_material(0, line_material)
	road_mesh.mesh = road
	shoulder_mesh.mesh = shoulders
	left_line.mesh = left
	right_line.mesh = right

	var shape := road.create_trimesh_shape() as ConcavePolygonShape3D
	shape.backface_collision = true
	collision.shape = shape


func _make_strip(width: float, lateral_offset: float, vertical_offset: float) -> ArrayMesh:
	var direction_2d := Vector2(end_point.x - start_point.x, end_point.z - start_point.z).normalized()
	var side := Vector2(-direction_2d.y, direction_2d.x)
	var center_offset := side * lateral_offset
	var half_side := side * width * 0.5
	var start_center := Vector3(start_point.x + center_offset.x, start_point.y + vertical_offset, start_point.z + center_offset.y)
	var end_center := Vector3(end_point.x + center_offset.x, end_point.y + vertical_offset, end_point.z + center_offset.y)
	var side_3d := Vector3(half_side.x, 0.0, half_side.y)

	var vertices := PackedVector3Array([
		start_center - side_3d,
		start_center + side_3d,
		end_center - side_3d,
		end_center + side_3d,
	])
	var distance := start_point.distance_to(end_point)
	var uvs := PackedVector2Array([
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(0, distance / 2.0),
		Vector2(1, distance / 2.0),
	])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([
		Vector3.UP,
		Vector3.UP,
		Vector3.UP,
		Vector3.UP,
	])
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	# В Godot лицевая сторона задаётся обходом по часовой стрелке.
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 2, 1, 1, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
