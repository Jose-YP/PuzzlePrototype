extends Node2D

@export var pieces: Array[CompressedTexture2D]
@export var connectedVFX: PackedScene

@onready var glow: Sprite2D = $Glow
@onready var connectPos: Array[Array] = [[%L1,%L2],[%R1,%R2],[%U1,%U2],[%D1,%D2]]

signal find_adjacent

var typeID: int = 0
var typeFlag: int = 1
var connectedNum: int = 0
var currentType: String = "Earth"
var connectedWith: Array[int] = [-1,-1,-1,-1]
var adjacent: Array = []
var linkedPieces: Array[Node] = [self]
var connectedLinks: Array[Array] = [linkedPieces]
var glowing: bool = false

func _ready() -> void:
	typeID = randi_range(0,Globals.piece_types.size() - 1)
	currentType = Globals.piece_types[typeID]
	typeFlag = Globals.string_to_flag(currentType)
	$Sprite.texture = pieces[typeID]
	$Sprite.modulate = Globals.piece_colors[typeID]
	glow.modulate = Globals.piece_colors[typeID]

func should_glow(skip = null) -> void:
	for i in range(adjacent.size()):
		var adj = adjacent[i]
		if adj == null:
			continue
		
		if adj.currentType == currentType:
			pass
		
		#if adj can but isn't linked to piece + make sure to skip same piece
		if adj.currentType == currentType and linkedPieces.find(adj) == -1 and adj != skip:
			link_pieces(adj)
			print(self,currentType, " Will check links with ", adj, adj.currentType)
			adj.should_glow(adj) #Find other pieces adj is linked to
	
	if linkedPieces.size() >= Globals.glow_num:
		print(self, " glows with ", linkedPieces)
		for piece in linkedPieces:
			piece.glow.show()
			glowing = true
			should_connect()
	else:
		for piece in linkedPieces:
			piece.glow.hide()
			glowing = false

func link_pieces(adj):
	#Add eachother to own links
	linkedPieces.append(adj)
	if adj.linkedPieces.find(self) == -1:
		adj.linkedPieces.append(self)
	
	#Sync links, if one has a larger link, sync them
	if adj.linkedPieces.size() >= linkedPieces.size():
		linkedPieces = adj.linkedPieces
	else:
		adj.linkedPieces = linkedPieces
	
	#If they still aren't the same, find what isn't in linked then sync the two
	if adj.linkedPieces != linkedPieces:
		for piece in linkedPieces:
			if adj.linkedPieces.find(piece) == -1:
				adj.linkedPieces.append(piece)
			linkedPieces = adj.linkedPieces

func should_connect():
	for i in range(adjacent.size()):
		var adj = adjacent[i]
		if adj == null or not adj.glowing:
			continue
		
		#Check if connections array has to updated when links update
		if adj.typeFlag & Globals.relation_flags[typeID] and connectedLinks.find(adj.linkedPieces) == -1:
			print("\n",self, adj.typeFlag, adj.currentType, Globals.relation_flags[typeID], currentType)
			make_connection(adj, i)

#Function is similar to link ver, might merge later
func make_connection(adj, linkWith) -> void:
	display_connection(linkWith,0)
	adj.display_connection(linkWith,1)
	#Check if the other piece already has a connection in 
	#link adj doesn't show up in link but does adj show up in link
	connectedLinks.append(adj.linkedPieces)
	if adj.connectedLinks.find(linkedPieces) == -1:
		adj.connectedLinks.append(linkedPieces)
	
	#Sync links, if one has a larger link, sync them
	if adj.connectedLinks.size() >= connectedLinks.size():
		connectedLinks = adj.connectedLinks
	else:
		adj.connectedLinks = connectedLinks
	
	#If they still aren't the same, find what isn't in linked then sync the two
	if adj.connectedLinks != connectedLinks:
		for piece in connectedLinks:
			if adj.connectedLinks.find(piece) == -1:
				adj.connectedLinks.append(linkedPieces)
			connectedLinks = adj.connectedLinks
	print(currentType, " can connect with ", adj.currentType," ", adj.connectedLinks)

func display_connection(direction,using) -> void:
	#Doesn't work
	var VFX: AnimatedSprite2D = connectedVFX.instantiate()
	add_child(VFX)
	VFX.position = connectPos[direction][using].position
	VFX.set_color(Globals.piece_colors[typeID])
	print(VFX.material)
	if direction > 1:
		VFX.rotation_degrees = VFX.horiRot
	else:
		VFX.rotation_degrees = -VFX.horiRot
