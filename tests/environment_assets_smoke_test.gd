# Проверяет, что подборка окружения полностью импортируется и открывается в Godot.
extends SceneTree

# Список найденных ошибок и всех GLB-файлов подборки.
var failures: Array[String] = []
var glb_paths: Array[String] = []


# Откладывает тест до готовности дерева движка.
func _init() -> void:
	call_deferred("_run")


# Загружает каждую модель и отдельно проверяет нативную лавочку.
func _run() -> void:
	_collect_glb_paths("res://assets/environment")
	_check(glb_paths.size() == 63, "environment selection must contain exactly 63 GLB models")

	for path in glb_paths:
		var packed_scene := load(path) as PackedScene
		_check(packed_scene != null, "could not load: " + path)
		if packed_scene == null:
			continue
		var instance := packed_scene.instantiate()
		_check(instance != null, "could not instantiate: " + path)
		if instance:
			instance.free()

	var bench_scene := load("res://assets/environment/props/bench_low_poly.tscn") as PackedScene
	_check(bench_scene != null, "editable bench scene is missing")
	if bench_scene:
		var bench := bench_scene.instantiate() as StaticBody3D
		_check(bench != null, "bench root must be a StaticBody3D")
		if bench:
			_check(bench.find_children("*", "MeshInstance3D", true, false).size() >= 11, "bench does not have editable separate parts")
			_check(bench.find_children("*", "CollisionShape3D", true, false).size() >= 4, "bench collision is incomplete")
			bench.free()

	_finish()


# Рекурсивно собирает только рабочие модели, игнорируя исходные ZIP-архивы.
func _collect_glb_paths(directory_path: String) -> void:
	for file_name in DirAccess.get_files_at(directory_path):
		if file_name.get_extension().to_lower() == "glb":
			glb_paths.append(directory_path.path_join(file_name))
	for directory_name in DirAccess.get_directories_at(directory_path):
		_collect_glb_paths(directory_path.path_join(directory_name))


# Записывает сообщение только при невыполненном условии.
func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


# Завершает тест кодом 0 при успехе или кодом 1 при найденных проблемах.
func _finish() -> void:
	if failures.is_empty():
		print("Environment assets smoke test passed: %d GLB models and editable bench" % glb_paths.size())
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
