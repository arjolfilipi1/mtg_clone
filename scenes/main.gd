extends Node2D

@onready var EndTurnButton = $"ButtonContainer/EndTurnButton"
@onready var Cancel_attack = $"ButtonContainer/Cancel attack"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game_Manager.register_main(self)


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
