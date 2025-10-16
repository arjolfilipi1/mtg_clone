class_name Player

extends Resource
signal mana_changed(Player)
# --- Gameplay State ---
var player_name: String = ""
var life_total: int = 20
var hand = []
var creatures = []  # Creatures on battlefield
var mana = []
var battlefield = []
var graveyard = []
var library = []
var mana_selected = false
var mana_created = false
var player_mana_zone : Node = null
var board : Node = null
var deck : Node = null
var player_hand : Node = null
var player_mana_card_nr = 0
var player_orbs = {
	"generic": [],
	"red": [],
	"blue": [],
	"green": [],
	"earth": [],
	"white": [],
	"black": []}
var mana_pool: Dictionary = {
	"generic": 0,
	"red": 0,
	"blue": 0,
	"green": 0,
	"earth": 0,
	"white": 0,
	"black": 0
}  # e.g., { "G": 1, "R": 2 }
var is_active: bool = false
var is_human: bool = false
var priority: bool = false
var did_draw: bool = false

# --- Signals ---
#signal priority_passed()
#signal card_played(card)
#signal life_changed(new_life: int)

func _init(_pn,_pmz,_ph,_b,_d):
	player_name = _pn
	player_mana_zone= _pmz 
	player_hand = _ph
	board = _b
	deck = _d
	mana_changed.connect(mana_match_visual)
	pass
func reset_mana():
	TurnManager.debug.text += "reseting mana \n"
	mana_pool = {
	"generic": 0,
	"red": 0,
	"blue": 0,
	"green": 0,
	"earth": 0,
	"white": 0,
	"black": 0
}
	emit_signal("mana_changed",self)
func create_mana():
	print("mana create")
	for color in player_orbs.keys():
		for node in color:
			if is_instance_valid(node):
				node.free()


	for child in player_mana_zone.get_children():
		if child is Sprite2D:
			continue
		if child.is_card:
			var list = TurnManager.cost_to_list(child.state.mana_creation)
			for l in list:
				mana_pool[l] += 1
				var orb = player_mana_zone.spawn_mana_orb(l,Vector2(100,125),player_mana_zone)
				orb.z_index = 10
				orb.mana_type = l
				player_orbs[l].append(orb)
	mana_created = true
	TurnManager.priority = !TurnManager.priority 
	TurnManager.finish_mana_creation()
	#current_phase = turn_phases[3]
	pass
#pay for card
func pay_for_card( card) -> void:
	#return 
	TurnManager.debug.text += "Paying for card by "+ player_name +" \n"
	for color in card.state.mana_cost.keys():
		var required = card.state.mana_cost[color]
		var available = mana_pool.get(color, 0)
		
		if available >= required:
			# Use same-color mana
			mana_pool[color] = available - required
		else:
			# Use all available of that color
			var remaining = required - available
			mana_pool[color] = 0
			
			# Pay remaining with other colors at 2:1 rate
			var substitute_needed = remaining * 2
			var to_spend = substitute_needed
			
			for other_color in mana_pool.keys():
				if other_color == color or other_color == "generic":
					continue
				var usable = min(mana_pool[other_color], to_spend)
				mana_pool[other_color] -= usable
				to_spend -= usable
				if to_spend == 0:
					break
	emit_signal("mana_changed",self)
func mana_match_visual(pl):
	if pl == self:
		TurnManager.debug.text += "Seting mana visuals for "+ player_name +" \n"
		for color in player_orbs.keys():
			while len(player_orbs[color]) > mana_pool[color] :
				var  node = player_orbs[color][-1]
				if is_instance_valid(node):
					player_orbs[color].erase(node)
					node.queue_free()
		player_mana_zone.arrange_mana_orbs_in_circle(Vector2(60,75),30)

# --- Gameplay Flags ---

# --- Public Methods ---

func draw():
	var card := preload("res://scenes/Card.tscn").instantiate()
	var random_card = TurnManager.game_manager.card_database[randi() % TurnManager.game_manager.card_database.size()]
	card.setup(random_card,is_human,self)
	card.state.card_location = CardState.le.hand
	card.state.controller = self
	player_hand.add_child(card)
	TurnManager.game_manager.draw_card(card, deck.position, player_hand.position)
	print("%s draws %s" % [player_name, card.name])
	did_draw = true


func take_damage(amount: int):
	life_total -= amount
	emit_signal("life_changed", life_total)
	print("%s takes %d damage (Life: %d)" % [player_name, amount, life_total])
	if life_total <= 0:
		print("%s has lost the game!" % player_name)

func gain_priority():
	priority = true
	print("%s gains priority." % player_name)

func pass_priority():
	priority = false
	emit_signal("priority_passed")
	print("%s passes priority." % player_name)

func get_attackable_creatures() -> Array:
	return creatures.filter(func(c): return c.can_attack and not c.tapped and not c.has_summoning_sickness)
