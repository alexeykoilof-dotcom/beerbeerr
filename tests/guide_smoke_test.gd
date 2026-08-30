# Автоматическая проверка гида: наличие, реплики, переключение и закрытие окна.
extends SceneTree

# Сюда собираются все ошибки, чтобы тест показал их вместе.
var failures: Array[String] = []


# Отложенный запуск даёт SceneTree полностью подготовиться.
func _init() -> void:
	call_deferred("_run")


# Создаёт главную сцену и последовательно проверяет поведение гида.
func _run() -> void:
	# Два физических кадра нужны для выполнения _ready и регистрации коллизий.
	var main := (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	await physics_frame
	await physics_frame

	var guide := main.get_node_or_null("Guide") as StaticBody3D
	_check(guide != null, "guide is missing from the main scene")
	if guide == null:
		_finish()
		return

	_check(guide.is_in_group("guide"), "guide interaction group is missing")
	_check(guide.collision_layer == 4, "guide is not on the interaction layer")
	var lines: Array[String] = guide.get("dialogue_lines")
	_check(lines.size() >= 5, "guide needs several default help lines")

	# Ставим игрока перед гидом и направляем камеру точно на него.
	var player := main.get_node("Player") as CharacterBody3D
	var camera := player.get_node("Camera3D") as Camera3D
	player.global_position = guide.global_position + Vector3(0, 0.95, 3.0)
	camera.look_at(guide.global_position + Vector3.UP * 1.1, Vector3.UP)
	await physics_frame
	player.call("_interact_with_ingredient")

	# Первое E должно открыть окно, второе — показать другую реплику.
	var panel := guide.get_node("DialogueHUD/DialoguePanel") as Control
	var label := guide.get_node("DialogueHUD/DialoguePanel/DialogueText") as Label
	_check(panel.visible, "E interaction did not open guide dialogue")
	var first_text := label.text
	player.call("_interact_with_ingredient")
	_check(label.text != first_text, "guide did not advance to another line")

	# Проверяем, что изменённый пользователем массив действительно используется.
	var edited_lines: Array[String] = ["Тестовая реплика"]
	guide.set("dialogue_lines", edited_lines)
	guide.call("interact", player)
	_check(label.text.contains("Тестовая реплика"), "edited dialogue array is not used")

	# Имитируем Escape без настоящей клавиатуры.
	var close_event := InputEventAction.new()
	close_event.action = "ui_cancel"
	close_event.pressed = true
	guide.call("_unhandled_input", close_event)
	_check(not panel.visible, "Escape did not close guide dialogue")

	main.queue_free()
	await process_frame
	_finish()


# Добавляет текст ошибки только при проваленной проверке.
func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


# Завершает Godot с кодом 0 при успехе или 1 при наличии ошибок.
func _finish() -> void:
	if failures.is_empty():
		print("Guide smoke test passed")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
