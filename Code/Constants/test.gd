extends Control

@onready var buttons = [$TextureButton, $TextureButton2, $TextureButton3]

# Called when the node enters the scene tree for the first time.
func _ready():
	$TextureButton.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right")
	 or Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("ui_up")):
		print("Move")
		for button in buttons: 
			print(button, button.texture_normal, button.animations.get_assigned_animation())
			
		print(get_viewport().gui_get_focus_owner())
		print()
		
