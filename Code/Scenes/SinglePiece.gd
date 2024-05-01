extends Node2D

@export var pieces: Array[CompressedTexture2D]

var typeID: int = 0
var currentType: String = "Earth"

func _ready() -> void:
	typeID = randi_range(0,Globals.piece_types.size() - 1)
	currentType = Globals.piece_types[typeID]
	$TextureRect.texture = pieces[typeID]
	$TextureRect.modulate = Globals.piece_colors[typeID]

func _process(_delta) -> void:
	if rotation != 0:
		print("AA")
		rotation = 0
