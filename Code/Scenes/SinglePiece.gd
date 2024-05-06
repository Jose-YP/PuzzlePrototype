extends Node2D

@export var pieces: Array[CompressedTexture2D]
@export var chainedVFX: PackedScene

@onready var linkArray: Node = $LinkArray
@onready var glow: Sprite2D = $Glow
@onready var chainPos: Array[Array] = [[%L1,%L2],[%R1,%R2],[%U1,%U2],[%D1,%D2]]
@onready var chainedLinks: Array[Node] = [self]

signal find_adjacent

var typeID: int = 0
var typeFlag: int = 1
var chainedNum: int = 0
var currentType: String = "Earth"
var chainedWith: Array[int] = [-1,-1,-1,-1]
var adjacent: Array = []
var chainNodes: Array = [null,null,null,null]
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
		
		var links: Dictionary = get_links()
		#if adj can but isn't linked to piece + make sure to skip same piece
		if adj.currentType == currentType and not links.has(adj) and adj != skip:
			link_pieces(adj)
			adj.should_glow(self) #Find other pieces adj is linked to
	for piece in get_links(true):
		piece.manage_glow()

func link_pieces(adj) -> void:
	#Sync links
	for piece in adj.get_links():
		set_links(piece)
	
	var link = get_links()
	#Keep every linked piece in the same order
	for piece in link:
		if piece.get_links() != link:
			piece.set_links(self)

func manage_glow() -> void:
	if get_links().size() >= Globals.glow_num:
		glow.show()
		glowing = true
	else:
		glow.hide()
		glowing = false

#______________________________
#MANAGING CONNECTIONS
#______________________________
func should_chain() -> void:
	for i in range(adjacent.size()):
		var adj = adjacent[i]
		if adj == null or not adj.glowing:
			continue
		
		#Check if chains array has to updated when links update
		if adj.typeFlag & Globals.relation_flags[typeID] and chainedLinks.find(adj) == -1:
			print("\n",self, adj.typeFlag, adj.currentType, Globals.relation_flags[typeID], currentType)
			make_chain(adj)
			if chainNodes[i] == null and adj.chainNodes[Globals.otherConnectionNum[i]] == null:
				display_chain(i,0)
				adj.display_chain(i,1)

func make_chain(adj) -> void:
	#Sync chains
	adj.set_chains(self)
	set_chains(adj)
	#Keep every linked piece in the same order
	print("\n",currentType, " can chain with ", adj.currentType," ", adj.get_all_chains())

func display_chain(direction,using) -> void:
	#Doesn't work
	var VFX: AnimatedSprite2D = chainedVFX.instantiate()
	$Connections.add_child(VFX)
	VFX.position = chainPos[direction][using].position
	VFX.set_color(Globals.piece_colors[typeID])
	print(VFX.material)
	if direction > 1:
		VFX.rotation_degrees = VFX.horiRot
	else:
		VFX.rotation_degrees = -VFX.horiRot
	#Add them to make sure they 
	if using == 0:
		chainNodes[direction] = VFX
	else:
		chainNodes[Globals.otherConnectionNum[direction]] = VFX

#______________________________
#GET SET VALUES
#______________________________
func get_links(array:bool = false):
	if array:
		return linkArray.linkedPieces.keys()
	else:
		return linkArray.linkedPieces

func set_links(value) -> void:
	get_links().merge(value.get_links())
	value.get_links().merge(get_links())

func get_all_chains() -> Array:
	var array: Array = []
	
	for value in chainedLinks:
		array.append(value.get_links())
	
	return array

func set_chains(value) -> void:
	var links: Dictionary = value.get_links()
	var alreadyThere: bool = false
	for piece in chainedLinks:
		if links.has(piece):
			alreadyThere = true
	
	if not alreadyThere:
		chainedLinks.append(value)
