extends Node2D

class_name CombatManager


var defender_player: Player
var attacker_player: Player

func _ready():
	pass

func execute_attack(attacker:Card,defender:Card):
	
	attacker.state.toughness = max(attacker.state.toughness - defender.state.power ,0)
	defender.state.toughness = max(defender.state.toughness - attacker.state.power ,0)
	attacker.visual.update_pt()
	defender.visual.update_pt()
	TurnManager.game_manager._on_cancel_attack_pressed()
	
