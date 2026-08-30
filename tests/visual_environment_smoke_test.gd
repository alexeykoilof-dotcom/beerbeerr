# Автоматическая проверка визуального слоя главной сцены.
# Тест ничего не сохраняет и не двигает: он только загружает сцену в памяти
# и убеждается, что небо, туман, цветокоррекция и тени подключены правильно.
extends SceneTree


func _init() -> void:
	var packed_main := load("res://main.tscn") as PackedScene
	assert(packed_main != null, "Главная сцена main.tscn должна загружаться")

	var main := packed_main.instantiate()
	root.add_child(main)

	# WorldEnvironment хранит все настройки атмосферы в отдельном .tres-файле,
	# поэтому их можно менять в Inspector без правки кода.
	var world_environment := main.get_node("WorldEnvironment") as WorldEnvironment
	assert(world_environment.environment != null, "Окружение должно быть подключено")
	assert(world_environment.environment.sky != null, "Небо должно быть подключено")
	assert(world_environment.environment.fog_enabled, "Лёгкий дальний туман должен быть включён")
	assert(world_environment.environment.adjustment_enabled, "Цветокоррекция должна быть включена")

	# Проверяем главный источник света: тени не должны снова стать прозрачными.
	var sun := main.get_node("DirectionalLight3D") as DirectionalLight3D
	assert(sun.shadow_enabled, "У главного солнца должны быть включены тени")
	assert(sun.shadow_opacity > 0.5, "Тени главного солнца должны быть видимыми")
	assert(sun.light_energy > 0.0, "Главное солнце должно освещать сцену")

	# Старый вложенный источник сохранён как редактируемый узел, но его яркость
	# обнулена, чтобы два одинаковых солнца не делали картинку плоской и пересвеченной.
	var duplicate_sun := main.get_node("DirectionalLight3D/DirectionalLight3D") as DirectionalLight3D
	assert(is_zero_approx(duplicate_sun.light_energy), "Дублирующее солнце не должно светить")

	main.queue_free()
	print("VISUAL_ENVIRONMENT_SMOKE_TEST_OK")
	quit(0)
