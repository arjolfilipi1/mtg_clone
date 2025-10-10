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

var original_position: Vector2
var diff: Vector2
var target_position: Vector2
var original_scale: Vector2
var is_attacking: bool = false
var can_attack: bool = true

#@onready var sprite: Sprite2D = $Sprite2D
@onready var trail_particles: GPUParticles2D = $"../../TrailParticles"

func _ready() -> void:
	
	if trail_particles:
		trail_particles.emitting = false

func start_slam_attack(direction: Vector2 = Vector2.RIGHT, custom_distance: float = 0.0) -> void:
	card= TurnManager.targeting
	print("attacked"+card.card_name +" defender "+target.card_name)
	original_position = card.position
	original_scale = card.scale
	diff = target.global_position - card.global_position 
	if not can_attack or is_attacking:
		return
	
	can_attack = false
	is_attacking = true
	
	
	target_position = target.global_position
	
	if trail_enabled and trail_particles:
		trail_particles.emitting = true
		
		# Use gravity or initial velocity instead of direction
		if trail_particles.process_material is ParticleProcessMaterial:
			# Set gravity to oppose movement direction
			trail_particles.process_material.gravity = Vector3(direction.x * -100, direction.y * -100, 0)
			
			# OR set initial velocity
			# trail_particles.process_material.initial_velocity_min = direction.length() * 50
			# trail_particles.process_material.initial_velocity_max = direction.length() * 100
	
	_slam_sequence()

func _slam_sequence() -> void:
	# Phase 1: Slam forward with squash effect
	var tween_slam = create_tween()
	tween_slam.set_parallel(true)  # Run animations in parallel
	
	# Position animation
	tween_slam.tween_method(_update_position, card.position,card.position + diff, slam_duration)
	
	# Scale animation (squash during movement)
	tween_slam.tween_method(_update_scale, original_scale, Vector2(original_scale.x * 1.1, original_scale.y * 0.9), slam_duration * 0.5)
	tween_slam.tween_method(_update_scale, Vector2(original_scale.x * 1.1, original_scale.y * 0.9), original_scale, slam_duration * 0.5)
	
	tween_slam.tween_callback(_on_slam_impact)
	
	# Phase 2: Return to original position with stretch effect
	var tween_return = create_tween()
	tween_return.set_parallel(true)
	
	tween_return.tween_method(_update_position, card.position + diff, original_position, return_duration)
	tween_return.tween_method(_update_scale, original_scale, Vector2(original_scale.x * 0.9, original_scale.y * 1.1), return_duration * 0.5)
	tween_return.tween_method(_update_scale, Vector2(original_scale.x * 0.9, original_scale.y * 1.1), original_scale, return_duration * 0.5)
	
	tween_return.tween_callback(_on_attack_complete)

func _update_position(new_position: Vector2) -> void:
	card.position = new_position

func _update_scale(new_scale: Vector2) -> void:
	card.scale = new_scale

func _on_slam_impact() -> void:
	# Impact scale effect
	var tween_impact = create_tween()
	tween_impact.tween_method(_update_scale, card.scale, impact_scale, 0.05)
	tween_impact.tween_method(_update_scale, impact_scale, original_scale, 0.1)
	
	_create_impact_effects()
	_screen_shake()


func _on_attack_complete() -> void:
	is_attacking = false
	
	# Stop trail effects
	if trail_particles:
		trail_particles.emitting = false
	
	# Reset to exact original values
	card.position = original_position
	card.scale = original_scale
	
	
	can_attack = true
	
	attack_finished.emit()

func _create_impact_effects() -> void:
	# Impact particles
	if has_node("ImpactParticles"):
		$ImpactParticles.emitting = true
	
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
