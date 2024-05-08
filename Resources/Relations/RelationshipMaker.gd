extends Resource
class_name Relations

@export_range(2,5) var glow_num: int = 3

@export_flags("Earth","Sea","Air","Light","Dark") var earthRelations: int = 6
@export_flags("Earth","Sea","Air","Light","Dark") var seaRelations: int = 5
@export_flags("Earth","Sea","Air","Light","Dark") var airRelations: int = 3
@export_flags("Earth","Sea","Air","Light","Dark") var lightRelations: int = 16
@export_flags("Earth","Sea","Air","Light","Dark") var darkRelations: int = 8

@export_color_no_alpha var earthColor: Color = Color(0.631, 0.125, 0.125)
@export_color_no_alpha var seaColor: Color = Color(0.137, 0.6, 0.91)
@export_color_no_alpha var airColor: Color = Color(1,1,1)
@export_color_no_alpha var lightColor: Color = Color(0.898, 0.91, 0.137)
@export_color_no_alpha var darkColor: Color = Color(0.478, 0.071, 0.365)

@export var relationDisplay: PackedScene
