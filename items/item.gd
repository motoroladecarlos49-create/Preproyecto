extends Resource
class_name Item

@export var nombre: String
@export var icono: Texture2D
@export var apilable: bool = true
@export var cantidad: int = 1
@export var max_cantidad: int = 16

# Se exporta para conservar el identificador al serializar el recurso.
@export var id_escena: String = ""
