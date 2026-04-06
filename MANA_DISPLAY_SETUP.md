# MANA DISPLAY — SETUP GUIDE
# ============================================================

# ── Scene setup (ManaDisplay.tscn) ───────────────────────────────────────────
#
# 1. Create a new scene: HBoxContainer → save as res://scenes/ManaDisplay.tscn
# 2. Attach ManaDisplay.gd as the script
# 3. Set these on the HBoxContainer:
#      - add_theme_constant_override("separation", 8)  ← gap between color groups
#      - size_flags_horizontal = SHRINK_CENTER
#
# That's it — the script builds all orb rows at runtime.

# ── Place in your main scene ──────────────────────────────────────────────────
#
# In main.tscn, add two instances of ManaDisplay.tscn:
#
#   PlayerManaDisplay  (anchored bottom-left, above the mana zone)
#     → Inspector: is_player_display = true
#
#   EnemyManaDisplay   (anchored top-left, below enemy mana zone)
#     → Inspector: is_player_display = false
#
# Suggested anchor positions (adjust to your layout):
#   Player:  anchor_left=0, anchor_bottom=1, offset = Vector2(20, -180)
#   Enemy:   anchor_left=0, anchor_top=0,    offset = Vector2(20,  120)

# ── How it works ──────────────────────────────────────────────────────────────
#
# On _ready:
#   - Waits for Game_Manager.setup_finished
#   - Grabs the right Player object
#   - Connects to player.mana_changed signal (already emitted by pay_for_card
#     and reset_mana in your Player.gd — no changes needed there)
#   - Builds one VBox per color, hidden by default
#
# On mana_changed:
#   - Reads mana_pool for current available mana per color
#   - Reads mana zone cards for total mana generated this turn
#   - Shows/hides color groups based on what's been generated
#   - Filled orbs = available, dimmed orbs = spent
#   - Animates the transition with a 0.15s tween

# ── Triggering the display update ─────────────────────────────────────────────
#
# Your Player.gd already emits mana_changed in two places:
#   - reset_mana()     → start of turn, all orbs go dim then refill
#   - pay_for_card()   → orbs dim as mana is spent
#
# If you add a "create_mana" phase where mana is generated mid-turn,
# call emit_signal("mana_changed", self) at the end of create_mana() too.
# You already have that in create_mana() — just confirm the signal fires
# after mana_pool is fully populated.

# ── Optional: color label ──────────────────────────────────────────────────────
#
# If you want a small color name or symbol under each orb group,
# add a Label child to each group in _build_ui():
#
#   var label := Label.new()
#   label.text = color.left(1).to_upper()   # "R", "B", "G" etc.
#   label.add_theme_font_size_override("font_size", 9)
#   label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
#   group.add_child(label)
#   _labels[color] = label
#
# Or use your existing mana symbol sprites instead of text:
#   var symbol := Sprite2D.new()
#   symbol.texture = load("res://assets/symbol/%s.png" % color)
#   symbol.scale = Vector2(0.4, 0.4)
#   group.add_child(symbol)
