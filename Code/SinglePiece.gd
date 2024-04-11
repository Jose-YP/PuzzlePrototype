extends Node2D

@export var pieces: Array[CompressedTexture2D]

const piece_types: Array = ["Earth","Liquid","Air","Light","Dark"]

var typeID: int = 0
var currentType: String = "Earth"

func _ready():
	typeID = randi_range(0,piece_types.size() - 1)
	currentType = piece_types[typeID]
	$TextureRect.texture = pieces[typeID]
