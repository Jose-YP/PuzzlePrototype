extends Control

@onready var nextBeads: Array[Control] = [%Control, %Control2, %Control3]

func update(index,bead):
	nextBeads[index].fullBead = bead
	nextBeads[index].change_bead()
