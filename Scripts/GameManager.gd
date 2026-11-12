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


# Registra los objetos soltados junto con la habitación y su posición global.
func registrar_item_tirado(id: String, item_data: Item, posicion: Vector2, escena: String) -> void:
	quitar_item_tirado(id)
	partida_actual.items_tirados.append({
		"id": id,
		"data": item_data,
		"posicion": posicion,
		"escena": escena
	})

func quitar_item_tirado(id: String) -> void:
	if id == "":
		return
	for i in range(partida_actual.items_tirados.size() - 1, -1, -1):
		if str(partida_actual.items_tirados[i].get("id", "")) == id:
			partida_actual.items_tirados.remove_at(i)

# Vuelve a crear únicamente los objetos que pertenecen a la habitación actual.
func restaurar_items_tirados(raiz_escena: Node) -> void:
	if raiz_escena == null:
		return

	var escena_actual = get_tree().current_scene.scene_file_path
	var escena_item: PackedScene = load("res://Escenas/linterna_mundo.tscn")
	if escena_item == null:
		return

	for registro in partida_actual.items_tirados:
		if str(registro.get("escena", "")) != escena_actual:
			continue

		var id = str(registro.get("id", ""))
		if id == "" or partida_actual.items_recogidos.has(id):
			continue

		# Evita duplicados si el método se invoca más de una vez.
		var existente = false
		for hijo in raiz_escena.get_children():
			if hijo is Area2D and hijo.get("id_unico") == id:
				existente = true
				break
		if existente:
			continue

		var objeto = escena_item.instantiate()
		objeto.data = registro.get("data") as Item
		objeto.id_unico = id
		if objeto.data == null:
			objeto.free()
			continue
		# La escena todavía puede estar configurando sus hijos desde _ready().
		# Diferimos el agregado y la posición hasta que termine esa configuración.
		_agregar_item_restaurado.call_deferred(raiz_escena, objeto, registro.get("posicion", Vector2.ZERO))

func _agregar_item_restaurado(raiz_escena: Node, objeto: Node2D, posicion: Vector2) -> void:
	if not is_instance_valid(raiz_escena) or not is_instance_valid(objeto):
		return
	raiz_escena.add_child(objeto)
	objeto.global_position = posicion
	objeto.z_index = 1

var is_dialogue_active = false
