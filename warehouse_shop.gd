@tool
extends Node3D

@export_range(1.0, 6.0, 0.1) var texture_tiling := 2.4
@export var mechanics_yard_path := NodePath("../MechanicsYard")


func _ready() -> void:
	_apply_smaller_textures()


# Стойка магазина использует тот же баланс денег и сырья, что учебная пивоварня.
func perform_action(action: int) -> void:
	if action != 0 or Engine.is_editor_hint():
		return
	var yard := get_node_or_null(mechanics_yard_path)
	if yard and yard.has_method("perform_action"):
		yard.call("perform_action", 0)


# У импортированного склада крупная каменная развёртка.
# Дублируем материалы только для этого экземпляра и повторяем рисунок чаще.
func _apply_smaller_textures() -> void:
	var source := get_node_or_null("SourceAsset")
	if source == null:
		return
	for candidate in source.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		for surface_index in mesh_instance.mesh.get_surface_count():
			var original := mesh_instance.get_active_material(surface_index)
			if original is StandardMaterial3D:
				var material := original.duplicate() as StandardMaterial3D
				material.uv1_scale = Vector3(texture_tiling, texture_tiling, texture_tiling)
				material.texture_repeat = true
				mesh_instance.set_surface_override_material(surface_index, material)
