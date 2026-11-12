extends Resource
class_name Item

@export var nombre: String
@export var icono: Texture2D
@export var apilable: bool = true
@export var cantidad: int = 1
@export var max_cantidad: int = 16

# Variable para recordar de qué posición original viene el ítem
var id_escena: String = "" 
