# Игровая логика уличной рулетки.
# Визуальные детали находятся в roulette_table.tscn и остаются отдельными узлами,
# поэтому стол, колесо, шарик, кнопки и материалы можно менять в редакторе Godot.
extends StaticBody3D

# Настоящий порядок чисел на европейском колесе с одним зеро.
# Индекс числа определяет положение цветной ячейки на окружности колеса.
const WHEEL_NUMBERS: Array[int] = [
	0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23,
	10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26,
]

# Красные номера стандартной европейской рулетки.
# Любой номер кроме них и зеро считается чёрным.
const RED_NUMBERS: Array[int] = [
	1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36,
]

@export_category("Вращение рулетки")
@export_range(1.0, 10.0, 0.1) var spin_duration := 4.2
@export_range(2, 12, 1) var minimum_wheel_turns := 5
@export_range(3, 16, 1) var maximum_wheel_turns := 8
@export_range(5, 20, 1) var ball_turns := 10

@export_category("Подписи")
@export var idle_text := "ВЫБЕРИ СТАВКУ: ЗЕРО / КРАСНОЕ / ЧЁРНОЕ"

# Узлы вращаются независимо: колесо идёт в одну сторону, шарик — в другую.
@onready var wheel_pivot: Node3D = $WheelPivot
@onready var ball_pivot: Node3D = $BallPivot
@onready var ball: MeshInstance3D = $BallPivot/Ball
@onready var result_label: Label3D = $ResultLabel

# Это состояние доступно тестам и другим будущим системам игры.
var current_bet := ""
var last_result := -1
var spinning := false
var random := RandomNumberGenerator.new()


# Подготавливает отдельный генератор случайных чисел и начальную подсказку.
func _ready() -> void:
	random.randomize()
	Localization.language_changed.connect(_on_language_changed)
	result_label.text = Localization.translate_source(idle_text)
	# Результат хранится в этом узле для логики, но сам трёхмерный текст скрыт.
	# Игрок увидит актуальное состояние в HUD только при наведении на стол.
	result_label.hide()


# Возвращает текст для общего HUD игрока только тогда, когда луч наведения
# действительно попал в физический корпус рулетки.
func get_interaction_text() -> String:
	if spinning:
		return Localization.get_text("roulette.spinning_hover")
	if last_result >= 0:
		var result_color := _result_color(last_result)
		var outcome := Localization.get_text(
			"roulette.won_short" if current_bet == result_color else "roulette.lost_short"
		)
		return Localization.get_text("roulette.result_hover", [
			last_result,
			_bet_display_name(result_color),
			outcome,
		])
	return Localization.get_text("roulette.aim")


# Вызывается одной из трёх физических кнопок после нажатия E.
func place_bet(bet_type: String) -> void:
	if spinning:
		result_label.text = Localization.get_text("roulette.already_spinning")
		return

	if bet_type not in ["zero", "red", "black"]:
		return

	current_bet = bet_type
	_start_spin()


# Выбирает случайную ячейку и запускает две плавные анимации через Tween.
func _start_spin() -> void:
	spinning = true
	var result_index := random.randi_range(0, WHEEL_NUMBERS.size() - 1)
	last_result = WHEEL_NUMBERS[result_index]
	result_label.text = Localization.get_text("roulette.spinning", [_bet_display_name(current_bet)])

	# Колесо делает несколько полных оборотов и останавливается под случайным углом.
	var full_turns := random.randi_range(minimum_wheel_turns, maximum_wheel_turns)
	var wheel_target := wheel_pivot.rotation.y + TAU * float(full_turns) + random.randf_range(0.0, TAU)

	# В конце шарик совмещается с выбранной ячейкой. Вычитание полных оборотов
	# заставляет его во время анимации вращаться в обратную сторону.
	var pocket_angle := TAU * float(result_index) / float(WHEEL_NUMBERS.size())
	var ball_target := wheel_target + pocket_angle - TAU * float(ball_turns)

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(wheel_pivot, "rotation:y", wheel_target, spin_duration)
	tween.tween_property(ball_pivot, "rotation:y", ball_target, spin_duration)
	tween.tween_property(ball, "rotation", ball.rotation + Vector3(TAU * 8.0, 0.0, TAU * 5.0), spin_duration)
	await tween.finished

	spinning = false
	_show_result()


# Выводит выпавшее число, его цвет и результат выбранной ставки.
func _show_result() -> void:
	var result_color := _result_color(last_result)
	var bet_won := current_bet == result_color
	var outcome := Localization.get_text("roulette.won" if bet_won else "roulette.lost")
	result_label.text = Localization.get_text("roulette.result", [
		last_result,
		_bet_display_name(result_color),
		outcome,
	])


# Преобразует номер в один из трёх типов ставки.
func _result_color(number: int) -> String:
	if number == 0:
		return "zero"
	if number in RED_NUMBERS:
		return "red"
	return "black"


# Отдельная функция хранит русские подписи в одном месте.
func _bet_display_name(bet_type: String) -> String:
	match bet_type:
		"zero":
			return Localization.get_text("roulette.zero")
		"red":
			return Localization.get_text("roulette.red")
		"black":
			return Localization.get_text("roulette.black")
	return Localization.get_text("roulette.unknown")


func _on_language_changed(_language_code: String) -> void:
	if spinning:
		result_label.text = Localization.get_text("roulette.spinning", [_bet_display_name(current_bet)])
	elif last_result >= 0:
		_show_result()
	else:
		result_label.text = Localization.translate_source(idle_text)
