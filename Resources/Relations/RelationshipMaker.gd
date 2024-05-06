extends Resource
class_name Relations

@export_range(2,5) var glow_num: int = 3

@export_flags("Earth","Sea","Air","Light","Dark") var earthRelations: int = 6
@export_flags("Earth","Sea","Air","Light","Dark") var seaRelations: int = 5
@export_flags("Earth","Sea","Air","Light","Dark") var airRelations: int = 3
@export_flags("Earth","Sea","Air","Light","Dark") var lightRelations: int = 16
@export_flags("Earth","Sea","Air","Light","Dark") var darkRelations: int = 8

@export var relationDisplay: PackedScene
