extends Node

var save_dict: Dictionary
var save: Save 
var scores
var username
#
var control_type
var controls_key
var controls_joy
#
var earth_color
var sea_color
var air_color
var light_color
var dark_color
var breaker_color
#
var master
var music
var sfx

func _ready():
	add_to_group("CloudSave")

func _cloud_save():
	save = Globals.save.duplicate()
	save_dict = {
		"file" : save,
		"scores" : scores,
		"username" : username,
		
		"control_type" : control_type,
		"controls_key" : controls_key,
		"controls_joy" : controls_joy,
		
		"earth_color" : earth_color,
		"sea_color" : sea_color,
		"air_color" : air_color,
		"light_color" : light_color,
		"dark_color" : dark_color,
		"breaker_color" : breaker_color,
		
		"master" : master,
		"music" : music,
		"sfx" : sfx
	}
	
	return save_dict

func convert_to_key_save(keys) -> Dictionary:
	var local_dict: Dictionary
	
	for key in keys:
		pass
	
	return local_dict

func convert_to_joy_save(joys) -> Dictionary:
	var local_dict: Dictionary
	
	for joy in joys:
		pass
	
	return local_dict

func NG2Save():
	for key in controls_key:
		if key is String:
			print(key)
			var asidn = OS.find_keycode_from_string(key)
			print(asidn)
			key = asidn
	
	save = Globals.save
	save.HiScores = scores
	save.username = username
	
	save.input_type = control_type
	save.keyboard_action_events = controls_key
	save.joy_action_events = controls_joy
	
	save.earthColor = Color.html(earth_color)
	save.seaColor = Color.html(sea_color)
	save.airColor = Color.html(air_color)
	save.lightColor = Color.html(light_color)
	save.darkColor = Color.html(dark_color)
	save.breakerColor = Color.html(breaker_color)
	
	save.masterAudioLeve = master
	save.musicAudioLeve = music
	save.sfxAudioLeve = sfx

func sync_files():
	save = Globals.save.duplicate()
	scores = save.HiScores
	username = save.username
	
	control_type = save.input_type
	controls_key = save.keyboard_action_events
	controls_joy = save.joy_action_events
	
	earth_color = save.earthColor.to_html()
	sea_color = save.seaColor.to_html()
	air_color = save.airColor.to_html()
	light_color = save.lightColor.to_html()
	dark_color = save.darkColor.to_html()
	breaker_color = save.breakerColor.to_html()
	
	master = save.masterAudioLeve
	music = save.musicAudioLeve
	sfx = save.sfxAudioLeve
