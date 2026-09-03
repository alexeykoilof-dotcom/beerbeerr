# Скрипт отдельной кнопки ставки на столе рулетки.
# Один и тот же файл используется для ЗЕРО, КРАСНОГО и ЧЁРНОГО.
extends StaticBody3D

# Значение выбирается у каждой кнопки в Inspector.
@export_enum("zero", "red", "black") var bet_type := "zero"


# Игрок вызывает этот метод лучом взаимодействия после нажатия E.
func interact(_player: Node = null) -> void:
	# Ищем родительский стол, не полагаясь на строго фиксированную вложенность узлов.
	# Благодаря этому кнопки можно переставлять внутри сцены без изменения кода.
	var possible_table: Node = get_parent()
	while possible_table:
		if possible_table.has_method("place_bet"):
			possible_table.call("place_bet", bet_type)
			return
		possible_table = possible_table.get_parent()


# Возвращает понятную подпись для контекстного HUD возле прицела.
func get_interaction_text() -> String:
	match bet_type:
		"zero":
			return Localization.get_text("roulette.prompt_zero")
		"red":
			return Localization.get_text("roulette.prompt_red")
		"black":
			return Localization.get_text("roulette.prompt_black")
	return Localization.get_text("roulette.prompt_bet")
