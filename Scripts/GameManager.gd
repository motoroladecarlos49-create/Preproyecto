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
var ya_aviso_puerta: bool = false
var tutorial_lampara_completado: bool = false

var item_recien_tirado: bool = false

# Escalas visuales para las escenas
var escala_item_escena1: float = 230.0
var escala_item_escena2: float = 4.75

const RUTA_GUARDADO: String = "user://partida_guardada.tres"

const RUTA_CONFIGURACION: String = "user://configuracion.cfg"

var volumen_general: float = 1.0
var resolucion_ventana: Vector2i = Vector2i(1280, 720)
var pantalla_completa: bool = false

const RESOLUCIONES_DISPONIBLES = [Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(720, 480)]

func obtener_resoluciones_disponibles() -> Array[Vector2i]:
	var resoluciones: Array[Vector2i] = []
	resoluciones.assign(RESOLUCIONES_DISPONIBLES)
	return resoluciones

func _ready() -> void:
	var ventana: Window = get_tree().root
	resolucion_ventana = ventana.size

	var indice_bus: int = AudioServer.get_bus_index("Master")
	if indice_bus >= 0:
		volumen_general = 0.0 if AudioServer.is_bus_mute(indice_bus) else db_to_linear(AudioServer.get_bus_volume_db(indice_bus))

	var configuracion := ConfigFile.new()
	if configuracion.load(RUTA_CONFIGURACION) == OK:
		volumen_general = clampf(float(configuracion.get_value("audio", "volumen_general", volumen_general)), 0.0, 1.0)
		var resolucion_guardada: Variant = configuracion.get_value("video", "resolucion_ventana", resolucion_ventana)
		if resolucion_guardada is Vector2i and RESOLUCIONES_DISPONIBLES.has(resolucion_guardada):
			resolucion_ventana = resolucion_guardada
		pantalla_completa = bool(configuracion.get_value("video", "pantalla_completa", false))

	_aplicar_volumen_guardado()
	_aplicar_configuracion_ventana()
	_guardar_configuracion()

func obtener_volumen_general() -> float:
	return volumen_general

func obtener_resolucion_ventana() -> Vector2i:
	return resolucion_ventana

func obtener_pantalla_completa() -> bool:
	return pantalla_completa

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

func establecer_pantalla_completa(activada: bool) -> void:
	pantalla_completa = activada
	_aplicar_configuracion_ventana()
	_guardar_configuracion()

func establecer_resolucion_ventana(resolucion: Vector2i) -> void:
	if not RESOLUCIONES_DISPONIBLES.has(resolucion):
		push_warning("La resolución solicitada no está en la lista de opciones disponibles.")
		return
	resolucion_ventana = resolucion
	pantalla_completa = false
	_aplicar_configuracion_ventana()
	_guardar_configuracion()

func _aplicar_configuracion_ventana() -> void:
	var ventana: Window = get_tree().root
	# Primero se vuelve al modo ventana para que el tamaño elegido se aplique
	# al área de ventana real y no quede solamente almacenado en la configuración.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(resolucion_ventana)
	ventana.move_to_center()
	if pantalla_completa:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _guardar_configuracion() -> void:
	var configuracion := ConfigFile.new()
	configuracion.set_value("audio", "volumen_general", volumen_general)
	configuracion.set_value("video", "resolucion_ventana", resolucion_ventana)
	configuracion.set_value("video", "pantalla_completa", pantalla_completa)
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
	ya_aviso_puerta = false
	tutorial_lampara_completado = false
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
