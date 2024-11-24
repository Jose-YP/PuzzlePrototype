extends Node

#FOR EVVERYTHING THAT NEEDS TO BE DONE LAST UPON LOADING THE GAME
func _ready() -> void:
	pass
	print(NG.save_slots)
	#if NG.save_slots.size() == 0:
		#NG.save_slots[1] = null

func finalReady(use_NG):
	if use_NG:
		await NG.sign_in()
		Globals.NewgroundsToggle = true
		#Everything is set to null here for some reason
		NGCloudSave.load_game()
		
		await get_tree().create_timer(1.5).timeout
		
		NGSaveSetup.NG2Save()
		NGCloudSave.save_game()
		
		Globals.display = Globals.sort_scores()
		Globals.set_other_inputs(false)
		Globals.set_controls()
		Globals.set_colors()
		Globals.set_volume()
		
		#How do I get NG.save slots ready before this?
		if NG.save_slots.size() == 0:
			print(NG.save_slots)
			#NG.save_slots[0] = null
		
	else: Globals.NewgroundsToggle = false


