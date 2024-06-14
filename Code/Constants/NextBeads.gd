extends Control

@onready var nextBeads: Array[Control] = [%First, %Second, %Third]

func update(index,bead):
	nextBeads[index].fullBead = bead
	nextBeads[index].change_bead()
