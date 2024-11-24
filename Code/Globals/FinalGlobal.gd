extends Node

#FOR EVVERYTHING THAT NEEDS TO BE DONE LAST UPON LOADING THE GAME
func _ready() -> void:
	pass
	print(NG.save_slots)
	#if NG.save_slots.size() == 0:
		#NG.save_slots[1] = null

func finalReady(use_NG):
	if use_NG:
		Globals.NewgroundsToggle = true
		#Everything is set to null here for some reason
		NGCloudSave.load_game()
		if NG.save_slots.size() == 0:
			NG.save_slots[1] = null
		
		NGCloudSave.save_game()
		NGSaveSetup.NG2Save()
		
		Globals.display = Globals.sort_scores()
		Globals.set_other_inputs(false)
		Globals.set_controls()
		Globals.set_colors()
		Globals.set_volume()
		
	else: Globals.NewgroundsToggle = false


