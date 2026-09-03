# Интерактивный гид возле гаража и его редактируемые реплики.
extends StaticBody3D

# Возможные способы выбора следующей фразы.
enum DialogueOrder {
	SEQUENTIAL,
	RANDOM,
}

# Все эти параметры меняются у узла Guide в Inspector.
@export_category("Реплики гида")
@export var guide_name := "Гид"
@export var dialogue_lines: Array[String] = [
	"Привет! Я помогу тебе сварить первое пиво.",
	"Наведи прицел на ингредиент и нажми E, чтобы взять его.",
	"Для рецепта нужны две порции солода, один хмель и одни дрожжи.",
	"Подойди к чану, наведи на него прицел и нажми E, чтобы бросить ингредиент.",
	"Счётчик слева показывает, сколько ингредиентов уже находится в чане.",
	"Если предмет застрял, подними его снова и брось немного выше края чана.",
	"Когда все четыре ингредиента окажутся в чане, пиво будет готово!",
]
@export var dialogue_order := DialogueOrder.SEQUENTIAL
@export_range(1.0, 20.0, 0.5) var display_seconds := 6.0

# Ссылки на элементы диалогового окна и таймер автозакрытия.
@onready var dialogue_panel: Control = $DialogueHUD/DialoguePanel
@onready var dialogue_title: Label = $DialogueHUD/DialoguePanel/DialogueTitle
@onready var dialogue_text: Label = $DialogueHUD/DialoguePanel/DialogueText
@onready var hide_timer: Timer = $HideTimer

# Индексы нужны для последовательного режима и защиты от повтора в случайном режиме.
var next_line_index := 0
var last_random_index := -1
var current_dialogue_source := ""


# Прячет окно при старте и применяет настройки из Inspector.
func _ready() -> void:
	dialogue_panel.hide()
	hide_timer.wait_time = display_seconds
	Localization.language_changed.connect(_on_language_changed)
	dialogue_title.text = _guide_display_name()


# Позволяет закрыть открытый диалог клавишей Escape.
func _unhandled_input(event: InputEvent) -> void:
	if dialogue_panel.visible and event.is_action_pressed("ui_cancel"):
		_hide_dialogue()
		get_viewport().set_input_as_handled()


# Публичный метод вызывается игроком, когда луч взаимодействия попал в гида.
func interact(_player: Node = null) -> void:
	if dialogue_lines.is_empty():
		_show_dialogue(Localization.get_text("guide.no_lines"))
		return

	var line_index := _choose_line_index()
	_show_dialogue(dialogue_lines[line_index])


# Текст забирает HUD игрока, когда прицел наведён на гида.
func get_interaction_text() -> String:
	return Localization.get_text("guide.prompt", [_guide_display_name()])


# Возвращает индекс следующей фразы с учётом выбранного порядка.
func _choose_line_index() -> int:
	if dialogue_order == DialogueOrder.RANDOM:
		var line_index := randi_range(0, dialogue_lines.size() - 1)
		# При наличии нескольких реплик не показываем одну и ту же дважды подряд.
		if dialogue_lines.size() > 1 and line_index == last_random_index:
			line_index = (line_index + 1) % dialogue_lines.size()
		last_random_index = line_index
		return line_index

	var line_index := next_line_index % dialogue_lines.size()
	next_line_index = (next_line_index + 1) % dialogue_lines.size()
	return line_index


# Заполняет заголовок и текст, показывает панель и перезапускает таймер.
func _show_dialogue(line: String) -> void:
	current_dialogue_source = line
	dialogue_title.text = _guide_display_name()
	dialogue_text.text = Localization.translate_source(line)
	dialogue_panel.show()
	hide_timer.start(display_seconds)


# Обработчик сигнала таймера.
func _on_hide_timer_timeout() -> void:
	_hide_dialogue()


# Обработчик нажатия кнопки-крестика.
func _on_close_button_pressed() -> void:
	_hide_dialogue()


# Единая функция закрытия останавливает таймер и скрывает окно.
func _hide_dialogue() -> void:
	dialogue_panel.hide()
	hide_timer.stop()


func _guide_display_name() -> String:
	return Localization.translate_source(guide_name)


func _on_language_changed(_language_code: String) -> void:
	dialogue_title.text = _guide_display_name()
	if not current_dialogue_source.is_empty():
		dialogue_text.text = Localization.translate_source(current_dialogue_source)
