extends Control

@onready var charInputs: Array[Button] = [%First, %Second, %Third]
@onready var username: String = Globals.save.username
@onready var currentFocus: Button = %First

signal proceed

const characters: Array[String] = ["A","B","C","D","E","F","G","H","I","J","K","L",
"M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","0","1",
"2","3","4","5","6","7","8","9",".","?","!"]
const threshold: float = 1

var score: int = 0
var placement: int = 6
var currentIndex: int = 0
var held: float = 0.0
var nameIndexes: Array[int]
# Called when the node enters the scene tree for the first time.
func _ready():
	%First.grab_focus()
	
	$VBoxContainer/RichTextLabel.clear()
	$VBoxContainer/RichTextLabel.append_text(str("[center] Reached a High Score of ",score))
	$VBoxContainer/RichTextLabel2.clear()
	$VBoxContainer/RichTextLabel2.append_text(str("[center] Placed in ",convert_placement(placement)," place!"))
	nameIndexes = charIndex(username)
	print(nameIndexes)
	
	for i in range(charInputs.size()):
		charInputs[i].text = characters[nameIndexes[i]]

func _process(delta):
	var justorMore: bool = held == 0.0 or held > threshold
	
	if Input.is_action_pressed("ui_up") and justorMore:
		nameIndexes[currentIndex] += 1
		if nameIndexes[currentIndex] > characters.size() - 1:
			nameIndexes[currentIndex] = 0
		charInputs[currentIndex].text = characters[nameIndexes[currentIndex]]
	if Input.is_action_pressed("ui_down") and justorMore:
		nameIndexes[currentIndex] -= 1
		if nameIndexes[currentIndex] < 0:
			nameIndexes[currentIndex] = characters.size() - 1
		charInputs[currentIndex].text = characters[nameIndexes[currentIndex]]
	
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down"):
		held += delta
	if Input.is_action_just_released("ui_up") or Input.is_action_just_released("ui_down"):
		held = 0.0

func convert_placement(place):
	match place:
		1:
			return str(place,"st")
		2:
			return str(place,"nd")
		3:
			return str(place,"rd")
		_:
			return str(place,"th")

func charIndex(input) -> Array[int]:
	var indexes: Array[int] = []
	
	for letter in input:
		for i in range(characters.size()):
			if characters[i] == letter:
				indexes.append(i)
	return indexes

func _on_submit_pressed():
	var user: String
	for chara in charInputs:
		user = str(user, chara.text)
	
	Globals.save.username = user

func _on_focus_entered(index):
	print("focus on ", charInputs[index])
	currentFocus = charInputs[index]
	currentIndex = index
