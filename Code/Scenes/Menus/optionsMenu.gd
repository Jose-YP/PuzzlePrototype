extends CanvasLayer

#IMPORTED FROM RPG PROTOTYPE
@export var awaitingColor = Color(0.455, 0.455, 0.455)

@onready var VolumeValues: Array[HSlider] = [%MasterSlider, %MusicSlider, %SFXSlider]
@onready var VolumeTexts: Array[RichTextLabel] = [%MasterText, %MusicText, %SFXText]
@onready var controllerChange: Array[Button] = [%ui_up/ui_up, %ui_accept/ui_accept, %ui_left/ui_left,
%ui_cancel/ui_cancel, %ui_down/ui_down, %Flip/Flip, %ui_right/ui_right, %Break/Break]
@onready var MasterBus = AudioServer.get_bus_index("Master")
@onready var MusicBus = AudioServer.get_bus_index("Music")
@onready var SFXBus = AudioServer.get_bus_index("SFX")

signal main
signal makeNoise
signal testMusic(toggled_on)
signal playSFX(index)

var inputs: Array[Array] = [[],[]]
var inputTexts: Array[String] = []
var Actions: Array = []
var Buses: Array = []
var userAudios: Array = []
var inputType: int = 0
var currentToggleIndex: int
var currentAction: String
var currentToggle: Button
var toggleOn: bool = false
var resetting: bool = false
var currentInput: InputEvent

#-----------------------------------------
#INITALIZATION & PROCESSING
#-----------------------------------------
func _ready():
	Buses = [MasterBus, MusicBus, SFXBus]
	userAudios = [Globals.userPrefs.masterAudioLeve, Globals.userPrefs.musicAudioLeve, Globals.userPrefs.sfxAudioLeve]
	
	for i in range(VolumeValues.size()):
		audioSet(userAudios[i], i)
	
	inputType = Globals.userPrefs.input_type
	Globals.set_controls()
	
	$Main/VBox/Controls/VBox/InputType/HBoxContainer/OptionButton.selected = inputType
	getNewInputs()

func _input(event):
	if toggleOn:
		if inputType == 0:
			if event is InputEventKey:
				changeInput(event)
		else:
			if event is InputEventJoypadButton:
				changeInput(event)

#-----------------------------------------
#AUDIO
#-----------------------------------------
func audioSet(value, index) -> void:
	VolumeValues[index].value = value
	VolumeTexts[index].text = str("		",VolumeValues[index].value,"%")
	AudioServer.set_bus_volume_db(Buses[index], linear_to_db(value * 0.01)) #0.01 so it doesn't get too loud
	
	userAudios[index] = value * 0.01
	match index: #Has to be saved directly
		0:
			Globals.userPrefs.masterAudioLeve = value
		1:
			Globals.userPrefs.musicAudioLeve = value
		2:
			Globals.userPrefs.sfxAudioLeve = value
	Globals.userPrefs.save()

func _on_music_toggled(toggled_on) -> void:
	testMusic.emit(toggled_on)

func _on_sfx_pressed() -> void:
	makeNoise.emit()

#-----------------------------------------
#CONTROLLER REMAPPING
#-----------------------------------------
#WHEN INPORTING: RESET INPUT MAP RESOURCE MANUALLY ONCE
#RECONFIGURE SIGNAL INDEXES
#IF INPUT MAP NAMES CHANGE, CHANGE THE NAMES OF THE HBOXES
func getNewInputs() -> void:
	Actions = []
	inputs = [[],[]]
	var loopActions = InputMap.get_actions()
	var sortedLoop: Array = []
	
	match inputType:
		0:
			loopActions = Globals.userPrefs.keyboard_action_events.keys()
		1:
			loopActions = Globals.userPrefs.joy_action_events.keys()
	
	for i in range(controllerChange.size()):#Controller change's parents have the right names
		for j in range(loopActions.size()):
			if controllerChange[i].get_parent().name == loopActions[j]:
				sortedLoop.append(loopActions[j])
				break
	
	loopActions = sortedLoop
	
	for action in loopActions: #Get every input in InputMap that can be edited
		var events = InputMap.action_get_events(action)
		Actions.append(action)
		print(action, events)
		for event in events:
			if event is InputEventKey and inputType == 0:
				inputs[0].append(event)
				Globals.userPrefs.keyboard_action_events[action] = event
			elif event is InputEventJoypadButton and inputType == 1:
				inputs[1].append(event)
				Globals.userPrefs.joy_action_events[action] = event
	
	Globals.userPrefs.save()
	updateInputDisplay()

func updateInputDisplay() -> void:
	inputTexts.clear()
	
	for event in range(controllerChange.size()):
		var keyText: String
		if inputType == 0:
			keyText = inputs[inputType][event].as_text().trim_suffix(" (Physical)")
		elif inputs[inputType][event].as_text().contains("Button"):
			keyText = inputs[inputType][event].as_text().left(16)
		else:
			keyText = inputs[inputType][event].as_text().left(23)
		
		inputTexts.append(keyText)
		controllerChange[event].text = keyText

func controllerMapStart(toggled,index) -> void:
	if not resetting:
		if currentToggle != null:
			currentToggle.button_pressed = toggled
			currentToggle.text = inputTexts[currentToggleIndex]
		
		currentAction = Actions[index]
		currentInput = inputs[inputType][index]
		currentToggleIndex = index
		currentToggle = controllerChange[index]
		currentToggle.text = str("...Awaiting Input...")
		print(toggled,index)
		toggleOn = true

func _on_new_input_type_selected(index) -> void:
	inputType = index
	Globals.userPrefs.input_type = index
	Globals.userPrefs.save()
	getNewInputs()

func _on_reset_pressed() -> void:
	InputMap.load_from_project_settings()
	getNewInputs()

func changeInput(event) -> void:
	currentToggle.button_pressed = false
	InputMap.action_erase_event(currentAction, currentInput)
	InputMap.action_add_event(currentAction, event)
	toggleOn = false
	checkRepeats(currentInput, event)
	getNewInputs()
	Globals.set_other_inputs()
	reset_buttons()

func checkRepeats(oldEvent, event) -> void:
	var found: bool = false
	var repeat: String
	
	for action in Actions:
		if action == currentAction: continue
		
		if InputMap.event_is_action(event, action, true):
			found = true
			repeat = action
	
	if found:
		InputMap.action_erase_event(repeat, event)
		InputMap.action_add_event(repeat, oldEvent)

func reset_buttons() -> void:
	#find a way to prevent this from 
	resetting = true
	for button in controllerChange:
		button.button_pressed = false
	resetting = false

#-----------------------------------------
#NAVIGATION BUTTONS
#-----------------------------------------
func _on_button_pressed() -> void:
	main.emit()
