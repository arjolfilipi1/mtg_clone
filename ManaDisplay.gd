# res://scripts/UI/ManaDisplay.gd
# Attach to a ManaDisplay.tscn HBoxContainer.
# Shows one colored orb per mana point, grayed out when spent.
#
# Scene structure:
#   ManaDisplay (HBoxContainer)
#     └── [one ColorGroup per color, added at runtime]
#
# Each ColorGroup is a VBoxContainer:
#   ColorGroup
#     ├── OrbRow  (HBoxContainer)  ← filled/spent orbs
#     └── Label                    ← color name, optional

extends HBoxContainer

# Point to the player this display belongs to.
# Set this from your HUD setup, e.g.:
#   player_mana_display.player = Game_Manager.player1
@export var is_player_display: bool = true

var player: Player = null

# Colors matching your mana system
const MANA_COLORS := {
	"red":     Color(0.9, 0.15, 0.1),
	"blue":    Color(0.1, 0.4, 0.95),
	"green":   Color(0.1, 0.75, 0.2),
	"earth":   Color(0.6, 0.4, 0.1),
	"white":   Color(0.95, 0.95, 0.85),
	"black":   Color(0.25, 0.1, 0.35),
	"generic": Color(0.55, 0.55, 0.55),
}

const ORB_SIZE    := Vector2(18, 18)
const ORB_SPACING := 3
const COLOR_ORDER := ["red", "blue", "green", "earth", "white", "black", "generic"]

# Track orb nodes per color so we can update efficiently
var _orb_rows: Dictionary = {}   # color -> HBoxContainer
var _labels:   Dictionary = {}   # color -> Label
var _groups:   Dictionary = {}   # color -> VBoxContainer

func _ready() -> void:
	# Wire up after GameManager finishes setup
	if not Game_Manager.setup_finished:
		await Game_Manager.get_tree().create_timer(0.1).timeout
	
	player = Game_Manager.player1 if is_player_display else Game_Manager.player2
	if player == null:
		push_error("ManaDisplay: player not found")
		return

	_build_ui()
	player.mana_changed.connect(_on_mana_changed)
	_refresh(player)

# ── Build the static structure once ──────────────────────────────────────────

func _build_ui() -> void:
	for color in COLOR_ORDER:
		var group := VBoxContainer.new()
		group.name = color + "_group"
		group.visible = false  # hidden until this color has mana
		add_child(group)
		_groups[color] = group

		var orb_row := HBoxContainer.new()
		orb_row.name = "OrbRow"
		orb_row.add_theme_constant_override("separation", ORB_SPACING)
		group.add_child(orb_row)
		_orb_rows[color] = orb_row

# ── Refresh all orbs when mana changes ───────────────────────────────────────

func _on_mana_changed(p: Player) -> void:
	if p == player:
		_refresh(p)

func _refresh(p: Player) -> void:
	# Get current pool and total (max) from mana zone cards
	var pool: Dictionary = p.mana_pool
	var total: Dictionary = _get_total_mana(p)

	for color in COLOR_ORDER:
		var available: int = pool.get(color, 0)
		var max_mana:  int = total.get(color, 0)

		var group: VBoxContainer = _groups[color]
		var orb_row: HBoxContainer = _orb_rows[color]

		# Hide the whole group if this color has never been generated
		group.visible = (max_mana > 0)
		if max_mana == 0:
			continue

		# Rebuild orbs if the count changed
		var current_count: int = orb_row.get_child_count()
		if current_count != max_mana:
			for child in orb_row.get_children():
				child.queue_free()
			for i in range(max_mana):
				orb_row.add_child(_make_orb(color))

		# Update filled vs spent state
		var orbs = orb_row.get_children()
		for i in range(orbs.size()):
			_set_orb_state(orbs[i], color, i < available)

# ── Orb creation ─────────────────────────────────────────────────────────────

func _make_orb(color: String) -> Control:
	var orb := ColorRect.new()
	orb.custom_minimum_size = ORB_SIZE
	orb.size = ORB_SIZE

	# Round it with a StyleBoxFlat
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left     = int(ORB_SIZE.x / 2)
	style.corner_radius_top_right    = int(ORB_SIZE.x / 2)
	style.corner_radius_bottom_left  = int(ORB_SIZE.x / 2)
	style.corner_radius_bottom_right = int(ORB_SIZE.x / 2)
	style.bg_color = MANA_COLORS.get(color, Color.GRAY)
	orb.add_theme_stylebox_override("panel", style)

	return orb

func _set_orb_state(orb: Control, color: String, is_filled: bool) -> void:
	var base_color: Color = MANA_COLORS.get(color, Color.GRAY)
	var target_color: Color = base_color if is_filled else base_color.darkened(0.6)
	target_color.a = 1.0 if is_filled else 0.35

	# Animate the color change
	var tween := orb.create_tween()
	tween.tween_property(orb, "modulate", target_color, 0.15)

# ── Total mana calculation ────────────────────────────────────────────────────
# Reads from the mana zone cards to know how many of each color exist this turn.

func _get_total_mana(p: Player) -> Dictionary:
	var total := { "generic": 0, "red": 0, "blue": 0, "green": 0,
				   "earth": 0, "white": 0, "black": 0 }
	if not p.player_mana_zone:
		return total
	for child in p.player_mana_zone.get_children():
		if child.is_in_group("card") and child.state:
			for color in child.state.mana_creation:
				if color in total:
					total[color] += 1
	return total
