# AttackArrow.gd
extends Path2D

@export var curve_length := 500.0
@export var animation_speed := 5.0
@export var color_normal := Color(1, 0.2, 0.2)
@export var color_valid := Color(0.19, 0.95, 0.32)
@export var color_invalid := Color(0.5, 0.5, 0.5)

@onready var path_follow := $ArrowHead
@onready var arrow_head := $ArrowHead/ArrowHeadSprite
@onready var arrow_trail := $ArrowTrail

var is_active := false
var current_target = null
var valid_targets := []

func _ready():
	hide()
	arrow_trail.default_color = color_normal

func _process(delta):
	if is_active:
		path_follow.progress += animation_speed
		if path_follow.progress_ratio >= 1.0:
			path_follow.progress_ratio = 0.0
		
		update_trail()

func start_attack(from_position: Vector2, to_position: Vector2, targets: Array):
	show()
	is_active = true
	valid_targets = targets
	
	# Create curved path
	var curve = Curve2D.new()
	curve.add_point(Vector2.ZERO)
	
	# Calculate control point for nice arc
	var mid_point = (from_position + to_position) * 0.5
	var control_offset = Vector2(0, -curve_length)
	if from_position.x > to_position.x:
		control_offset.y *= -1
	
	curve.add_point(to_position - from_position, Vector2.ZERO, control_offset)
	self.curve = curve
	
	# Position the arrow
	global_position = from_position
	update_target_visual(to_position)

func update_target_visual(target_position: Vector2):
	var is_valid = false
	for target in valid_targets:
		if target.global_position.distance_to(target_position) < 50.0:
			current_target = target
			is_valid = true
			break
	
	arrow_trail.default_color = color_valid if is_valid else color_invalid
	arrow_head.modulate = color_valid if is_valid else color_invalid

func confirm_attack():
	if current_target and current_target in valid_targets:
		return current_target
	return null

func cancel_attack():
	hide()
	is_active = false

func update_trail():
	var point_count = 20
	arrow_trail.clear_points()
	
	for i in range(point_count + 1):
		path_follow.progress_ratio = float(i) / point_count
		arrow_trail.add_point(path_follow.position)
