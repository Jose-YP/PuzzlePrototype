extends CanvasLayer

#IMPORTED FROM RPG PROTOTYPE
@onready var VolumeValues: Array[HSlider] = [%MasterSlider, %MusicSlider, %SFXSlider]
@onready var VolumeTexts: Array[RichTextLabel] = [%MasterText, %MusicText, %SFXText]
@onready var controllerChange: Array[Button] = [%ui_up/ui_up, %ui_accept/ui_accept, %ui_left/ui_left,
%ui_cancel/ui_cancel, %ui_down/ui_down, %Flip/Flip, %ui_right/ui_right, %Break/Break]
@onready var MasterBus = AudioServer.get_bus_index("Master")
@onready var MusicBus = AudioServer.get_bus_index("Music")
@onready var SFXBus = AudioServer.get_bus_index("SFX")
@onready var beadColorPickers: Array = [%EarthColor, %SeaColor, %AirColor,
 %LightColor, %DarkColor, %BreakerColor]
@onready var beadExamples: Array[TabContainer] = [%Erth, %Sea, %Air, %Lght, %Dark, %Brek]

signal main
signal makeNoise
signal switchBG
signal testMusic(toggled_on)
signal playSFX(index)

const awaitText: String = "Awaiting Input"

var inputs: Array[Array] = [[],[]]
var inputTexts: Array[String] = []
var currentColors: Array[Color] = []
var Actions: Array = []
var Buses: Array = []
var userAudios: Array = []
var inputType: int = 0
var refocusLater: int
var currentToggleIndex: int
var currentAction: String
var toggleOn: bool = false
var resetting: bool = false
var currentToggle: Button
var currentInput: InputEvent

#-----------------------------------------
#INITALIZATION & PROCESSING
#-----------------------------------------
func _ready():
	Buses = [MasterBus, MusicBus, SFXBus]
	userAudios = [Globals.save.masterAudioLeve, Globals.save.musicAudioLeve, Globals.save.sfxAudioLeve]
	
	for i in range(VolumeValues.size()):
		audioSet(userAudios[i], i)
	
	inputType = Globals.save.input_type
	Globals.set_controls()
	
	currentColors = Globals.save.get_regular_colors()
	currentColors.append(Globals.save.breakerColor)
	
	for i in range(beadExamples.size() - 1):
		beadExamples[i].current_tab = i
	beadExamples[5].current_tab = 6
	
	$Main/VBox/Controls/VBox/InputType/HBoxContainer/OptionButton.selected = inputType
	getNewInputs()
	set_color_pickers()
	show_colors()
	$Main/VBox/HBoxContainer/Audio/IndvOptions/Tests/SFX.grab_focus()

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
			Globals.save.masterAudioLeve = value
		1:
			Globals.save.musicAudioLeve = value
		2:
			Globals.save.sfxAudioLeve = value
	Globals.save.save(Globals.NewgroundsToggle)

func _on_music_toggled(toggled_on) -> void:
	testMusic.emit(toggled_on)

func _on_sfx_pressed() -> void:
	makeNoise.emit()

#-----------------------------------------
#COLOR MAPPING
#-----------------------------------------
func set_color_pickers() -> void:
	for i in range(beadColorPickers.size()):
		var edit: ColorPicker = beadColorPickers[i].get_picker()
		
		beadColorPickers[i].color = currentColors[i]
		
		edit.set_picker_shape(edit.SHAPE_OKHSL_CIRCLE)
		edit.set_presets_visible(false)
		edit.set_sliders_visible(false)
		edit.set_modes_visible(false)

func show_colors() -> void:
	for i in range(beadExamples.size()):
		beadExamples[i].modulate = currentColors[i]

func set_colors(color: Color, index: int) -> void:
	currentColors[index] = color
	show_colors()

func save_colors():
	Globals.save.set_colors(currentColors)
	Globals.save.save(Globals.NewgroundsToggle)

func _on_reset_colors_pressed():
	Globals.save.reset_colors()
	currentColors = Globals.save.get_regular_colors()
	currentColors.append(Globals.save.breakerColor)
	for i in range(beadColorPickers.size()):
		beadColorPickers[i].color = currentColors[i]
	
	show_colors()

func _on_bg_color_pressed():
	switchBG.emit()

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
			loopActions = Globals.save.keyboard_action_events.keys()
		1:
			loopActions = Globals.save.joy_action_events.keys()
	
	for i in range(controllerChange.size()):#Controller change's parents have the right names
		Globals.show_controls(controllerChange[i].get_child(0))
		
		for j in range(loopActions.size()):
			if controllerChange[i].get_parent().name == loopActions[j]:
				sortedLoop.append(loopActions[j])
				break
	
	loopActions = sortedLoop
	
	for action in loopActions: #Get every input in InputMap that can be edited
		var events = InputMap.action_get_events(action)
		Actions.append(action)
		for event in events:
			if event is InputEventKey and inputType == 0:
				inputs[0].append(event)
				Globals.save.keyboard_action_events[action] = event
			elif event is InputEventJoypadButton and inputType == 1:
				inputs[1].append(event)
				Globals.save.joy_action_events[action] = event
	
	Globals.save.save(Globals.NewgroundsToggle)
	ControllerIcons.refresh()
	#updateInputDisplay()

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

func controllerMapStart(_toggled,index) -> void:
	if not resetting:
		var erase: bool = false
		if currentToggle != null:
			#I think this might be bad for the look of options but it might also be needed
			#currentToggle.button_pressed = toggled
			#Using Text inputs: inputTexts[currentToggleIndex]
			refocusLater = index
			erase = true
			currentToggle.text = ""
		
		currentAction = Actions[index]
		currentInput = inputs[inputType][index]
		currentToggleIndex = index
		currentToggle = controllerChange[index]
		if not erase:
			currentToggle.text = awaitText
		toggleOn = true

func _on_new_input_type_selected(index) -> void:
	inputType = index
	Globals.save.input_type = index
	Globals.save.save(Globals.NewgroundsToggle)
	
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
	reset_buttons()
	
	if controllerChange[refocusLater] != %ui_accept/ui_accept:
		controllerChange[refocusLater].grab_focus()
	else:
		#Find a way to get the focus back on the old button without pressing it again
		#A tiny delay is enough to make sure godot doesn't register the accept input instantly
		await get_tree().create_timer(.005).timeout
		controllerChange[refocusLater].grab_focus()

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
		button.release_focus()
		button.button_pressed = false
	resetting = false

#-----------------------------------------
#NAVIGATION BUTTONS
#-----------------------------------------
func _on_button_pressed() -> void:
	save_colors()
	Globals.set_colors()
	main.emit()
