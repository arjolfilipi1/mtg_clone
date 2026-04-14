extends Node2D

@onready var EndTurnButton = $"ButtonContainer/EndTurnButton"
@onready var Cancel_attack = $"ButtonContainer/Cancel attack"
@onready var Pass_Button:Button = $ButtonContainer/Pass
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game_Manager.register_main(self)
	PriorityManager.priority_changed.connect(_on_priority_changed)
	Pass_Button.disabled = true
func _on_priority_changed(player_index: int):
	Pass_Button.disabled = not (player_index == 0 and not Game_Manager.gamestate.stack.is_empty())
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if TurnManager.current_phase == GameEnums.TurnEnum.MAIN and TurnManager.priority:
		EndTurnButton.disabled = false
	else:
		EndTurnButton.disabled = true
	if TurnManager.current_phase == GameEnums.TurnEnum.ATTACK and TurnManager.priority:
		Cancel_attack.disabled = false
	else:
		Cancel_attack.disabled = true


func _on_overlay_cancelled() -> void:
	Game_Manager._on_overlay_cancelled()


func _on_cancel_attack_pressed() -> void:
	Game_Manager._on_cancel_attack_pressed()


func store_gamestate() -> void:
	Game_Manager.store_gamestate()

func _on_pass_pressed():
	PriorityManager.pass_priority()

func _on_end_turn_button_pressed() -> void:
	TurnManager.end_turn()
