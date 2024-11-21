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
var BGColor
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

#______________________________
#INITALIZATION
#______________________________
func _ready() -> void:
	add_to_group("CloudSave")

#______________________________
#SAVE MANAGEMENT
#______________________________
func _cloud_save() -> Dictionary:
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

func NG2Save() -> void:
	save = Globals.save
	save.HiScores = scores
	print("CURRENT: ", save.HiScores, "REPLACE WITH: ", scores)
	save.username = username
	
	save.input_type = control_type
	save.keyboard_action_events = convert_keys_to_usable(controls_key)
	save.joy_action_events = convert_joys_to_usable(controls_joy)
	
	save.earthColor = Color.html(earth_color)
	save.seaColor = Color.html(sea_color)
	save.airColor = Color.html(air_color)
	save.lightColor = Color.html(light_color)
	save.darkColor = Color.html(dark_color)
	save.breakerColor = Color.html(breaker_color)
	
	save.masterAudioLeve = master
	save.musicAudioLeve = music
	save.sfxAudioLeve = sfx

func sync_files() -> void:
	save = Globals.save.duplicate()
	print(save.HiScores, save.username, save.joy_action_events)
	scores = save.HiScores
	username = save.username
	
	control_type = save.input_type
	controls_key = convert_to_key_save(save.keyboard_action_events)
	controls_joy = convert_to_joy_save(save.joy_action_events)
	
	earth_color = save.earthColor.to_html()
	sea_color = save.seaColor.to_html()
	air_color = save.airColor.to_html()
	light_color = save.lightColor.to_html()
	dark_color = save.darkColor.to_html()
	breaker_color = save.breakerColor.to_html()
	
	master = save.masterAudioLeve
	music = save.musicAudioLeve
	sfx = save.sfxAudioLeve

#______________________________
#CONVERSION
#______________________________
func convert_to_key_save(keys) -> Dictionary:
	var local_dict: Dictionary = {}
	print("CONVERTING")
	
	for key in keys:
		local_dict[key] = keys[key].get_physical_keycode() 
	
	return local_dict

func convert_keys_to_usable(keys) -> Dictionary:
	var local_dict: Dictionary = {}
	
	for key in keys:
		local_dict[key] = InputEventKey.new()
		local_dict[key].set_physical_keycode(keys[key])
	
	return local_dict

func convert_to_joy_save(joys) -> Dictionary:
	var local_dict: Dictionary = {}
	
	for joy in joys:
		if joys[joy] is InputEventJoypadButton:
			local_dict[joy] = joys[joy].get_button_index()
		else:
			#Convert the axis into something that won't be detected by a joy button
			local_dict[joy] = (int(joys[joy].get_axis()) * -1) - 1
	
	return local_dict

func convert_joys_to_usable(joys) -> Dictionary:
	var local_dict: Dictionary = {}
	
	for joy in joys:
		if joys[joy] >= 0:
			local_dict[joy] = InputEventJoypadButton.new()
			local_dict[joy].set_button_index(joys[joy])
		else:
			#only get the button verison
			local_dict[joy] = InputEventJoypadMotion.new()
			local_dict[joy].set_axis(int((joys[joy] + 1) * -1))
	
	return local_dict

