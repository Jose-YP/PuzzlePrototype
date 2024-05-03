extends Node2D

@export var pieces: Array[CompressedTexture2D]

var typeID: int = 0
var typeFlag: int = 1
var currentType: String = "Earth"
var linkedPieces: Array[Node]
var connectedLinks: Array[Array]
var glowing: bool = false

func _ready() -> void:
	typeID = randi_range(0,Globals.piece_types.size() - 1)
	currentType = Globals.piece_types[typeID]
	typeFlag = Globals.string_to_flag(currentType)
	$Sprite.texture = pieces[typeID]
	$Sprite.modulate = Globals.piece_colors[typeID]

func should_glow(adjacent) -> bool:
	return false
