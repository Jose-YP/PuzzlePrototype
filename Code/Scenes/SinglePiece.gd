extends Node2D

@export var pieces: Array[CompressedTexture2D]

@onready var glow: Sprite2D = $Glow

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
	glow.modulate = Globals.piece_colors[typeID]

func update_adj() -> void:
	find_adjacent.emit(self)

func should_glow(refresh = false) -> void:
	if adjacent.size() == 0 or refresh:
		update_adj()
	
	for adj in adjacent:
		if adj == null:
			continue
		
		#if adj can but isn't linked to piece
		if adj.currentType == currentType and linkedPieces.find(adj) == -1:
			#if this piece isn't linked but can to adj
			if adj.linkedPieces.find(self) == -1:
				adj.linkedPieces.append(self)
				linkedPieces = adj.linkedPieces
			#link adj to 
			linkedPieces.append(adj)
			adj.linkedPieces = linkedPieces
			
		elif adj.typeFlag & Globals.relation_flags[typeID] and glowing and adj.glowing:
			should_connect(adj)
	
	if linkedPieces.size() >= Globals.glow_num:
		print(self,currentType, " links in ", linkedPieces)
		for piece in linkedPieces:
			piece.glow.show()
			glowing = true
	else:
		for piece in linkedPieces:
			piece.glow.hide()
			glowing = false

func should_connect(piece) -> void:
	var link = piece.connectedLinks.find(linkedPieces)
	print(currentType, " can connect with ", piece.currentType, link)
	#If they aren't already connected, connect the links
	if link == -1:
		connectedLinks.append(piece.linkedPieces)
		piece.connectedLinks.append(linkedPieces)
