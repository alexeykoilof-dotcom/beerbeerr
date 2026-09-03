# Физический мини-тир: следит за тремя мишенями и возвращает их кнопкой E.
extends StaticBody3D

@export var targets_path := NodePath("../Targets")
@export var status_label_path := NodePath("../StatusLabel")
@export var status_light_path := NodePath("../StatusLight")
@export_range(0.1, 0.9, 0.05) var upright_threshold := 0.55

var targets: Array[RigidBody3D] = []
var initial_transforms: Dictionary = {}
var gallery_complete := false


func _ready() -> void:
	var targets_root := get_node_or_null(targets_path)
	if targets_root:
		for child in targets_root.get_children():
			var target := child as RigidBody3D
			if target:
				targets.append(target)
				initial_transforms[target.get_instance_id()] = target.transform
	_update_status(true)


func _physics_process(_delta: float) -> void:
	_update_status()


func interact(player: CharacterBody3D) -> void:
	reset_targets()
	if player and player.has_method("show_action_message"):
		player.call("show_action_message", Localization.get_text("gallery.restored"))


func get_interaction_text() -> String:
	return Localization.get_text("gallery.reset")


func reset_targets() -> void:
	for target in targets:
		if not is_instance_valid(target):
			continue
		target.freeze = true
		target.linear_velocity = Vector3.ZERO
		target.angular_velocity = Vector3.ZERO
		target.transform = initial_transforms[target.get_instance_id()]
		target.freeze = false
		target.sleeping = false
	gallery_complete = false
	_update_status(true)


func _update_status(force: bool = false) -> void:
	var is_complete := not targets.is_empty()
	for target in targets:
		if is_instance_valid(target) and not _target_is_down(target):
			is_complete = false
			break
	if not force and is_complete == gallery_complete:
		return
	gallery_complete = is_complete

	var label := get_node_or_null(status_label_path) as Label3D
	if label:
		label.text = Localization.get_text("gallery.complete" if gallery_complete else "gallery.goal")
		label.modulate = Color(0.45, 1.0, 0.48, 1.0) if gallery_complete else Color(1.0, 0.86, 0.48, 1.0)
	var status_light := get_node_or_null(status_light_path) as OmniLight3D
	if status_light:
		status_light.light_color = Color(0.35, 1.0, 0.4, 1.0) if gallery_complete else Color(1.0, 0.55, 0.16, 1.0)
		status_light.light_energy = 1.6 if gallery_complete else 0.65


func _target_is_down(target: RigidBody3D) -> bool:
	var initial_transform: Transform3D = initial_transforms.get(target.get_instance_id(), target.transform)
	var upright_amount := target.global_basis.y.normalized().dot(Vector3.UP)
	return (
		upright_amount < upright_threshold
		or target.position.y < initial_transform.origin.y - 0.4
	)
