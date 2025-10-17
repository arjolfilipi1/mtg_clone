extends Node2D

class_name CombatManager


var defender_player: Player
var attacker_player: Player

func _ready():
	pass

func execute_attack(attacker:Card,defender:Card):
	
	attacker.state.take_damage(defender.state.power,defender)
	defender.state.take_damage(attacker.state.power,attacker)
	
	TurnManager.game_manager._on_cancel_attack_pressed()
	
