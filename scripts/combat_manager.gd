extends Node2D

class_name CombatManager

var attackers: Array = []
var defender: Player
var attacker_player: Player

#signal attack_declared(attacker, defender: Player)

func start_combat_phase(attacking_player: Player, defending_player: Player):
	attacker_player = attacking_player
	defender = defending_player
	attackers.clear()
	prompt_attackers()

func prompt_attackers():
	for creature in attacker_player.creatures:
		if can_attack(creature):
			creature.connect("clicked", Callable(self, "_on_attacker_selected").bind(creature))
			creature.highlight("attackable")  # optional visual

func _on_attacker_selected(creature):
	if attackers.has(creature):
		attackers.erase(creature)
		creature.unhighlight()
	else:
		attackers.append(creature)
		creature.highlight("selected")

func confirm_attack():
	for attacker in attackers:
		declare_attack(attacker)

	emit_signal("attack_declared", attackers, defender)
	# Proceed to declare blockers, etc.

func declare_attack(_attacker):
	pass

func can_attack(creature) -> bool:
	return creature.owner == attacker_player and \
		   creature.can_attack and \
		   not creature.tapped and \
		   not creature.has_summoning_sickness
