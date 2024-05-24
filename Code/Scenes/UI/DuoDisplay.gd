extends Control

@export var beadTabs: Array[int] = [0,1,2,3,4]

func _ready():
	var beadImages = $Pieces.get_children()
	for i in range(beadImages.size()):
		beadImages[i].current_tab = beadTabs[i]
