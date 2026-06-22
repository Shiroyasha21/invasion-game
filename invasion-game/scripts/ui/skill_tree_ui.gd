extends CanvasLayer
class_name SkillTreeUI

@onready var shield_label: Label = $Panel/VBox/ShieldRow/ShieldLabel
@onready var vines_button: Button = $Panel/VBox/VinesButton
@onready var vines_label: Label = $Panel/VBox/VinesButton/Row/Label
@onready var weaken_button: Button = $Panel/VBox/WeakenButton
@onready var weaken_label: Label = $Panel/VBox/WeakenButton/Row/Label
@onready var close_button: Button = $Panel/VBox/CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	vines_button.pressed.connect(_on_vines_pressed)
	weaken_button.pressed.connect(_on_weaken_pressed)
	close_button.pressed.connect(_on_close_pressed)
	SkillTree.shield_changed.connect(_on_shield_changed)
	SkillTree.shield_cooldown_changed.connect(_on_shield_cooldown_changed)


func open() -> void:
	_refresh()
	visible = true
	get_tree().paused = true


func _on_close_pressed() -> void:
	visible = false
	get_tree().paused = false


func _on_vines_pressed() -> void:
	if SkillTree.unlock_vines():
		_refresh()


func _on_weaken_pressed() -> void:
	if SkillTree.unlock_weaken():
		_refresh()


func _on_shield_changed(active: bool) -> void:
	_update_shield_label(active)


func _on_shield_cooldown_changed(_remaining: float, _ready: bool) -> void:
	_update_shield_label(SkillTree.shield_active)


func _refresh() -> void:
	_update_shield_label(SkillTree.shield_active)

	if SkillTree.vines_unlocked:
		vines_label.text = "Vines — Unlocked\nPeriodically slows nearby enemies"
		vines_button.disabled = true
	else:
		vines_label.text = "Unlock Vines (%d coins)\nPeriodically slows nearby enemies" % SkillTree.VINES_COST
		vines_button.disabled = false

	if SkillTree.weaken_unlocked:
		weaken_label.text = "Weaken Boss — Unlocked\nFuture mini-bosses are weaker"
		weaken_button.disabled = true
	else:
		weaken_label.text = "Unlock Weaken Boss (%d coins)\nFuture mini-bosses are weaker" % SkillTree.WEAKEN_COST
		weaken_button.disabled = false


func _update_shield_label(active: bool) -> void:
	if active:
		shield_label.text = "Shield: ACTIVE"
	elif SkillTree.shield_ready:
		shield_label.text = "Shield — ready (use the Shield button on the HUD)"
	else:
		shield_label.text = "Shield — on cooldown"
