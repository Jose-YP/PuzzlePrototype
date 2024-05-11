extends Node

func _ready():
	
	
	print(InputMap.action_get_events("ui_focus_next"))
	print(InputMap.action_get_events("ui_focus_prev"))
