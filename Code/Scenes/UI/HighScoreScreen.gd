extends Control

@onready var charInputs: Array[LineEdit] = [%First, %Second, %Third]
@onready var username: String = Globals.save.username

signal proceed

const characters: Array[String] = ["A","B","C","D","E","F","G","H","I","J","K","L",
"M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","0","1",
"2","3","4","5","6","7","8","9",".","?","!"]

var score: int = 0
var placement: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/RichTextLabel.clear()
	$VBoxContainer/RichTextLabel.append_text(str("[center] Reached a High Score of ",score))
	$VBoxContainer/RichTextLabel2.clear()
	$VBoxContainer/RichTextLabel2.append_text(str("[center] Placed in ",score))
	var nameIndexes = charIndex(username)
	print(nameIndexes)
	
	for i in range(charInputs.size()):
		charInputs[i].text = characters[nameIndexes[i]]

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
