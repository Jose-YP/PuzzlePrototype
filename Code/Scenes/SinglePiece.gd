extends Node2D

@export var pieces: Array[CompressedTexture2D]
@export var connectedVFX: PackedScene

@onready var glow: Sprite2D = $Glow
@onready var connectPos: Array[Array] = [[%L1,%L2],[%R1,%R2],[%U1,%U2],[%D1,%D2]]
@onready var connectedLinks: Array[Node] = [self]

signal find_adjacent

var typeID: int = 0
var typeFlag: int = 1
var connectedNum: int = 0
var currentType: String = "Earth"
var connectedWith: Array[int] = [-1,-1,-1,-1]
var adjacent: Array = []

var connectNodes = [null,null,null,null]
var glowing: bool = false

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	typeID = randi_range(0,Globals.piece_types.size() - 1)
	currentType = Globals.piece_types[typeID]
	typeFlag = Globals.string_to_flag(currentType)
	$Sprite.texture = pieces[typeID]
	$Sprite.modulate = Globals.piece_colors[typeID]
	glow.modulate = Globals.piece_colors[typeID]

#______________________________
#MANAGING LINKS
#______________________________
func should_glow(skip = null) -> void:
	find_adjacent.emit(self)
	for i in range(adjacent.size()):
		var adj = adjacent[i]
		if adj == null:
			continue
		
		if adj.currentType == currentType:
			pass
		
		var links = get_links()
		print(adj,skip)
		#if adj can but isn't linked to piece + make sure to skip same piece
		if adj.currentType == currentType and links.find(adj) == -1 and adj != skip:
			link_pieces(adj)
			print(self,currentType, " Will check links with ", adj, adj.currentType)
			adj.should_glow(self) #Find other pieces adj is linked to
	
	var finalLink = get_links()
	if finalLink.size() >= Globals.glow_num:
		print(self, " glows with ", finalLink)
		for piece in finalLink:
			piece.glow.show()
			glowing = true
			should_connect()
	else:
		for piece in finalLink:
			piece.glow.hide()
			glowing = false

func link_pieces(adj) -> void:
	#Sync links
	for piece in adj.get_links():
		append_links(piece)
		piece.append_links(self)
	
	var link = get_links()
	#Keep every linked piece in the same order
	for piece in link:
		if piece.get_links() == link:
			piece.sync_links(self)

#______________________________
#MANAGING CONNECTIONS
#______________________________
func should_connect() -> void:
	for i in range(adjacent.size()):
		var adj = adjacent[i]
		if adj == null or not adj.glowing:
			continue
		
		#Check if connections array has to updated when links update
		if adj.typeFlag & Globals.relation_flags[typeID] and connectedLinks.find(adj) == -1:
			print("\n",self, adj.typeFlag, adj.currentType, Globals.relation_flags[typeID], currentType)
			make_connection(adj)
			if connectNodes[i] == null and adj.connectNodes[Globals.otherConnectionNum[i]] == null:
				display_connection(i,0)
				adj.display_connection(i,1)

func make_connection(adj) -> void:
	#Sync connections
	adj.set_connections(self)
	set_connections(adj)
	#Keep every linked piece in the same order
	print("\n",currentType, " can connect with ", adj.currentType," ", adj.get_all_connections())

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

#______________________________
#GET SET VALUES
#______________________________
func get_links() -> Array:
	return $LinkArray.linkedPieces

func set_links(value) -> void:
	$LinkArray.linkedPieces = value

func append_links(value) -> void:
	if $LinkArray.linkedPieces.find(value) == -1:
		$LinkArray.linkedPieces.append(value)

func sync_links(adj) -> void:
	if adj.get_links() != get_links():
		adj.set_links(get_links())

func get_all_connections() -> Array:
	var array: Array = []
	
	for value in connectedLinks:
		array.append(value.get_links())
	
	return array

func set_connections(value) -> void:
	if connectedLinks.find(value) == -1:
		connectedLinks.append(value)
