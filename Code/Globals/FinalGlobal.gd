extends Node

#FOR EVVERYTHING THAT NEEDS TO BE DONE LAST UPON LOADING THE GAME
func _ready() -> void:
	pass
	print(NG.save_slots)
	#if NG.save_slots.size() == 0:
		#NG.save_slots[1] = null

func finalReady(NG):
	if NG:
		Globals.NewgroundsToggle = true
		NGCloudSave.load_game()
		if NG.save_slots.size() == 0:
			NG.save_slots[1] = null
		NGCloudSave.loadSlot()
	else: Globals.NewgroundsToggle = false
