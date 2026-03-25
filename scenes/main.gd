extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game_Manager.register_main(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if TurnManager.current_phase == GameEnums.TurnEnum.MAIN and TurnManager.priority:
		$"ButtonContainer/EndTurnButton".disabled = false
	else:
		$"ButtonContainer/EndTurnButton".disabled = true
	if TurnManager.current_phase == GameEnums.TurnEnum.ATTACK and TurnManager.priority:
		$"ButtonContainer/Cancel attack".disabled = false
	else:
		$"ButtonContainer/Cancel attack".disabled = true
