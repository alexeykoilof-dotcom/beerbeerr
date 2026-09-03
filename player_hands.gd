# Управляет только лёгким покачиванием модели рук.
# Камеру этот скрипт не вращает и не наклоняет.
extends Node3D

# Исходное положение рук относительно камеры можно менять в Inspector.
@export_group("Положение рук")
@export var rest_position := Vector3(0.0, -0.34, -0.68)

# Небольшая амплитуда делает руки живыми, но не мешает прицеливанию.
@export_group("Движение при ходьбе")
@export_range(0.0, 0.08, 0.002) var movement_amount := 0.018
@export_range(1.0, 20.0, 0.5) var movement_frequency := 8.0
@export_range(1.0, 30.0, 0.5) var movement_smoothing := 14.0

# Внутреннее время используется как аргумент синуса для плавного движения.
var movement_time := 0.0


# При запуске применяет редактируемое исходное положение.
func _ready() -> void:
	position = rest_position


# Вызывается контроллером игрока после расчёта скорости.
func update_from_player(delta: float, horizontal_speed: float, maximum_speed: float, on_floor: bool) -> void:
	var speed_ratio := clampf(horizontal_speed / maxf(maximum_speed, 0.01), 0.0, 1.0)
	var is_walking := on_floor and horizontal_speed > 0.15

	if is_walking:
		movement_time += delta * movement_frequency * lerpf(0.8, 1.35, speed_ratio)

	# Руки двигаются вбок и вверх-вниз; поворот камеры при этом не меняется.
	var movement_offset := Vector3.ZERO
	if is_walking:
		movement_offset.x = sin(movement_time * 0.5) * movement_amount
		movement_offset.y = absf(cos(movement_time)) * movement_amount * 0.65

	var target_position := rest_position + movement_offset
	position = position.lerp(target_position, 1.0 - exp(-movement_smoothing * delta))
