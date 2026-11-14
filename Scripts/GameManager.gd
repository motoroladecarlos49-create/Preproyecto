extends Node

var partida_actual: SaveGame = SaveGame.new()

var puerta_destino_id: String = ""
var direccion_salida: String = "down"
var escena_retorno_2d: String = ""
var punto_retorno_2d_id: String = ""
var mochila_global: Mochila = null
var linterna_encendida: bool = false
var carga_pendiente: bool = false

# Banderas de tutoriales
var ya_aviso_inventario: bool = false
var ya_aviso_recoger: bool = false
var ya_aviso_llave_3d: bool = false
var ya_aviso_puerta: bool = false
var tutorial_lampara_completado: bool = false
var ya_aviso_salida_3d: bool = false
var tutorial_movimiento_completado: bool = false

var item_recien_tirado: bool = false

# Escalas visuales para las escenas
var escala_item_escena1: float = 230.0
var escala_item_escena2: float = 4.75

const RUTA_GUARDADO: String = "user://partida_guardada.tres"
const RUTA_CONFIGURACION: String = "user://configuracion.cfg"

var volumen_general: float = 1.0

func _ready() -> void:
	var indice_bus: int = AudioServer.get_bus_index("Master")
	if indice_bus >= 0:
		volumen_general = 0.0 if AudioServer.is_bus_mute(indice_bus) else db_to_linear(AudioServer.get_bus_volume_db(indice_bus))

	var configuracion := ConfigFile.new()
	if configuracion.load(RUTA_CONFIGURACION) == OK:
		volumen_general = clampf(float(configuracion.get_value("audio", "volumen_general", volumen_general)), 0.0, 1.0)

	_aplicar_volumen_guardado()
	_guardar_configuracion()

func obtener_volumen_general() -> float:
	return volumen_general

func establecer_volumen_general(valor: float) -> void:
	volumen_general = clampf(valor, 0.0, 1.0)
	_aplicar_volumen_guardado()
	_guardar_configuracion()

func _aplicar_volumen_guardado() -> void:
	var indice_bus: int = AudioServer.get_bus_index("Master")
	if indice_bus < 0:
		return
	AudioServer.set_bus_volume_db(indice_bus, linear_to_db(maxf(volumen_general, 0.001)))
	AudioServer.set_bus_mute(indice_bus, volumen_general <= 0.0)

func _guardar_configuracion() -> void:
	var configuracion := ConfigFile.new()
	configuracion.set_value("audio", "volumen_general", volumen_general)
	var error: Error = configuracion.save(RUTA_CONFIGURACION)
	if error != OK:
		push_error("No se pudo guardar la configuración. Código: %s" % error)

func hay_partida_guardada() -> bool:
	if not FileAccess.file_exists(RUTA_GUARDADO):
		return false
	var guardado = ResourceLoader.load(RUTA_GUARDADO) as SaveGame
	return guardado != null and guardado.escena_actual != "" and ResourceLoader.exists(guardado.escena_actual)

func eliminar_partida_guardada() -> bool:
	if not FileAccess.file_exists(RUTA_GUARDADO):
		return true
	var ruta_absoluta = ProjectSettings.globalize_path(RUTA_GUARDADO)
	var error = DirAccess.remove_absolute(ruta_absoluta)
	if error != OK:
		push_error("No se pudo eliminar el guardado anterior. Código: %s" % error)
		return false
	return true

func iniciar_partida_nueva() -> void:
	partida_actual = SaveGame.new()
	mochila_global = Mochila.new()
	linterna_encendida = false
	carga_pendiente = false
	puerta_destino_id = ""
	direccion_salida = "down"
	escena_retorno_2d = ""
	punto_retorno_2d_id = ""
	ya_aviso_inventario = false
	ya_aviso_recoger = false
	ya_aviso_llave_3d = false
	ya_aviso_puerta = false
	tutorial_lampara_completado = false
	ya_aviso_salida_3d = false
	tutorial_movimiento_completado = false
	item_recien_tirado = false
	is_dialogue_active = false

func preparar_regreso_2d(escena: String, punto_retorno_id: String) -> void:
	escena_retorno_2d = escena
	punto_retorno_2d_id = punto_retorno_id

func volver_a_escena_2d() -> bool:
	if escena_retorno_2d == "" or punto_retorno_2d_id == "":
		push_warning("No hay una escena o un punto de regreso 2D configurado.")
		return false
	if not ResourceLoader.exists(escena_retorno_2d):
		push_error("No existe la escena 2D de regreso: %s" % escena_retorno_2d)
		return false

	puerta_destino_id = punto_retorno_2d_id
	direccion_salida = "down"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var error: Error = get_tree().change_scene_to_file(escena_retorno_2d)
	if error != OK:
		puerta_destino_id = ""
		push_error("No se pudo volver a la escena 2D. Código: %s" % error)
		return false

	escena_retorno_2d = ""
	punto_retorno_2d_id = ""
	return true

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
	partida_actual.ya_aviso_inventario = ya_aviso_inventario
	partida_actual.ya_aviso_recoger = ya_aviso_recoger
	partida_actual.ya_aviso_puerta = ya_aviso_puerta
	partida_actual.tutorial_lampara_completado = tutorial_lampara_completado
	partida_actual.ya_aviso_salida_3d = ya_aviso_salida_3d
	partida_actual.tutorial_movimiento_completado = tutorial_movimiento_completado
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
	ya_aviso_inventario = partida_actual.ya_aviso_inventario
	ya_aviso_recoger = partida_actual.ya_aviso_recoger
	ya_aviso_puerta = partida_actual.ya_aviso_puerta
	tutorial_lampara_completado = partida_actual.tutorial_lampara_completado
	ya_aviso_salida_3d = partida_actual.ya_aviso_salida_3d
	tutorial_movimiento_completado = partida_actual.tutorial_movimiento_completado
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

func _obtener_escena_item_3d(item_data: Item) -> String:
	if item_data == null:
		return ""
	match item_data.nombre:
		"Linterna":
			return "res://Escenas/linterna_3d.tscn"
		"Llave":
			return "res://Escenas/llave_3d.tscn"
	return ""

func registrar_item_tirado_3d(id: String, item_data: Item, posicion: Vector3, escena: String, encendida: bool, escena_item: String = "") -> void:
	quitar_item_tirado_3d(id)
	if escena_item == "":
		escena_item = _obtener_escena_item_3d(item_data)
	partida_actual.items_tirados_3d.append({
		"id": id,
		"data": item_data,
		"posicion": posicion,
		"escena": escena,
		"encendida": encendida,
		"escena_item": escena_item
	})

func quitar_item_tirado_3d(id: String) -> void:
	if id == "":
		return
	for i in range(partida_actual.items_tirados_3d.size() - 1, -1, -1):
		if str(partida_actual.items_tirados_3d[i].get("id", "")) == id:
			partida_actual.items_tirados_3d.remove_at(i)

func restaurar_items_tirados_3d(raiz_escena: Node) -> void:
	if raiz_escena == null:
		return
	var escena_actual = get_tree().current_scene.scene_file_path
	for registro in partida_actual.items_tirados_3d:
		if str(registro.get("escena", "")) != escena_actual:
			continue
		var id = str(registro.get("id", ""))
		if id == "" or partida_actual.items_recogidos.has(id):
			continue
		var item_data := registro.get("data") as Item
		var ruta_escena := str(registro.get("escena_item", ""))
		if ruta_escena == "":
			ruta_escena = _obtener_escena_item_3d(item_data)
		if ruta_escena == "" or not ResourceLoader.exists(ruta_escena):
			push_warning("No se pudo restaurar el objeto 3D '%s': no tiene una escena válida." % id)
			continue
		var existente := false
		for hijo in raiz_escena.get_children():
			if hijo.is_in_group("items_tirados_3d") and hijo.get("id_unico") == id:
				existente = true
				break
		if existente:
			continue
		var escena_item := load(ruta_escena) as PackedScene
		if escena_item == null:
			continue
		var objeto := escena_item.instantiate() as Node3D
		objeto.set("data", item_data)
		objeto.set("id_unico", id)
		if objeto.has_method("configurar_estado"):
			objeto.configurar_estado(bool(registro.get("encendida", false)))
		if objeto.get("data") == null:
			objeto.free()
			continue
		_agregar_item_3d_restaurado.call_deferred(raiz_escena, objeto, registro.get("posicion", Vector3.ZERO))

func _agregar_item_3d_restaurado(raiz_escena: Node, objeto: Node3D, posicion: Vector3) -> void:
	if not is_instance_valid(raiz_escena) or not is_instance_valid(objeto):
		return
	raiz_escena.add_child(objeto)
	objeto.global_position = posicion

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
	for registro in partida_actual.items_tirados:
		if str(registro.get("escena", "")) != escena_actual:
			continue
		var id = str(registro.get("id", ""))
		if id == "" or partida_actual.items_recogidos.has(id):
			continue
		var item_data := registro.get("data") as Item
		if item_data == null:
			continue
		var ruta_escena := "res://Escenas/linterna_mundo.tscn"
		if item_data.nombre == "Llave":
			ruta_escena = "res://Escenas/llave_mundo.tscn"
		elif item_data.nombre != "Linterna":
			continue
		var existente := false
		for hijo in raiz_escena.get_children():
			if hijo is Area2D and str(hijo.get("id_unico")) == id:
				existente = true
				break
		if existente:
			continue
		var escena_item := load(ruta_escena) as PackedScene
		if escena_item == null:
			push_warning("No se pudo restaurar el objeto 2D '%s'." % id)
			continue
		var objeto := escena_item.instantiate() as Area2D
		objeto.set("data", item_data)
		objeto.set("id_unico", id)
		_agregar_item_restaurado.call_deferred(raiz_escena, objeto, registro.get("posicion", Vector2.ZERO))

func _agregar_item_restaurado(raiz_escena: Node, objeto: Node2D, posicion: Vector2) -> void:
	if not is_instance_valid(raiz_escena) or not is_instance_valid(objeto):
		return
	raiz_escena.add_child(objeto)
	objeto.global_position = posicion
	objeto.z_index = 1

var is_dialogue_active = false
