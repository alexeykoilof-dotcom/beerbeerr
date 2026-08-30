# Автоматическая проверка новой физики персонажа: разгон, спринт и прыжок.
extends SceneTree

# Сообщения всех проваленных проверок.
var failures: Array[String] = []


# Запускает тест после инициализации дерева Godot.
func _init() -> void:
	call_deferred("_run")


# Создаёт реального игрока из main.tscn и вызывает части контроллера напрямую.
func _run() -> void:
	var main := (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	await physics_frame
	await physics_frame

	var player := main.get_node("Player") as CharacterBody3D
	_check(InputMap.has_action("sprint"), "sprint action is missing")
	# Руки должны быть отдельной редактируемой сценой с двумя независимыми руками.
	var hands := player.get_node_or_null("Camera3D/PlayerHands") as Node3D
	_check(hands != null, "first-person hands are missing")
	if hands:
		_check(hands.get_node_or_null("LeftArm/Hand") is MeshInstance3D, "left hand mesh is missing")
		_check(hands.get_node_or_null("RightArm/Hand") is MeshInstance3D, "right hand mesh is missing")

	# Один короткий шаг не должен мгновенно разгонять игрока до полной скорости.
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	player.call("_update_horizontal_movement", 0.05, true)
	var first_step_speed := Vector2(player.velocity.x, player.velocity.z).length()
	_check(first_step_speed > 0.0, "player does not accelerate")
	_check(first_step_speed < player.get("walk_speed"), "player reaches full speed instantly")

	# Удержание Shift должно разогнать персонажа быстрее обычной ходьбы.
	Input.action_press("sprint")
	for step in 20:
		player.call("_update_horizontal_movement", 0.05, true)
	var sprint_result := Vector2(player.velocity.x, player.velocity.z).length()
	_check(sprint_result > player.get("walk_speed"), "sprint is not faster than walking")
	Input.action_release("sprint")
	Input.action_release("move_forward")

	# Заполненные таймеры имитируют допустимое нажатие Space около поверхности.
	player.velocity.y = 0.0
	player.set("coyote_timer", player.get("coyote_time"))
	player.set("jump_buffer_timer", player.get("jump_buffer_time"))
	player.call("_try_to_jump")
	_check(is_equal_approx(player.velocity.y, player.get("jump_velocity")), "jump impulse is incorrect")

	main.queue_free()
	await process_frame
	_finish()


# Добавляет ошибку в список, когда условие ложно.
func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


# Возвращает код 0 при успехе и код 1 при ошибке.
func _finish() -> void:
	if failures.is_empty():
		print("Player physics smoke test passed")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
