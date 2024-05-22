extends Node

#FOR EVVERYTHING THAT NEEDS TO BE DONE LAST UPON LOADING THE GAME
func _ready() -> void:
	#
	pass

func finalReady(NG):
	if NG:
		Globals.NewgroundsToggle = true
		NGCloudSave.load_game()
	else: Globals.NewgroundsToggle = false
