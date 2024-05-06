extends Node2D

@export var beads: Array[CompressedTexture2D]
@export var connectedVFX: PackedScene
@export_range(0,.5,.01) var burnTiming: float = .05

@onready var linkArray: Node = $LinkArray
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
var connectNodes: Array = [null,null,null,null]
var glowing: bool = false
var willDie: bool = false

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	typeID = randi_range(0,Globals.bead_types.size() - 1)
	currentType = Globals.bead_types[typeID]
	typeFlag = Globals.string_to_flag(currentType)
	$Sprite/Sprite.texture = beads[typeID]
	$Sprite.modulate = Globals.bead_colors[typeID]
	glow.modulate = Globals.bead_colors[typeID]
	print(Globals.bead_colors[typeID])
	$Free.wait_time = burnTiming + 1

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
		print(adj,skip)
		#if adj can but isn't linked to bead + make sure to skip same bead
		if adj.currentType == currentType and not links.has(adj) and adj != skip:
			print("A")
			link_beads(adj)
			print(self,currentType, " Will check links with ", adj, adj.currentType)
			adj.should_glow(self) #Find other beads adj is linked to
	print(self, get_links(true))
	for bead in get_links(true):
		bead.manage_glow()

func link_beads(adj) -> void:
	#Sync links
	for bead in adj.get_links():
		set_links(bead)
	
	var link = get_links()
	#Keep every linked bead in the same order
	print("\n\n->", self, link)
	for bead in link:
		print(bead,bead.get_links(true)," Sync ",bead.get_links() != link)
		if bead.get_links() != link:
			bead.set_links(self)

func manage_glow() -> void:
	print(self, get_links(true))
	if get_links().size() >= Globals.glow_num:
		glow.show()
		glowing = true
	else:
		print(get_links(true).size())
		glow.hide()
		glowing = false

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
	#Keep every linked bead in the same order
	print("\n",currentType, " can connect with ", adj.currentType," ", adj.get_all_connections())

func display_connection(direction,using) -> void:
	#Doesn't work
	var VFX: AnimatedSprite2D = connectedVFX.instantiate()
	$Connections.add_child(VFX)
	VFX.position = connectPos[direction][using].position
	VFX.set_color(Globals.bead_colors[typeID])
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
func get_links(array:bool = false):
	if array:
		return linkArray.linkedPieces.keys()
	else:
		return linkArray.linkedPieces

func set_links(value) -> void:
	get_links().merge(value.get_links())
	value.get_links().merge(get_links())

func get_all_connections() -> Array:
	var array: Array = []
	
	for value in connectedLinks:
		array.append(value.get_links())
	
	return array

func set_connections(value) -> void:
	if connectedLinks.find(value) == -1:
		connectedLinks.append(value)

#______________________________
#DESTROYING PIECES
#______________________________
func destroy_anim():
	#Destroy connections
	for bolt in $Connections.get_children():
		bolt.fade_tweenout()
	
	#Destroy bead
	var tween = get_tree().create_tween()
	tween.tween_method(set_burn, 1.0, 0.0, burnTiming)

func set_burn(value):
	material.set_shader_parameter("dissolve_value",value)

func _on_free_timeout():
	queue_free()
