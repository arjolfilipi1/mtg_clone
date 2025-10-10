extends CanvasLayer


@onready var panel: ColorRect = $Panel
@onready var message_label: Label = $VBoxContainer/Message
@onready var confirm_button: Button = $VBoxContainer/ButtonContainer/ConfirmButton
@onready var cancel_button: Button = $VBoxContainer/ButtonContainer/CancelButton
var meta:Callable 
var null_meta:Callable
func _ready() -> void:
	hide_confirm()
	# Connect button signals
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Optional: Connect to handle keyboard input
	confirm_button.focus_entered.connect(_on_focus_entered)
	cancel_button.focus_entered.connect(_on_focus_entered)

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
	hide()
	panel.hide()
	process_mode = Node.PROCESS_MODE_INHERIT

func _on_confirm_pressed() -> void:
	#confirmed.emit()
	print("confirmed")
	TurnManager.game_manager._on_overlay_confirmed()
	hide_confirm()

func _on_cancel_pressed() -> void:
	TurnManager.game_manager._on_overlay_cancelled()
	print("cancelled")
	hide_confirm()

func _on_focus_entered() -> void:
	# Play focus sound if desired
	pass

# Optional: Handle keyboard input
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()
