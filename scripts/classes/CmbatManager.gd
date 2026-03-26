extends Node2D

class_name CombatManager


var defender_player: Player
var attacker_player: Player

func _ready():
	pass

func execute_attack(attacker:Card,defender:Card,game:MTGGameState):
	UI_Manager.cancel_attack()
	attacker.state.take_damage(defender.state.power,defender.state,game)
	defender.state.take_damage(attacker.state.power,attacker.state,game)
	
	
	
