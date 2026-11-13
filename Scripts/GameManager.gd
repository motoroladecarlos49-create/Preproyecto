extends Node

var partida_actual: SaveGame = SaveGame.new()

var puerta_destino_id: String = ""
var direccion_salida: String = "down"
var mochila_global: Mochila = null
var linterna_encendida: bool = false
var carga_pendiente: bool = false

# Banderas de tutoriales
var ya_aviso_inventario: bool = false
var ya_aviso_recoger: bool = false
var ya_aviso_puerta: bool = false
var tutorial_lampara_completado: bool = false

var item_recien_tirado: bool = false

# Escalas visuales para las escenas
var escala_item_escena1: float = 230.0
var escala_item_escena2: float = 4.75

const RUTA_GUARDADO: String = "user://partida_guardada.tres"

func obtener_escala_item(escala_padre: float) -> float:
	if is_equal_approx(escala_padre, 0.01):
		return escala_item_escena1
	elif is_equal_approx(escala_padre, 0.26):
		return escala_item_escena2
	return 1.0

func guardar_partida(jugador: Node2D = null) -> bool:
	if mochila_global == null:
		push_warning("No se pudo guardar: la mochila global no está inicializada.")
		return false

	if jugador == null and get_tree().current_scene != null:
		jugador = get_tree().current_scene.find_child("player", true, false) as Node2D

	partida_actual.mochila = mochila_global
	partida_actual.linterna_encendida = linterna_encendida
	partida_actual.escena_actual = get_tree().current_scene.scene_file_path if get_tree().current_scene != null else ""

	if jugador != null:
		partida_actual.posicion_jugador = jugador.global_position

	partida_actual.clave_item_seleccionado = ""
	for clave in mochila_global.objetos:
		if mochila_global.objetos[clave] == mochila_global.item_seleccionado:
			partida_actual.clave_item_seleccionado = str(clave)
			break

	var error = ResourceSaver.save(partida_actual, RUTA_GUARDADO)
	if error != OK:
		push_error("Error al guardar la partida. Código: %s" % error)
		return false
	return true

func cargar_partida() -> bool:
	if not ResourceLoader.exists(RUTA_GUARDADO):
		push_warning("No existe una partida guardada.")
		return false

	var guardado = ResourceLoader.load(RUTA_GUARDADO) as SaveGame
	if guardado == null:
		push_error("No se pudo leer el archivo de guardado.")
		return false

	partida_actual = guardado
	mochila_global = partida_actual.mochila
	linterna_encendida = partida_actual.linterna_encendida
	carga_pendiente = true

	if partida_actual.escena_actual == "":
		carga_pendiente = false
		return false

	var error = get_tree().change_scene_to_file(partida_actual.escena_actual)
	if error != OK:
		carga_pendiente = false
		push_error("No se pudo abrir la escena guardada. Código: %s" % error)
		return false
	return true

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
		_agregar_item_restaurado.call_deferred(raiz_escena, objeto, registro.get("posicion", Vector2.ZERO))

func _agregar_item_restaurado(raiz_escena: Node, objeto: Node2D, posicion: Vector2) -> void:
	if not is_instance_valid(raiz_escena) or not is_instance_valid(objeto):
		return
	raiz_escena.add_child(objeto)
	objeto.global_position = posicion
	objeto.z_index = 1

var is_dialogue_active = false
