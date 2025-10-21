extends Node2D

class_name CombatManager


var defender_player: Player
var attacker_player: Player

func _ready():
	pass

func execute_attack(attacker:Card,defender:Card,game:GameState):
	TurnManager.game_manager._on_cancel_attack_pressed()
	attacker.state.take_damage(defender.state.power,defender,game)
	defender.state.take_damage(attacker.state.power,attacker,game)
	
	
	
