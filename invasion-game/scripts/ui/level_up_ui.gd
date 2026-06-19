extends CanvasLayer
class_name LevelUpUI

signal card_chosen(card: UpgradeCard)

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var card_buttons: Array[Button] = [
	$Panel/VBox/Cards/CardA,
	$Panel/VBox/Cards/CardB,
	$Panel/VBox/Cards/CardC,
]

var _current_cards: Array[UpgradeCard] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	for i in card_buttons.size():
		card_buttons[i].pressed.connect(_on_card_pressed.bind(i))


func show_cards(new_level: int, cards: Array[UpgradeCard]) -> void:
	_current_cards = cards
	title_label.text = "Level %d!" % new_level
	for i in card_buttons.size():
		if i < cards.size():
			card_buttons[i].visible = true
			card_buttons[i].text = "%s\n\n%s" % [cards[i].title, cards[i].description]
		else:
			card_buttons[i].visible = false
	visible = true
	get_tree().paused = true


func _on_card_pressed(index: int) -> void:
	var card := _current_cards[index]
	visible = false
	get_tree().paused = false
	emit_signal("card_chosen", card)
