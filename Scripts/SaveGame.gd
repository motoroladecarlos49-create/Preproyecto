extends Resource
class_name SaveGame

@export var mochila: Mochila
@export var items_tirados: Array[Dictionary] = []
@export var items_recogidos: Array[String] = []
@export var escena_actual: String = ""
@export var posicion_jugador: Vector2 = Vector2.ZERO
@export var clave_item_seleccionado: String = ""
@export var linterna_encendida: bool = false

@export var ya_aviso_inventario: bool = false
@export var ya_aviso_recoger: bool = false
@export var ya_aviso_puerta: bool = false
@export var tutorial_lampara_completado: bool = false
@export var ya_aviso_salida_3d: bool = false
