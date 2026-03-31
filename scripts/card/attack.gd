extends Node2D
@onready var target:Card = $"../.."
@onready var card:Card

@export_group("Slam Settings")
@export var slam_duration: float = 0.2
@export var return_duration: float = 0.15

@export_group("Effects")
@export var shake_intensity: float = 5.0
@export var impact_scale: Vector2 = Vector2(1.2, 0.8)
@export var trail_enabled: bool = true

var original_global_position: Vector2
var original_position: Vector2
var diff: Vector2
var target_position: Vector2
var original_scale: Vector2
var is_attacking: bool = false
var can_attack: bool = true
var original_rotation:float
#@onready var sprite: Sprite2D = $Sprite2D
@onready var trail_particles: GPUParticles2D = $"../../TrailParticles"
# Track tweens
var current_tween: Tween = null
var slam_tween: Tween = null
var return_tween: Tween = null
var impact_tween: Tween = null

func _ready() -> void:
	
	if trail_particles:
		trail_particles.emitting = false
func _exit_tree():
	"""Clean up all tweens when node is removed"""
	_kill_all_tweens()

func _kill_all_tweens():
	"""Kill all active tweens"""
	if slam_tween and slam_tween.is_valid():
		slam_tween.kill()
		slam_tween = null
	
	if return_tween and return_tween.is_valid():
		return_tween.kill()
		return_tween = null
	
	if impact_tween and impact_tween.is_valid():
		impact_tween.kill()
		impact_tween = null
	
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		current_tween = null
func start_slam_attack(attacker, defender, direction: Vector2 = Vector2.RIGHT) -> void:
	# Kill any ongoing attack tweens
	_kill_all_tweens()
	
	attacker = attacker if attacker is Card else attacker.card_node
	defender = defender if defender is Card else defender.card_node
	TurnManager.waiting_for_input = true
	TurnManager._pass_priority()
	target = target if not defender else defender
	card = TurnManager.targeting if not attacker else attacker
	UI_Manager.targeting_arrow.complete_targeting()
	print("attacked " + card.state.card_name + " defender " + target.state.card_name)
	
	original_position = card.position
	original_scale = card.scale
	original_rotation = card.rotation
	diff = target.global_position - card.global_position
	
	if not can_attack or is_attacking:
		return
	
	can_attack = false
	is_attacking = true
	target_position = target.global_position
	
	if trail_enabled and trail_particles:
		if trail_particles.process_material is ParticleProcessMaterial:
			trail_particles.emitting = true
			trail_particles.process_material.gravity = Vector3(direction.x * -100, direction.y * -100, 0)
	
	_slam_sequence()

func _slam_sequence() -> void:
	original_global_position = card.global_position
	original_scale = card.scale
	
	var target_global_center = _get_control_center(target)
	var movement_vector = card.global_position - target_global_center
	var target_rotation = movement_vector.angle() - deg_to_rad(90)
	
	# Create slam tween
	slam_tween = create_tween()
	slam_tween.set_parallel(true)
	
	slam_tween.tween_property(card, "global_position", target_global_center, slam_duration)
	slam_tween.tween_property(card, "rotation", target_rotation, slam_duration * 0.3)
	slam_tween.tween_property(card, "scale", Vector2(original_scale.x * 1.1, original_scale.y * 0.9), slam_duration * 0.5)
	slam_tween.chain().tween_property(card, "scale", original_scale, slam_duration * 0.5)
	
	slam_tween.tween_callback(attack_back)

func _get_control_center(control: Control) -> Vector2:
	# For Control nodes, use global_position + size/2 to get the center
	# Also account for pivot and rotation if they exist
	var center_local = control.size * 0.5
	
	# If the control has pivot offset (custom pivot), use it
	if control.has_method("get_pivot_offset"):
		center_local = control.get_pivot_offset()
	elif control.has_property("pivot_offset"):
		center_local = control.pivot_offset
	
	# Convert local center to global position
	var center_global = control.global_position + center_local + Vector2(-100,0)
	
	# Account for rotation if the control is rotated
	if control.rotation != 0:
		# For Control nodes with rotation, we need to rotate the pivot point
		center_global = control.global_position + center_local.rotated(control.rotation)
	
	return center_global 

func attack_back():
	_on_slam_impact()
	
	# Create return tween
	return_tween = create_tween()
	var return_rotation = original_rotation
	return_tween.set_parallel(true)
	
	return_tween.tween_property(card, "rotation", return_rotation, return_duration * 0.3)
	return_tween.tween_property(card, "global_position", original_global_position, return_duration)
	return_tween.tween_property(card, "scale", Vector2(original_scale.x * 0.9, original_scale.y * 1.1), return_duration * 0.5)
	return_tween.chain().tween_property(card, "scale", original_scale, return_duration * 0.5)
	
	return_tween.tween_callback(_on_attack_complete)
func _update_position(new_position: Vector2) -> void:
	card.position = new_position

func _update_scale(new_scale: Vector2) -> void:
	card.scale = new_scale

func _on_slam_impact() -> void:
	# Create impact tween
	impact_tween = create_tween()
	impact_tween.tween_method(_update_scale, card.scale, impact_scale, 0.05)
	impact_tween.tween_method(_update_scale, impact_scale, original_scale, 0.1)
	
	_create_impact_effects()
	_screen_shake()


func _on_attack_complete() -> void:
	is_attacking = false
	TurnManager.waiting_for_input = false
	
	if trail_particles:
		trail_particles.emitting = false
	
	card.position = original_position
	card.scale = original_scale
	Game_Manager.cm.execute_attack(card, target, Game_Manager.gamestate)
	can_attack = true
	
	# Clean up tweens
	_kill_all_tweens()
	
	attack_finished.emit()

func _create_impact_effects() -> void:
	# Impact particles
	if has_node("ImpactParticles"):
		var red_color = Color.RED
		trail_particles.process_material.color = red_color
		
		# Optional: Configure for trail effect
		trail_particles.process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		trail_particles.process_material.spread = 10.0
		trail_particles.amount = 300
		trail_particles.lifetime = 0.5
	
	# Sound
	if has_node("ImpactSound"):
		$ImpactSound.play()
	
	# Flash effect (if you have a shader or animation)
	#=if sprite and sprite.material:
	#	_trigger_flash_effect()

#func _trigger_flash_effect() -> void:
	# Simple flash using modulate
	#var tween_flash = create_tween()
	#tween_flash.tween_property(sprite, "modulate", Color.WHITE * 2.0, 0.05)
	#tween_flash.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _screen_shake() -> void:
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(shake_intensity)



signal attack_finished
