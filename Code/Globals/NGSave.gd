extends Node

var save: Save
var save_dict: Dictionary

func _ready():
	add_to_group("CloudSave")

func _cloud_save():
	save = Globals.save.duplicate()
	save_dict = {
		"file" : save,
		"scores" : save.HiScores,
		"username" : save.username,
		
		"control_type" : save.input_type,
		"controls_key" : save.keyboard_action_events,
		"controls_joy" : save.joy_action_events,
		
		"earth_color" : save.earthColor,
		"sea_color" : save.seaColor,
		"air_color" : save.airColor,
		"light_color" : save.lightColor,
		"dark_color" : save.darkColor,
		"breaker_color" : save.breakerColor,
		
		"master" : save.masterAudioLeve,
		"music" : save.musicAudioLeve,
		"sfx" : save.sfxAudioLeve
	}
	
	return save_dict
