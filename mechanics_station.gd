# Универсальная кнопка-станция пивного цикла.
# В Inspector меняются действие и текст возле прицела; внешний вид редактируется в сцене.
extends StaticBody3D

@export_enum(
	"Купить пивное сырьё",
	"Сварить пиво",
	"Упаковать пиво",
	"Продать пиво",
	"Улучшить оборудование",
	"Эксперимент с рецептом",
	"Очистить оборудование"
) var action := 0

@export var interaction_text := "использовать станцию"


func interact(_player: Node) -> void:
	var action_owner := get_parent()
	while action_owner and not action_owner.has_method("perform_action"):
		action_owner = action_owner.get_parent()
	if action_owner:
		action_owner.call("perform_action", action)


func get_interaction_text() -> String:
	return "E — " + Localization.translate_source(interaction_text)
