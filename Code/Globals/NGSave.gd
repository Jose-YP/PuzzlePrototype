extends Node

var save: Save
var save_dict: Dictionary

func _ready():
	add_to_group("CloudSave")

func _cloud_save():
	print(Globals.save)
	save_dict = {
		"file" : Globals.save,
		"scores" : Globals.save.HiScores,
		"username" : Globals.save.username,
		
		"control_type" : Globals.save.input_type,
		"controls_key" : Globals.save.keyboard_action_events,
		"controls_joy" : Globals.save.joy_action_events,
		
		"earth_color" : Globals.save.earthColor,
		"sea_color" : Globals.save.seaColor,
		"air_color" : Globals.save.airColor,
		"light_color" : Globals.save.lightColor,
		"dark_color" : Globals.save.darkColor,
		"breaker_color" : Globals.save.breakerColor,
		
		"master" : Globals.save.masterAudioLeve,
		"music" : Globals.save.musicAudioLeve,
		"sfx" : Globals.save.sfxAudioLeve
	}
	
	return save_dict

