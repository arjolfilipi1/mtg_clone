extends CanvasLayer


@onready var panel: ColorRect = $Panel
@onready var vb:  = $VBoxContainer
@onready var message_label: Label = $VBoxContainer/Message
@onready var confirm_button: Button = $VBoxContainer/ButtonContainer/ConfirmButton
@onready var cancel_button: Button = $VBoxContainer/ButtonContainer/CancelButton
var meta:Callable 
var null_meta:Callable
signal choice_selected(choice)
var created = false

func _ready() -> void:
	hide_confirm()
	# Connect button signals

	# Optional: Connect to handle keyboard input
	confirm_button.focus_entered.connect(_on_focus_entered)
	cancel_button.focus_entered.connect(_on_focus_entered)
	var center = get_viewport().get_visible_rect().size / 2
	panel.global_position = center
	vb.global_position = center
func show_confirm(message: String = "Are you sure?", confirm_text: String = "Yes", cancel_text: String = "Cancel") -> void:
	message_label.text = message
	confirm_button.text = confirm_text
	cancel_button.text = cancel_text
	
	show()
	panel.show()
	
	# Set process mode to pause underlying scene
	#process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Grab focus for keyboard navigation
	cancel_button.grab_focus()

func hide_confirm() -> void:
	message_label.text = "hidden"
	print("HIDE COFIRM")
	hide()
	panel.hide()
	panel.visible = false
	process_mode = Node.PROCESS_MODE_INHERIT

func _on_confirm_pressed() -> void:
	print("_on_confirm_pressed")
	hide_confirm()
	choice_selected.emit(confirm_button.text)
	if created:
		queue_free()
	

func _on_cancel_pressed() -> void:
	print("_on_cancel_pressed")
	choice_selected.emit(cancel_button.text)
	hide_confirm()
	if created:
		queue_free()
func _on_focus_entered() -> void:
	# Play focus sound if desired
	pass

# Optional: Handle keyboard input
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()
