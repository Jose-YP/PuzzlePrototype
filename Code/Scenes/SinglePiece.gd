extends Node2D

@export var pieces: Array[CompressedTexture2D]

signal find_adjacent

var typeID: int = 0
var typeFlag: int = 1
var connectedNum: int = 0
var currentType: String = "Earth"
var adjacent: Array = []
var linkedPieces: Array[Node]
var connectedLinks: Array[Array]
var glowing: bool = false

func _ready() -> void:
	typeID = randi_range(0,Globals.piece_types.size() - 1)
	currentType = Globals.piece_types[typeID]
	typeFlag = Globals.string_to_flag(currentType)
	$Sprite.texture = pieces[typeID]
	$Sprite.modulate = Globals.piece_colors[typeID]
	$Glow.modulate = Globals.piece_colors[typeID]

func update_adj() -> void:
	find_adjacent.emit(self)
	print(adjacent)

func should_glow(refresh = false) -> bool:
	if adjacent.size() == 0 or refresh:
		update_adj()
	
	for adj in adjacent:
		if adj == null:
			continue
		print("looking at ",adj.currentType, " ", adj)
		
		if adj.currentType == currentType and linkedPieces.find(adj) == -1:
			linkedPieces.append(adj)
			adj.linkedPieces = linkedPieces
		else:
			print(linkedPieces.find(adj)," ", linkedPieces)
	
	if linkedPieces.size() >= Globals.glow_num:
		for piece in linkedPieces:
			$Glow.show()
		return true
	else:
		print()
	
	return false
