extends Control

@onready var nextBeads = $VBoxContainer/NextBeads

signal breakReady

var rules: Rules

# Called when the node enters the scene tree for the first time.
func update_next(beads):
	for i in range(3):
		nextBeads.update(i,beads[i])

func update_meter():
	pass
