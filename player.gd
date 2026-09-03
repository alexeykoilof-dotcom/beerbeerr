extends CharacterBody3D

signal inventory_changed
signal inventory_full

const HOTBAR_SIZE := 4
const STORAGE_SIZE := 8

@export_group("Скорость движения")
@export_range(1.0, 12.0, 0.1) var walk_speed := 6.4
@export_range(1.0, 16.0, 0.1) var sprint_speed := 10.0
@export_range(1.0, 8.0, 0.1) var crouch_speed := 3.6
@export_range(1.0, 60.0, 0.5) var ground_acceleration := 42.0
@export_range(1.0, 60.0, 0.5) var ground_deceleration := 38.0
@export_range(0.1, 30.0, 0.1) var air_acceleration := 8.5
@export_range(1.0, 3.0, 0.05) var reverse_acceleration_multiplier := 1.45

@export_group("Прыжок и гравитация")
@export_range(1.0, 12.0, 0.1) var jump_velocity := 5.8
@export_range(0.1, 3.0, 0.05) var gravity_multiplier := 1.35
@export_range(0.0, 0.3, 0.01) var coyote_time := 0.12
@export_range(0.0, 0.3, 0.01) var jump_buffer_time := 0.12
@export_range(0.1, 1.0, 0.05) var short_jump_multiplier := 0.55

@export_group("Размер персонажа")
@export_range(0.1, 1.0, 0.01) var player_radius := 0.35
@export_range(1.0, 3.0, 0.05) var standing_height := 1.8
@export_range(0.5, 2.0, 0.05) var crouching_height := 1.0
@export_range(0.5, 20.0, 0.5) var crouch_transition_speed := 12.0

@export_group("Физичность камеры")
@export_range(0.0005, 0.01, 0.0001) var mouse_sensitivity := 0.002
@export_range(0.2, 2.0, 0.05) var standing_camera_height := 0.8
@export_range(0.1, 1.5, 0.05) var crouching_camera_height := 0.45
@export_range(0.1, 1.5, 0.05) var sitting_camera_height := 0.55
@export_range(0.0, 0.12, 0.005) var walk_bob_amount := 0.02
@export_range(0.0, 0.16, 0.005) var sprint_bob_amount := 0.035
@export_range(1.0, 20.0, 0.5) var bob_frequency := 11.5
@export_range(1.0, 30.0, 0.5) var camera_smoothing := 16.0
@export_range(0.0, 0.2, 0.01) var landing_bob_amount := 0.055
@export_range(60.0, 100.0, 0.5) var base_fov := 75.0
@export_range(1.0, 20.0, 0.5) var fov_smoothing := 8.0

@export_group("Взаимодействие")
@export_range(1.0, 10.0, 0.1) var interaction_distance := 4.0
# Слой 1 обязателен: ближайшая стена должна остановить луч и не дать взять
# предмет на слое 2 через гараж, чан или другое препятствие.
@export_flags_3d_physics var interaction_mask := 1 | 2 | 4

@export_group("Предмет в руках")
@export_range(0.5, 3.0, 0.05) var held_item_distance := 1.15
@export_range(4.0, 20.0, 0.5) var throw_speed := 10.0
@export_range(8.0, 30.0, 0.5) var maximum_charged_throw_speed := 20.0
@export_range(0.1, 1.0, 0.05) var strong_throw_hold_time := 0.4
@export_range(0.5, 3.0, 0.1) var maximum_throw_charge_time := 1.5
@export_range(0.5, 2.0, 0.05) var place_item_distance := 0.9
@export_range(1.0, 120.0, 1.0) var hold_spring_strength := 55.0
@export_range(1.0, 30.0, 0.5) var hold_spring_damping := 9.0
@export_range(1.0, 30.0, 0.5) var hold_max_speed := 12.0
@export_range(0.5, 2.0, 0.05) var blocked_item_drop_distance := 1.0
@export_range(0.05, 0.5, 0.01) var blocked_item_drop_delay := 0.15
@export_range(0.1, 1.5, 0.05) var blocked_item_pickup_grace := 0.75
@export_range(0.0, 8.0, 0.1) var body_push_strength := 2.0

@export_group("Удар")
@export_range(0.1, 1.0, 0.05) var punch_distance := 0.45
@export_range(0.03, 0.3, 0.01) var punch_speed := 0.08
@export_range(0.03, 0.3, 0.01) var punch_return_speed := 0.13

@onready var camera: Camera3D = $Camera3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var hands: Node3D = $Camera3D/PlayerHands
@onready var right_arm: Node3D = $Camera3D/PlayerHands/RightArm

@onready var crosshair: Label = get_tree().get_first_node_in_group("interaction_crosshair") as Label
@onready var interaction_prompt: Label = get_tree().get_first_node_in_group("interaction_prompt") as Label

var is_crouching := false
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var bob_time := 0.0
var landing_offset := 0.0

var is_sitting := false
var sitting_seat_point: Node3D
var sitting_exit_point: Node3D

var held_item: RigidBody3D
var held_item_gravity_scale := 1.0
var held_item_linear_damp := 0.0
var held_item_angular_damp := 0.0
var held_item_collision_layer := 0
var held_item_collision_mask := 0
var held_item_blocked_time := 0.0
var held_item_drop_armed := false
var held_item_pickup_grace_left := 0.0

# Четыре физических предмета быстрого инвентаря. Неактивные предметы остаются
# в мире как узлы, но временно скрыты и отключены от физики.
var inventory_slots: Array[RigidBody3D] = [null, null, null, null]
var storage_slots: Array[RigidBody3D] = [null, null, null, null, null, null, null, null]
var selected_inventory_slot := 0
var inventory_item_states: Dictionary = {}
var beers_drank := 0
var item_action_message := ""
var item_action_message_until := 0
var drop_charge_started_ms := -1
var drinking_from_mug := false

# Удар
var right_arm_start: Vector3
var punching := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	floor_snap_length = 0.25
	safe_margin = 0.03

	var shape := collision.shape as CapsuleShape3D
	shape.radius = player_radius
	shape.height = standing_height
	collision.position = Vector3.ZERO

	right_arm_start = right_arm.position
	camera.fov = base_fov
	Localization.language_changed.connect(_on_language_changed)
	inventory_changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var slot_index := _slot_index_from_key(event.physical_keycode)
		if slot_index >= 0:
			select_inventory_slot(slot_index)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))

	if event.is_action_pressed("drop_item"):
		_begin_drop_item_charge()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_released("drop_item"):
		_finish_drop_item_charge()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		if is_sitting:
			_stand_up_from_bench()
		else:
			_interact_with_ingredient()

		get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			_punch()


func _physics_process(delta: float) -> void:
	if is_sitting:
		_update_sitting_pose(delta)
		_update_interaction_hud()
		return

	var was_on_floor := is_on_floor()
	_update_jump_timers(delta, was_on_floor)

	if not was_on_floor:
		velocity += get_gravity() * gravity_multiplier * delta

	_try_to_jump()
	_update_horizontal_movement(delta, was_on_floor)
	_update_crouch(delta)
	_update_held_item_physics(delta)

	var falling_speed := velocity.y

	move_and_slide()
	_push_touched_rigid_bodies()

	if not was_on_floor and is_on_floor() and falling_speed < -2.0:
		landing_offset = minf((-falling_speed - 2.0) * 0.018, landing_bob_amount)

	_update_camera_effects(delta)
	_update_interaction_hud()


func _update_jump_timers(delta: float, on_floor: bool) -> void:
	if on_floor:
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)


func _try_to_jump() -> void:
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= short_jump_multiplier


func _update_horizontal_movement(delta: float, on_floor: bool) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var target_speed := walk_speed

	if is_crouching:
		target_speed = crouch_speed
	elif Input.is_action_pressed("sprint") and input_dir.y < 0.1:
		target_speed = sprint_speed

	var target_velocity := Vector2(direction.x, direction.z) * target_speed
	var horizontal_velocity := Vector2(velocity.x, velocity.z)
	var acceleration := air_acceleration

	if on_floor:
		acceleration = ground_acceleration if not direction.is_zero_approx() else ground_deceleration

		if not direction.is_zero_approx() and horizontal_velocity.dot(target_velocity) < 0.0:
			acceleration *= reverse_acceleration_multiplier

	horizontal_velocity = horizontal_velocity.move_toward(target_velocity, acceleration * delta)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.y


func _update_crouch(delta: float) -> void:
	var wants_to_crouch := Input.is_action_pressed("crouch")

	if wants_to_crouch:
		is_crouching = true
	elif is_crouching and _can_stand_up():
		is_crouching = false

	var shape := collision.shape as CapsuleShape3D
	var target_height := crouching_height if is_crouching else standing_height
	var target_center_y := -(standing_height - target_height) * 0.5

	shape.height = move_toward(shape.height, target_height, crouch_transition_speed * delta)
	collision.position.y = -(standing_height - shape.height) * 0.5

	if is_equal_approx(shape.height, target_height):
		collision.position.y = target_center_y


func _can_stand_up() -> bool:
	var standing_shape := CapsuleShape3D.new()
	standing_shape.radius = player_radius
	standing_shape.height = standing_height

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = standing_shape
	query.transform = Transform3D(
		global_basis.orthonormalized(),
		global_position + up_direction.normalized() * safe_margin
	)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.margin = 0.0

	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _update_camera_effects(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var movement_ratio := clampf(horizontal_speed / maxf(sprint_speed, 0.01), 0.0, 1.0)
	var moving_on_floor := is_on_floor() and horizontal_speed > 0.15

	if moving_on_floor:
		bob_time += delta * bob_frequency * lerpf(0.85, 1.35, movement_ratio)

	var bob_amount := sprint_bob_amount if horizontal_speed > walk_speed + 0.5 else walk_bob_amount
	var bob := Vector3.ZERO

	if moving_on_floor:
		bob.x = cos(bob_time * 0.5) * bob_amount * 0.45
		bob.y = sin(bob_time) * bob_amount

	landing_offset = move_toward(
		landing_offset,
		0.0,
		camera_smoothing * delta * landing_bob_amount
	)

	var base_height := crouching_camera_height if is_crouching else standing_camera_height
	camera.position = camera.position.lerp(
		Vector3(bob.x, base_height + bob.y - landing_offset, 0.0),
		1.0 - exp(-camera_smoothing * delta)
	)
	# FOV остаётся постоянным: взятие предмета после бега больше не выглядит
	# как приближение камеры.
	_smooth_camera_fov(delta, base_fov)
	camera.rotation.z = 0.0
	_update_hands_motion(delta, horizontal_speed, is_on_floor())


func _smooth_camera_fov(delta: float, target_fov: float) -> void:
	camera.fov = lerpf(camera.fov, target_fov, 1.0 - exp(-fov_smoothing * delta))


func _update_hands_motion(delta: float, horizontal_speed: float, on_floor: bool) -> void:
	if hands.has_method("update_from_player"):
		hands.call("update_from_player", delta, horizontal_speed, sprint_speed, on_floor)


func _push_touched_rigid_bodies() -> void:
	for collision_index in get_slide_collision_count():
		var slide_collision := get_slide_collision(collision_index)
		var body := slide_collision.get_collider() as RigidBody3D

		if body == null or body == held_item or body.freeze:
			continue

		var push_direction := -slide_collision.get_normal()
		push_direction.y = 0.0

		if push_direction.is_zero_approx():
			continue

		var impulse_strength := minf(
			Vector2(velocity.x, velocity.z).length() * body_push_strength,
			8.0
		)

		body.apply_central_impulse(
			push_direction.normalized() * impulse_strength * body.mass
		)


# Возвращает номер быстрого слота для клавиш 1–4.
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


# Публичный интерфейс: четыре активных слота и восемь складских.
func get_inventory_slots() -> Array[RigidBody3D]:
	_clean_invalid_inventory_items()
	return inventory_slots.duplicate()


func get_storage_slots() -> Array[RigidBody3D]:
	_clean_invalid_inventory_items()
	return storage_slots.duplicate()


func get_slot_item_name(slot_group: String, slot_index: int) -> String:
	var item := _get_inventory_slot_item(slot_group, slot_index)
	return _item_display_name(item) if is_instance_valid(item) else ""


func inventory_slot_has_item(slot_group: String, slot_index: int) -> bool:
	return is_instance_valid(_get_inventory_slot_item(slot_group, slot_index))


func select_inventory_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= HOTBAR_SIZE:
		return
	_clean_invalid_inventory_items()
	if slot_index == selected_inventory_slot and is_instance_valid(held_item):
		inventory_changed.emit()
		return

	_stash_held_item()
	selected_inventory_slot = slot_index
	_equip_selected_inventory_item()
	inventory_changed.emit()


func move_inventory_item(source_group: String, source_index: int, target_group: String, target_index: int) -> void:
	if not _is_valid_inventory_slot(source_group, source_index):
		return
	if not _is_valid_inventory_slot(target_group, target_index):
		return
	if source_group == target_group and source_index == target_index:
		return
	_clean_invalid_inventory_items()
	_stash_held_item()
	var source_item := _get_inventory_slot_item(source_group, source_index)
	var target_item := _get_inventory_slot_item(target_group, target_index)
	_set_inventory_slot_item(source_group, source_index, target_item)
	_set_inventory_slot_item(target_group, target_index, source_item)
	_equip_selected_inventory_item()
	inventory_changed.emit()


func _is_valid_inventory_slot(slot_group: String, slot_index: int) -> bool:
	return (
		(slot_group == "hotbar" and slot_index >= 0 and slot_index < HOTBAR_SIZE)
		or (slot_group == "storage" and slot_index >= 0 and slot_index < STORAGE_SIZE)
	)


func _get_inventory_slot_item(slot_group: String, slot_index: int) -> RigidBody3D:
	if not _is_valid_inventory_slot(slot_group, slot_index):
		return null
	return inventory_slots[slot_index] if slot_group == "hotbar" else storage_slots[slot_index]


func _set_inventory_slot_item(slot_group: String, slot_index: int, item: RigidBody3D) -> void:
	if slot_group == "hotbar":
		inventory_slots[slot_index] = item
	else:
		storage_slots[slot_index] = item


func _interact_with_ingredient() -> void:
	if is_instance_valid(held_item):
		var held_result := _cast_interaction_ray()
		if not held_result.is_empty():
			var held_target := held_result["collider"] as CollisionObject3D
			if held_target and held_target.has_method("interact_with_item"):
				if bool(held_target.call("interact_with_item", self, held_item)):
					return
		if held_item.has_method("use_in_hand"):
			if not _held_item_is_at_hand():
				return
			if bool(held_item.call("use_in_hand", self)):
				return
		return

	var result := _cast_interaction_ray()

	if result.is_empty():
		return

	var collider := result["collider"] as CollisionObject3D

	if collider and collider.has_method("interact"):
		collider.call("interact", self)
		return

	var body := collider as RigidBody3D

	if _is_pickup_item(body):
		_pick_up_item(body)


func _cast_interaction_ray() -> Dictionary:
	var from := camera.global_position
	var to := from - camera.global_basis.z * interaction_distance
	var query := PhysicsRayQueryParameters3D.create(from, to, interaction_mask)

	query.exclude = [get_rid()]

	return get_world_3d().direct_space_state.intersect_ray(query)


func _update_interaction_hud() -> void:
	if interaction_prompt == null or crosshair == null:
		return

	var modal_dialogue := get_tree().get_first_node_in_group("modal_dialogue") as Control

	if modal_dialogue and modal_dialogue.visible:
		_hide_interaction_prompt()
		return

	if Time.get_ticks_msec() < item_action_message_until:
		_show_interaction_prompt(item_action_message)
		return

	if is_sitting:
		_show_interaction_prompt(Localization.get_text("interaction.stand"))
		return

	if is_instance_valid(held_item):
		var held_action_text := _held_item_action_text()
		if drop_charge_started_ms >= 0:
			held_action_text = Localization.get_text("interaction.charge_release")
		_show_interaction_prompt(
			held_action_text if not held_action_text.is_empty()
			else Localization.get_text("interaction.place_throw")
		)
		return

	var result := _cast_interaction_ray()

	if result.is_empty():
		_hide_interaction_prompt()
		return

	var collider := result["collider"] as CollisionObject3D
	var prompt_text := _interaction_text_for(collider)

	if prompt_text.is_empty():
		_hide_interaction_prompt()
		return

	_show_interaction_prompt(prompt_text)


func _interaction_text_for(collider: CollisionObject3D) -> String:
	if collider == null:
		return ""

	if collider.has_method("get_interaction_text"):
		return String(collider.call("get_interaction_text"))

	var body := collider as RigidBody3D

	if _is_pickup_item(body):
		return Localization.get_text("interaction.pickup", [_item_display_name(body)])

	if collider.has_method("interact"):
		return Localization.get_text("interaction.generic")

	return ""


func _held_item_action_text() -> String:
	var result := _cast_interaction_ray()
	if not result.is_empty():
		var target := result["collider"] as CollisionObject3D
		if target and target.has_method("get_item_interaction_text"):
			var target_text := String(target.call("get_item_interaction_text", held_item))
			if not target_text.is_empty():
				return target_text
	if held_item.has_method("get_use_in_hand_text"):
		return String(held_item.call("get_use_in_hand_text"))
	return ""


func notify_inventory_changed() -> void:
	inventory_changed.emit()


func drink_from_mug(mug: RigidBody3D) -> void:
	if drinking_from_mug or mug != held_item or not is_instance_valid(mug):
		return
	if not _held_item_is_at_hand():
		return
	drinking_from_mug = true
	drop_charge_started_ms = -1
	mug.freeze = true
	mug.linear_velocity = Vector3.ZERO
	mug.angular_velocity = Vector3.ZERO

	# Глобальные конечные точки нельзя вычислять один раз: если игрок побежит,
	# камера уйдёт, а кружка останется в старой точке мира. На время питья делаем
	# кружку дочерней камере и анимируем локально — теперь она повторяет любое
	# движение и вращение персонажа автоматически.
	var original_parent := mug.get_parent()
	var original_top_level := mug.top_level
	mug.top_level = false
	mug.reparent(camera, true)
	var return_transform := Transform3D(Basis.IDENTITY, Vector3(0.0, -0.12, -held_item_distance))
	# Сбрасываем возможное отставание физической пружины до начала tween.
	# Иначе при резком беге анимация несколько кадров догоняла бы камеру издалека.
	mug.transform = return_transform
	var tilted_basis := Basis.IDENTITY.rotated(Vector3.RIGHT, deg_to_rad(68.0))
	var drink_transform := Transform3D(tilted_basis, Vector3(0.12, -0.04, -0.34))

	var tween := create_tween()
	tween.bind_node(mug)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(mug, "transform", drink_transform, 0.28)
	tween.tween_interval(0.22)
	tween.tween_callback(func():
		if is_instance_valid(mug) and mug.has_method("consume_beer"):
			mug.call("consume_beer", self)
		drink_beer()
	)
	tween.tween_property(mug, "transform", return_transform, 0.3)
	await tween.finished

	if is_instance_valid(mug) and mug == held_item:
		if is_instance_valid(original_parent):
			mug.reparent(original_parent, true)
		else:
			mug.reparent(get_parent(), true)
		mug.top_level = original_top_level
		mug.global_position = camera.global_position - camera.global_basis.z * held_item_distance + Vector3.DOWN * 0.12
		mug.global_rotation = Vector3(0.0, camera.global_rotation.y, 0.0)
		mug.freeze = false
		mug.sleeping = false
		mug.linear_velocity = velocity
		mug.angular_velocity = Vector3.ZERO
	drinking_from_mug = false


func drink_beer() -> void:
	beers_drank += 1
	show_action_message(Localization.get_text("message.beer_drunk"), 1400)


func show_action_message(message: String, duration_ms: int = 1000) -> void:
	item_action_message = message
	item_action_message_until = Time.get_ticks_msec() + duration_ms


func _show_interaction_prompt(text: String) -> void:
	interaction_prompt.text = text
	interaction_prompt.show()
	# Подсветка прицела остаётся белой, как рамки инвентаря и новой подсказки.
	crosshair.modulate = Color(1.0, 1.0, 1.0, 0.96)
	crosshair.scale = Vector2(1.12, 1.12)


func _hide_interaction_prompt() -> void:
	interaction_prompt.hide()
	crosshair.modulate = Color.WHITE
	crosshair.scale = Vector2.ONE


func _is_pickup_item(body: RigidBody3D) -> bool:
	return body != null and (
		body.is_in_group("brew_ingredient")
		or body.is_in_group("pickup_object")
	)


func _item_display_name(body: RigidBody3D) -> String:
	if body == null:
		return Localization.get_text("item.generic")

	if body.has_meta("item_key"):
		return Localization.get_text(String(body.get_meta("item_key")))

	if body.has_meta("ingredient_key"):
		return Localization.get_text(String(body.get_meta("ingredient_key")))

	var ingredient_id := String(body.get_meta("ingredient_id", ""))
	if ingredient_id in ["malt", "hops", "yeast"]:
		return Localization.get_text("ingredient." + ingredient_id)

	if body.has_meta("item_name"):
		return Localization.translate_source(String(body.get_meta("item_name")))

	return Localization.translate_source(String(body.get_meta(
		"ingredient_name",
		Localization.get_text("item.generic")
	)))


func _on_language_changed(_language_code: String) -> void:
	inventory_changed.emit()


func _pick_up_item(body: RigidBody3D) -> void:
	if body == null or not is_instance_valid(body):
		return

	_clean_invalid_inventory_items()
	if inventory_slots.find(body) >= 0 or storage_slots.find(body) >= 0:
		return

	var target_slot := selected_inventory_slot
	if is_instance_valid(inventory_slots[target_slot]):
		target_slot = _first_empty_hotbar_slot()
	if target_slot < 0:
		inventory_full.emit()
		return

	_capture_inventory_item_state(body)
	inventory_slots[target_slot] = body
	_stash_held_item()
	selected_inventory_slot = target_slot
	_equip_selected_inventory_item(false)
	inventory_changed.emit()


func _pick_up_ingredient(body: RigidBody3D) -> void:
	_pick_up_item(body)


func _first_empty_hotbar_slot() -> int:
	for slot_index in HOTBAR_SIZE:
		if not is_instance_valid(inventory_slots[slot_index]):
			return slot_index
	return -1


func _capture_inventory_item_state(item: RigidBody3D) -> void:
	var item_id := item.get_instance_id()
	if inventory_item_states.has(item_id):
		return
	inventory_item_states[item_id] = {
		"gravity_scale": item.gravity_scale,
		"linear_damp": item.linear_damp,
		"angular_damp": item.angular_damp,
		"collision_layer": item.collision_layer,
		"collision_mask": item.collision_mask,
		"visible": item.visible,
		"axis_lock_angular_x": item.axis_lock_angular_x,
		"axis_lock_angular_y": item.axis_lock_angular_y,
		"axis_lock_angular_z": item.axis_lock_angular_z,
		"contact_monitor": item.contact_monitor,
		"max_contacts_reported": item.max_contacts_reported,
	}


func _equip_selected_inventory_item(move_to_hand: bool = true) -> void:
	var item := inventory_slots[selected_inventory_slot]
	if not is_instance_valid(item):
		held_item = null
		return

	var state: Dictionary = inventory_item_states.get(item.get_instance_id(), {})
	held_item = item
	held_item_gravity_scale = float(state.get("gravity_scale", item.gravity_scale))
	held_item_linear_damp = float(state.get("linear_damp", item.linear_damp))
	held_item_angular_damp = float(state.get("angular_damp", item.angular_damp))
	held_item_collision_layer = int(state.get("collision_layer", item.collision_layer))
	held_item_collision_mask = int(state.get("collision_mask", item.collision_mask))
	held_item_blocked_time = 0.0
	held_item_drop_armed = move_to_hand
	held_item_pickup_grace_left = 0.0 if move_to_hand else blocked_item_pickup_grace

	item.visible = true
	item.freeze = false
	item.sleeping = false
	item.gravity_scale = 0.25
	item.linear_damp = 1.5
	item.angular_damp = 5.0
	item.continuous_cd = true
	item.contact_monitor = true
	item.max_contacts_reported = maxi(item.max_contacts_reported, 4)
	item.collision_layer = 0
	item.collision_mask = 3 if item.is_in_group("pickup_object") else 1
	item.add_collision_exception_with(self)
	if move_to_hand:
		item.global_position = camera.global_position - camera.global_basis.z * held_item_distance + Vector3.DOWN * 0.12
	if bool(item.get_meta("hold_upright", false)):
		# Для кружки не используем физическую пружину вращения: при контакте со
		# стеной она раскачивала тело и могла накопить огромную угловую скорость.
		# Наклон блокируется только на время удержания, а после отпускания исходные
		# ограничения тела восстанавливаются в _release_held_item().
		item.global_rotation = Vector3(0.0, camera.global_rotation.y, 0.0)
		item.axis_lock_angular_x = true
		item.axis_lock_angular_y = true
		item.axis_lock_angular_z = true
	item.linear_velocity = velocity
	item.angular_velocity = Vector3.ZERO


func _stash_held_item() -> void:
	if not is_instance_valid(held_item):
		held_item = null
		return

	var item := held_item
	held_item = null
	held_item_blocked_time = 0.0
	held_item_drop_armed = false
	held_item_pickup_grace_left = 0.0
	_stash_inventory_item(item)


func _stash_inventory_item(item: RigidBody3D) -> void:
	if not is_instance_valid(item):
		return
	item.remove_collision_exception_with(self)
	item.linear_velocity = Vector3.ZERO
	item.angular_velocity = Vector3.ZERO
	item.collision_layer = 0
	item.collision_mask = 0
	item.freeze = true
	item.sleeping = true
	item.visible = false


func _clean_invalid_inventory_items() -> void:
	var changed := false
	for slot_index in HOTBAR_SIZE:
		if inventory_slots[slot_index] != null and not is_instance_valid(inventory_slots[slot_index]):
			inventory_slots[slot_index] = null
			changed = true
	for slot_index in STORAGE_SIZE:
		if storage_slots[slot_index] != null and not is_instance_valid(storage_slots[slot_index]):
			storage_slots[slot_index] = null
			changed = true
	if held_item != null and not is_instance_valid(held_item):
		held_item = null
		changed = true
	if changed:
		inventory_changed.emit()


func sit_on_bench(seat_point: Node3D, exit_point: Node3D) -> void:
	if is_sitting or seat_point == null:
		return

	is_sitting = true
	is_crouching = false
	sitting_seat_point = seat_point
	sitting_exit_point = exit_point

	velocity = Vector3.ZERO
	global_transform = seat_point.global_transform
	camera.rotation.x = 0.0
	collision.disabled = true


func _stand_up_from_bench() -> void:
	if not is_sitting:
		return

	var exit_transform := global_transform

	if is_instance_valid(sitting_exit_point):
		exit_transform = sitting_exit_point.global_transform

	is_sitting = false
	sitting_seat_point = null
	sitting_exit_point = null

	global_transform = exit_transform
	velocity = Vector3.ZERO
	collision.disabled = false


func _update_sitting_pose(delta: float) -> void:
	if not is_instance_valid(sitting_seat_point):
		_stand_up_from_bench()
		return

	global_position = sitting_seat_point.global_position
	velocity = Vector3.ZERO

	camera.position = camera.position.lerp(
		Vector3(0.0, sitting_camera_height, 0.0),
		1.0 - exp(-camera_smoothing * delta)
	)
	_smooth_camera_fov(delta, base_fov)
	camera.rotation.z = 0.0
	_update_hands_motion(delta, 0.0, true)


func _update_held_item_physics(delta: float) -> void:
	if not is_instance_valid(held_item):
		held_item_blocked_time = 0.0
		held_item_drop_armed = false
		held_item_pickup_grace_left = 0.0
		_clean_invalid_inventory_items()
		return
	if drinking_from_mug:
		held_item_blocked_time = 0.0
		return

	var target := _held_item_target_position()
	var offset := target - held_item.global_position
	var relative_velocity := held_item.linear_velocity - velocity

	var spring_force := (
		offset * hold_spring_strength
		- relative_velocity * hold_spring_damping
	) * held_item.mass

	held_item.apply_central_force(spring_force)

	if held_item.linear_velocity.length() > hold_max_speed:
		held_item.linear_velocity = held_item.linear_velocity.limit_length(hold_max_speed)

	# При первом E предмет сначала должен спокойно оторваться от полки или пола.
	# После первого прихода к руке защита включается до конца удержания.
	if not held_item_drop_armed:
		held_item_pickup_grace_left = maxf(held_item_pickup_grace_left - delta, 0.0)
		if offset.length() < blocked_item_drop_distance or held_item_pickup_grace_left <= 0.0:
			held_item_drop_armed = true
		else:
			return

	# Само столкновение предмет не отпускает. Он выпадает только тогда, когда
	# остаётся за препятствием, а игрок отходит от точки удержания примерно на метр.
	var blocked := (
		offset.length() >= blocked_item_drop_distance
		and _held_item_has_blocking_contact(target)
	)
	if blocked:
		held_item_blocked_time += delta
		if held_item_blocked_time >= blocked_item_drop_delay:
			_drop_blocked_held_item()
	else:
		held_item_blocked_time = 0.0


func _held_item_has_blocking_contact(target: Vector3) -> bool:
	if not held_item.get_colliding_bodies().is_empty():
		return true
	# Луч закрывает редкий случай, когда тонкая стена уже разделяет руку и
	# предмет, но движок ещё не успел зарегистрировать контакт в мониторе тела.
	var query := PhysicsRayQueryParameters3D.create(held_item.global_position, target, 1)
	query.exclude = [get_rid(), held_item.get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _held_item_target_position() -> Vector3:
	return camera.global_position - camera.global_basis.z * held_item_distance + Vector3.DOWN * 0.12


func _held_item_is_at_hand() -> bool:
	if not is_instance_valid(held_item):
		return false
	if drinking_from_mug:
		return true
	# Использовать кружку можно только рядом с рукой. Это отдельный малый порог:
	# большой метровый порог отвечает лишь за автоматическое выпадение.
	return held_item.global_position.distance_to(_held_item_target_position()) <= 0.35


func _drop_blocked_held_item() -> void:
	if not is_instance_valid(held_item) or drinking_from_mug:
		return
	drop_charge_started_ms = -1
	item_action_message = Localization.get_text("message.item_fell")
	item_action_message_until = Time.get_ticks_msec() + 900
	_release_held_item(Vector3.ZERO, null, true)

func _begin_drop_item_charge() -> void:
	if is_instance_valid(held_item) and not drinking_from_mug:
		drop_charge_started_ms = Time.get_ticks_msec()


func _finish_drop_item_charge() -> void:
	if drop_charge_started_ms < 0:
		return
	var held_seconds := float(Time.get_ticks_msec() - drop_charge_started_ms) / 1000.0
	drop_charge_started_ms = -1
	if not is_instance_valid(held_item):
		return
	if held_seconds < strong_throw_hold_time:
		_place_held_item()
		return
	var charge_ratio := clampf(
		(held_seconds - strong_throw_hold_time)
		/ maxf(maximum_throw_charge_time - strong_throw_hold_time, 0.01),
		0.0,
		1.0
	)
	var charged_speed := lerpf(throw_speed, maximum_charged_throw_speed, charge_ratio)
	_throw_held_item(charged_speed, 1.0 + charge_ratio * 1.5)


func _place_held_item() -> void:
	var place_position := (
		camera.global_position
		- camera.global_basis.z * place_item_distance
		+ Vector3.DOWN * 0.42
	)
	_release_held_item(velocity * 0.25, place_position)


func _throw_held_item(speed: float = -1.0, upward_force: float = 1.0) -> void:
	if speed < 0.0:
		speed = throw_speed
	_release_held_item(
		velocity - camera.global_basis.z * speed + Vector3.UP * upward_force
	)


func _release_held_item(
	release_velocity: Vector3,
	place_position: Variant = null,
	preserve_current_position: bool = false
) -> void:
	if not is_instance_valid(held_item):
		_clean_invalid_inventory_items()
		return

	var item := held_item
	# Сначала вычисляем свободную точку, пока held_item ещё доступен функции
	# проверки. Это не даёт поставить или бросить предмет внутрь пола/стены.
	var desired_position := item.global_position
	if place_position is Vector3:
		desired_position = place_position
	var safe_position := (
		desired_position
		if preserve_current_position
		else _get_safe_release_position(item, desired_position)
	)

	held_item = null
	held_item_blocked_time = 0.0
	held_item_drop_armed = false
	held_item_pickup_grace_left = 0.0
	var item_slot := inventory_slots.find(item)
	if item_slot >= 0:
		inventory_slots[item_slot] = null
	var state: Dictionary = inventory_item_states.get(item.get_instance_id(), {})

	item.remove_collision_exception_with(self)
	item.visible = bool(state.get("visible", true))
	item.freeze = false
	item.collision_layer = int(state.get("collision_layer", held_item_collision_layer))
	item.collision_mask = int(state.get("collision_mask", held_item_collision_mask))

	if item.is_in_group("pickup_object"):
		item.collision_layer |= 2
		item.collision_mask |= 3

	item.gravity_scale = float(state.get("gravity_scale", held_item_gravity_scale))
	item.linear_damp = float(state.get("linear_damp", held_item_linear_damp))
	item.angular_damp = float(state.get("angular_damp", held_item_angular_damp))
	item.axis_lock_angular_x = bool(state.get("axis_lock_angular_x", false))
	item.axis_lock_angular_y = bool(state.get("axis_lock_angular_y", false))
	item.axis_lock_angular_z = bool(state.get("axis_lock_angular_z", false))
	item.contact_monitor = bool(state.get("contact_monitor", false))
	item.max_contacts_reported = int(state.get("max_contacts_reported", 0))
	item.sleeping = false
	inventory_item_states.erase(item.get_instance_id())

	item.global_position = safe_position
	# Никогда не переносим накопленное вращение из режима удержания в мир.
	# Именно оно вместе с CCD создавало тяжёлые зависания после удара о землю.
	item.angular_velocity = Vector3.ZERO
	item.linear_velocity = release_velocity if release_velocity.is_finite() else Vector3.ZERO
	inventory_changed.emit()


func _get_safe_release_position(item: RigidBody3D, desired_position: Vector3) -> Vector3:
	var origin := camera.global_position
	var direction := desired_position - origin
	if direction.length_squared() < 0.0001:
		return origin - camera.global_basis.z * 0.5

	var query := PhysicsRayQueryParameters3D.create(origin, desired_position, 1)
	query.exclude = [get_rid(), item.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return desired_position

	# Запас задаётся на предмете, чтобы крупному реквизиту можно было назначить
	# своё значение. Для кружки 28 см покрывают радиус коллайдера 24.5 см.
	var clearance := float(item.get_meta("release_clearance", 0.28))
	return Vector3(hit["position"]) + Vector3(hit["normal"]) * clearance


# ЛКМ — простой удар правой рукой.
func _punch() -> void:
	if punching:
		return

	punching = true

	var tween := create_tween()
	tween.tween_property(
		right_arm,
		"position",
		right_arm_start + Vector3(0.0, 0.0, -punch_distance),
		punch_speed
	)
	tween.tween_property(
		right_arm,
		"position",
		right_arm_start,
		punch_return_speed
	)

	await tween.finished
	punching = false
