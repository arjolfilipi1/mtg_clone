extends Button
@onready var card:Card = $"../.."
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	visible = false
func pressed() -> void:
	if card.state.effect:
		if card.state.effect.targets:
			#open targeting 
			pass
		else:
			card.state.apply_effect()

func _process(_delta:float) -> void:
	if card.state.effect:
		if card.state.can_be_payed(TurnManager.game_manager.gamestate):
			visible = true
		else:
			visible = false
