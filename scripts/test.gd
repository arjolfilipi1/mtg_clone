extends Button
@onready var card:Card = $"../.."
var rng = RandomNumberGenerator.new()

func pressed() -> void:
	print(card.state.get_board_range(TurnManager.board_slots))
func burnCard(direction):
	var svb = card.visual.subvp
	if svb.material and svb.material is ShaderMaterial:
		svb.material.set_shader_parameter("destroy", true)
		
		var tween = create_tween()
		# set burning direction in degrees
		svb.material.set_shader_parameter("direction", direction)
		# use tweens to animate the progress value
		tween.tween_method(up, -1.5, 1.5, 1.0)
	 
func up(value: float):
	var svb = card.visual.subvp
	if svb.material:
		svb.material.set_shader_parameter("progress", value)
