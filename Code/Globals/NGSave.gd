extends Node

var save_dict: Dictionary
var save: Save
var scores = {"999999": [1000, "LVY"],
 "000000": [900, "ERN"],
 "111111": [800, "GAN"],
 "222222": [700, "MRA"],
 "333333": [600, "MLY"],
 "444444": [500, "NAN"]}
var username = "LVY"
#Copy pasted from a function
var control_type = 0
var controls_key = {"Break": 86, 
 "Flip": 67, 
 "ui_accept": 90, 
 "ui_cancel": 88, 
 "ui_down": 4194322, 
 "ui_left": 4194319,
 "ui_right": 4194321,
 "ui_up": 4194320}
var controls_joy = {"Break": 2, 
 "Flip": 3, 
 "ui_accept": 1, 
 "ui_cancel": 0, 
 "ui_down": 12, 
 "ui_left": 13, 
 "ui_right": 14, 
 "ui_up": 11}
#
var BGColor = 0
var earth_color = Color(0.886, 0.224, 0.212).to_html()
var sea_color = Color(0.137, 0.6, 0.91).to_html()
var air_color = Color(1,1,1).to_html()
var light_color = Color(0.898, 0.91, 0.137).to_html()
var dark_color = Color(0.843, 0.251, 0.663).to_html()
var breaker_color = Color(0.514, 0.969, 0.557).to_html()
#
var master = 70
var music = 70
var sfx = 70

#______________________________
#INITALIZATION
#______________________________
func _ready() -> void:
	add_to_group("CloudSave")

#______________________________
#SAVE MANAGEMENT
#______________________________
func _cloud_save() -> Dictionary:
	save_dict = {
		"file" : save,
		"scores" : scores,
		"username" : username,
		
		"control_type" : control_type,
		"controls_key" : controls_key,
		"controls_joy" : controls_joy,
		
		"BGColor" : BGColor,
		
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

func _cloud_set_property(property, value):
	match property:
		"scores":
			scores = value
		"username":
			username = value
		"control_type":
			control_type = value
		"controls_key":
			controls_key = value
		"controls_joy":
			controls_joy = value
		
		"BGColor":
			BGColor = value
		
		"earth_color":
			earth_color = value
		"sea_color":
			sea_color = value
		"air_color":
			air_color = value
		"light_color":
			light_color = value
		"dark_color":
			dark_color = value
		"breaker_color":
			breaker_color = value
		
		"master":
			master = value
		"music":
			music = value
		"sfx":
			sfx = value

func NG2Save() -> void:
	save = Globals.save
	if save.HiScores != scores:
		print(scores, save.HiScores)
		for id in save.HiScores:
			print(id, save.HiScores[id][0], save.HiScores[id][1])
			print(id, scores[id][0], scores[id][1])
		print(save.HiScores, scores)
		print("EJDVOJN")
	save.HiScores = scores
	if save.username != username:
		print(save.username, " | ",  username)
		print()
	save.username = username
	
	save.input_type = control_type
	save.keyboard_action_events = convert_keys_to_usable(controls_key)
	save.joy_action_events = convert_joys_to_usable(controls_joy)
	
	save.background_id = BGColor
	
	save.earthColor = Color(earth_color)
	save.seaColor = Color(sea_color)
	save.airColor = Color(air_color)
	save.lightColor = Color(light_color)
	save.darkColor = Color(dark_color)
	save.breakerColor = Color(breaker_color)
	
	save.masterAudioLeve = master
	save.musicAudioLeve = music
	save.sfxAudioLeve = sfx

func sync_files() -> void:
	save = Globals.save
	print(save.HiScores, save.username, save.joy_action_events)
	if save.HiScores != scores:
		print("DVODVKJ")
	scores = save.HiScores
	if save.username != username:
		print(save.username, " | ",  username)
		print()
	username = save.username
	
	control_type = save.input_type
	controls_key = convert_to_key_save(save.keyboard_action_events)
	controls_joy = convert_to_joy_save(save.joy_action_events)
	
	BGColor = save.background_id
	
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
	
	print("\n\n", keys)
	
	#For every key in the 
	for key in keys:
		local_dict[key] = InputEventKey.new()
		print(key, keys[key])
		
		if keys[key] is String:
			print("VDSOINSDVINO0")
			keys = set_inital_controls(0)
			local_dict[key].set_physical_keycode(keys[key])
		
		else:
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
		if joys[joy] is String:
			print("OH NO IUFEUFNIOFEJNOVDJNO")
			joys = set_inital_controls(1)
		
		if joys[joy] >= 0:
			local_dict[joy] = InputEventJoypadButton.new()
			local_dict[joy].set_button_index(joys[joy])
		else:
			#only get the button verison
			local_dict[joy] = InputEventJoypadMotion.new()
			local_dict[joy].set_axis(int((joys[joy] + 1) * -1))
	
	return local_dict

func set_inital_controls(type) -> Dictionary:
	var keyboard_action_events: Dictionary = {}
	var joy_action_events: Dictionary = {}
	InputMap.load_from_project_settings()
	const actions = ["Break","Flip","ui_accept","ui_cancel","ui_down","ui_left","ui_right","ui_up"]
	for action in actions:
		if type == 0:
			var events: Array[InputEvent] = InputMap.action_get_events(action)
			keyboard_action_events[action] = events[0].get_physical_keycode()
		else:
			var events: Array[InputEvent] = InputMap.action_get_events(action)
			joy_action_events[action] = events[1].get_button_index()
	
	if type == 0:
		return keyboard_action_events
	print(joy_action_events)
	return joy_action_events
