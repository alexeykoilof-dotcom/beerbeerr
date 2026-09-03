# Управляет общей сценой: создаёт коллизии импортированных моделей и двигает ворота.
extends Node3D

const WORLD_LAYER := 1
const PICKUP_LAYER := 2
const PICKUP_MASK := WORLD_LAYER | PICKUP_LAYER

# Ворота переключаются только наружной кнопкой GarageGateSwitch.
@export var open_height := 4.0
@export var move_speed := 2.5

# Ссылки на уже расставленные в main.tscn объекты.
# Знак $ означает путь к существующему дочернему узлу; новый объект здесь не создаётся.
@onready var garage: Node3D = $garage
@onready var garage_gate: Node3D = $GarageGate

# Исходная позиция ворот запоминается при запуске, чтобы они всегда возвращались
# именно туда, куда ты поставил их в редакторе Godot.
var closed_position: Vector3

var gate_is_open := false

# При запуске добавляет физические оболочки декорациям и запоминает положение ворот.
func _ready() -> void:
	# GLB-модели обычно содержат видимый Mesh, но не всегда имеют физическое тело.
	# Здесь коллизии создаются один раз после загрузки сцены.
	# Старый верхнеуровневый Sketchfab_Scene мог быть удалён из main.tscn вручную.
	# В таком состоянии запускаем игру без него и не восстанавливаем декорацию.
	var environment_root := get_node_or_null("Sketchfab_Scene")
	if environment_root:
		_create_environment_collisions(environment_root)
	_create_environment_collisions(garage)
	_create_environment_collisions(garage_gate)
	# Уличный фонарь является отдельной GLB-сценой и не входит ни в гараж,
	# ни в общий каменный декор, поэтому его коллизия создаётся отдельно.
	var street_lamp := get_node_or_null("light-curved2")
	if street_lamp:
		_create_environment_collisions(street_lamp)

	_configure_required_static_collisions()
	_configure_pickup_collisions()

	# Сохраняем пользовательскую позицию ворот до того, как начнём их анимировать.
	closed_position = garage_gate.position

	# Статические подписи сцен тоже получают язык из общей базы. Дочерние
	# скрипты к этому моменту уже выполнили _ready(), поэтому обновление единообразно.
	Localization.localize_tree(self)


# Каждый физический кадр плавно ведёт ворота к состоянию, выбранному кнопкой.
func _physics_process(delta: float) -> void:
	var target_position := closed_position
	if gate_is_open:
		target_position += Vector3.UP * open_height
	garage_gate.position = garage_gate.position.move_toward(target_position, move_speed * delta)


func toggle_garage_gate() -> void:
	gate_is_open = not gate_is_open


func set_garage_gate_open(is_open: bool) -> void:
	gate_is_open = is_open


# Проходит по всем мешам импортированной GLB-модели и создаёт точные StaticBody3D.
func _create_environment_collisions(root: Node) -> void:
	if root == null:
		return
	# Декоративная трава сюда не передаётся, поэтому она намеренно остаётся без коллизии.
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		# Интерьер гаража уже содержит простые ручные коллизии для полок,
		# верстака, шин и огнетушителя. Не создаём поверх них тяжёлые дубликаты.
		if _has_skip_auto_collision_ancestor(mesh_instance, root):
			continue

		# Пустые меши пропускаются. Для остальных Godot строит неподвижную
		# треугольную коллизию точно по форме видимой модели.
		if mesh_instance.mesh and mesh_instance.mesh.get_surface_count() > 0:
			mesh_instance.create_trimesh_collision()


# Проверяет сам узел и его родителей до корня импортированной модели.
# Достаточно добавить группу skip_auto_collision контейнеру новой декорации,
# чтобы main.gd не создавал коллизию отдельно для каждого её маленького меша.
func _has_skip_auto_collision_ancestor(node: Node, search_root: Node) -> bool:
	var current := node
	while current and current != search_root:
		if current.is_in_group("skip_auto_collision"):
			return true
		current = current.get_parent()
	return false


# Переносимые предметы сталкиваются не только с миром на слое 1,
# но и друг с другом на слое 2. Это не даёт коробкам и шинам проходить насквозь.
func _configure_pickup_collisions() -> void:
	for node in get_tree().get_nodes_in_group("pickup_object"):
		var body := node as RigidBody3D
		if body == null:
			continue
		body.collision_layer |= PICKUP_LAYER
		body.collision_mask |= PICKUP_MASK
		body.continuous_cd = true


# Явно включает физический слой и формы у ключевых препятствий.
# Это защищает их от случайного отключения в переопределениях главной сцены.
func _configure_required_static_collisions() -> void:
	var required_paths := [
		"StreetLamp/CollisionBody",
		"GarageGateSwitch/InteractionBody",
		"Guide",
		"RouletteTable",
		"BrewingStation/IngredientTable",
		"garage/GarageInterior/Workbench",
		"WarehouseShop/BuildingCollision",
		"WarehouseShop/PurchaseCounter",
	]
	for path in required_paths:
		var body := get_node_or_null(path) as StaticBody3D
		if body == null:
			continue
		body.collision_layer |= WORLD_LAYER
		body.collision_mask |= WORLD_LAYER
		for shape_node in body.find_children("*", "CollisionShape3D", true, false):
			var shape := shape_node as CollisionShape3D
			if shape:
				shape.disabled = false
