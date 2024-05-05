extends Node2D

@export var pieces: Array[CompressedTexture2D]
@export var connectedVFX: PackedScene

@onready var glow: Sprite2D = $Glow
@onready var connectPos: Array[Array] = [[%L1,%L2],[%R1,%R2],[%U1,%U2],[%D1,%D2]]
@onready var Links = $LinkArray
@onready var connectedLinks: Array[Array] = [$LinkArray.linkedPieces]

signal find_adjacent

var typeID: int = 0
var typeFlag: int = 1
var connectedNum: int = 0
var currentType: String = "Earth"
var connectedWith: Array[int] = [-1,-1,-1,-1]
var adjacent: Array = []

var connectNodes = [null,null,null,null]
var glowing: bool = false

func _ready() -> void:
	typeID = randi_range(0,Globals.piece_types.size() - 1)
	currentType = Globals.piece_types[typeID]
	typeFlag = Globals.string_to_flag(currentType)
	$Sprite.texture = pieces[typeID]
	$Sprite.modulate = Globals.piece_colors[typeID]
	glow.modulate = Globals.piece_colors[typeID]

func should_glow(skip = null) -> void:
	find_adjacent.emit(self)
	for i in range(adjacent.size()):
		var adj = adjacent[i]
		if adj == null:
			continue
		
		if adj.currentType == currentType:
			pass
		
		var linkedPieces = $LinkArray.linkedPieces
		print(adj,skip)
		#if adj can but isn't linked to piece + make sure to skip same piece
		if adj.currentType == currentType and linkedPieces.find(adj) == -1 and adj != skip:
			link_pieces(adj)
			print(self,currentType, " Will check links with ", adj, adj.currentType)
			adj.should_glow(self) #Find other pieces adj is linked to
		
	if $LinkArray.linkedPieces.size() >= Globals.glow_num:
		print(self, " glows with ", $LinkArray.linkedPieces)
		for piece in $LinkArray.linkedPieces:
			piece.glow.show()
			glowing = true
			should_connect()
	else:
		for piece in $LinkArray.linkedPieces:
			piece.glow.hide()
			glowing = false

func link_pieces(adj):
	#Sync links
	var linkedPieces = $LinkArray.linkedPieces
	for piece in adj.linkedPieces:
		if piece.linkedPieces.find(self) == -1:
			piece.linkedPieces.append(self)
		if linkedPieces.find(piece) == -1:
			linkedPieces.append(piece)
	#Keep every linked piece in the same order
	for piece in linkedPieces:
		if piece.linkedPieces == linkedPieces:
			piece.linkedPieces = linkedPieces
	
func should_connect():
	for i in range(adjacent.size()):
		var adj = adjacent[i]
		if adj == null or not adj.glowing:
			continue
		
		#Check if connections array has to updated when links update
		if adj.typeFlag & Globals.relation_flags[typeID] and connectedLinks.find(adj.linkedPieces) == -1:
			print("\n",self, adj.typeFlag, adj.currentType, Globals.relation_flags[typeID], currentType)
			make_connection(adj)
			adj.make_connection(self)
			if connectNodes[i] == null and adj.connectNodes[Globals.otherConnectionNum[i]] == null:
				display_connection(i,0)
				adj.display_connection(i,1)

func make_connection(adj) -> void:
	#Sync connections
	var linkedPieces = $LinkArray.linkedPieces
	if adj.connectedLinks.find(linkedPieces) == -1:
		adj.connectedLinks.append(linkedPieces)
	if connectedLinks.find(adj.connectedLinks) == -1:
		connectedLinks.append(adj.linkedPieces)
	#Keep every linked piece in the same order
	if adj.connectedLinks != connectedLinks:
		adj.connectedLinks = connectedLinks
	print("\n",currentType, " can connect with ", adj.currentType," ", adj.connectedLinks)

func sync_arrays(adj, array):
	for item in array:
		if adj.array.find(item) == -1:
			adj.array.append(item)

func display_connection(direction,using) -> void:
	#Doesn't work
	var VFX: AnimatedSprite2D = connectedVFX.instantiate()
	$Connections.add_child(VFX)
	VFX.position = connectPos[direction][using].position
	VFX.set_color(Globals.piece_colors[typeID])
	print(VFX.material)
	if direction > 1:
		VFX.rotation_degrees = VFX.horiRot
	else:
		VFX.rotation_degrees = -VFX.horiRot
	#Add them to make sure they 
	if using == 0:
		connectNodes[direction] = VFX
	else:
		connectNodes[Globals.otherConnectionNum[direction]] = VFX
