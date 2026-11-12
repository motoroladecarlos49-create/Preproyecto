extends Node

var partida_actual: SaveGame = SaveGame.new()

var puerta_destino_id: String = "" 
var direccion_salida: String = "down"
var mochila_global: Mochila = null

# Banderas de tutoriales
var ya_aviso_inventario: bool = false
var ya_aviso_recoger: bool = false
var ya_aviso_puerta: bool = false
var tutorial_lampara_completado: bool = false 

# --- NUEVA VARIABLE TEMPORAL ---
var item_recien_tirado: bool = false 
# --------------------------------

# Escalas visuales para las escenas
var escala_item_escena1: float = 230.0 
var escala_item_escena2: float = 4.75  

func obtener_escala_item(escala_padre: float) -> float:
	if is_equal_approx(escala_padre, 0.01):
		return escala_item_escena1
	elif is_equal_approx(escala_padre, 0.26):
		return escala_item_escena2
	else:
		return 1.0

func guardar_partida():
	partida_actual.mochila = mochila_global
	ResourceSaver.save(partida_actual, "user://partida_guardada.tres")

func cargar_partida():
	if ResourceLoader.exists("user://partida_guardada.tres"):
		partida_actual = ResourceLoader.load("user://partida_guardada.tres")
		mochila_global = partida_actual.mochila

var is_dialogue_active = false
