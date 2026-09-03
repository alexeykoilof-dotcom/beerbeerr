# Простой выключатель двух редактируемых потолочных ламп гаража.
extends StaticBody3D

@export var lights_path := NodePath("../../CeilingLights")
@export var starts_enabled := true

@onready var handle: Node3D = $"../Handle"
@onready var indicator: MeshInstance3D = $"../Indicator"

var lights_enabled := true
var controlled_lights: Array[Light3D] = []
var enabled_energies: Dictionary = {}
var indicator_material: StandardMaterial3D


func _ready() -> void:
	var lights_root := get_node_or_null(lights_path)
	if lights_root:
		for node in lights_root.find_children("*", "Light3D", true, false):
			var light := node as Light3D
			if light:
				controlled_lights.append(light)
				enabled_energies[light.get_instance_id()] = light.light_energy

	var source_material := indicator.material_override as StandardMaterial3D
	if source_material:
		indicator_material = source_material.duplicate() as StandardMaterial3D
		indicator.material_override = indicator_material

	lights_enabled = starts_enabled
	_apply_state()


func interact(player: CharacterBody3D) -> void:
	lights_enabled = not lights_enabled
	_apply_state()
	if player and player.has_method("show_action_message"):
		player.call(
			"show_action_message",
			Localization.get_text("light.enabled" if lights_enabled else "light.disabled")
		)


func get_interaction_text() -> String:
	return Localization.get_text("light.turn_off" if lights_enabled else "light.turn_on")


func _apply_state() -> void:
	for light in controlled_lights:
		if not is_instance_valid(light):
			continue
		var enabled_energy := float(enabled_energies.get(light.get_instance_id(), 2.0))
		light.light_energy = enabled_energy if lights_enabled else 0.0

	handle.rotation.z = deg_to_rad(-18.0 if lights_enabled else 18.0)
	if indicator_material:
		var color := Color(1.0, 0.72, 0.22, 1.0) if lights_enabled else Color(0.18, 0.2, 0.22, 1.0)
		indicator_material.albedo_color = color
		indicator_material.emission = color
		indicator_material.emission_energy_multiplier = 2.2 if lights_enabled else 0.0
