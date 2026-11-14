extends CharacterBody2D

var mochila : Mochila
var escena_item_mundo: PackedScene
var ui_inventario: Control = null

@onready var sprite_normal: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite_lampara: AnimatedSprite2D = $SpriteLampara
@onready var flash_light: PointLight2D = $flashLight
@onready var camera: Camera2D = $Camera2D

@export var speed: float = 160
@export var flashlight_distance: float = 5.0

var last_direction: String = "down"
var item_cerca: Node = null
var puerta_cerca: Node = null
var escena_destino: String = ""
var id_puerta: String = ""
var id_punto_retorno_2d: String = ""
var direccion_salida: String = "down"
var tiene_linterna_equipada: bool = false
var _finalizando_juego: bool = false
var reproductor_sonido: AudioStreamPlayer
var ultima_posicion_pasos: Vector2 = Vector2.ZERO
var distancia_pasos: float = 0.0

func _ready() -> void:
	reproductor_sonido = AudioStreamPlayer.new()
	reproductor_sonido.name = "SonidosJugador"
	add_child(reproductor_sonido)
	ultima_posicion_pasos = global_position
	flash_light.enabled = false
	sprite_lampara.visible = false
	update_flashlight_direction()
	z_index = 2
	escena_item_mundo = load("res://Escenas/linterna_mundo.tscn")

	if GameManager.mochila_global == null:
		mochila = Mochila.new()
		GameManager.mochila_global = mochila
	else:
		mochila = GameManager.mochila_global

	ui_inventario = find_child("UI_inventario", true, false) as Control
	if ui_inventario != null:
		ui_inventario.mochila = mochila
		ui_inventario.conectar_mochila()

	if not mochila.item_seleccionado_cambiado.is_connected(_on_mochila_item_seleccionado_cambiado):
		mochila.item_seleccionado_cambiado.connect(_on_mochila_item_seleccionado_cambiado)

	GameManager.restaurar_items_tirados(get_parent())

	if GameManager.puerta_destino_id != "":
		var spawn_point = get_parent().find_child(GameManager.puerta_destino_id, true, false)
		if spawn_point != null:
			global_position = spawn_point.global_position
			last_direction = GameManager.direccion_salida
			update_animation("idle")
		GameManager.puerta_destino_id = ""

	# La carga manual tiene prioridad sobre el punto de aparición de una puerta.
	if GameManager.carga_pendiente:
		global_position = GameManager.partida_actual.posicion_jugador
		var clave_guardada = GameManager.partida_actual.clave_item_seleccionado
		if clave_guardada != "" and mochila.objetos.has(clave_guardada):
			mochila.seleccionar_item(clave_guardada)
		else:
			mochila.seleccionar_item("")
		GameManager.carga_pendiente = false
	else:
		_on_mochila_item_seleccionado_cambiado(mochila.item_seleccionado)

func _process(_delta):
	if camera:
		camera.global_position.x = global_position.x
		camera.global_position.y = 0

func _physics_process(delta: float) -> void:
	get_input()
	move_and_slide()
	var desplazamiento := global_position - ultima_posicion_pasos
	ultima_posicion_pasos = global_position
	if velocity.length() > 1.0 and desplazamiento.length() > 0.01 and not _finalizando_juego and not GameManager.is_dialogue_active and (ui_inventario == null or not ui_inventario.visible):
		distancia_pasos += desplazamiento.length()
		var distancia_por_paso := 48.0
		if distancia_pasos >= distancia_por_paso:
			distancia_pasos = fmod(distancia_pasos, distancia_por_paso)
			_reproducir_pisada()
	else:
		distancia_pasos = 0.0
	if item_cerca != null:
		if not GameManager.ya_aviso_recoger:
			MessageManager.mostrar_mensaje("Presiona 'E' para recoger el ítem", 2.0)
			GameManager.ya_aviso_recoger = true
	elif puerta_cerca != null:
		if not GameManager.ya_aviso_puerta:
			MessageManager.mostrar_mensaje("Presiona 'E' para entrar a la puerta", 2.0)
			GameManager.ya_aviso_puerta = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_linterna"):
		if tiene_linterna_equipada:
			flash_light.enabled = not flash_light.enabled
			GameManager.linterna_encendida = flash_light.enabled
			_reproducir_tono(880.0 if flash_light.enabled else 520.0, 0.09, 0.12)
		else:
			flash_light.enabled = false
			GameManager.linterna_encendida = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar"):
		if item_cerca != null and is_instance_valid(item_cerca):
			if item_cerca.data == null:
				return
			var exito = mochila.agregar_item(item_cerca.data)
			if exito:
				var id_recogido = item_cerca.id_unico
				if id_recogido == "":
					id_recogido = item_cerca.data.id_escena
				if id_recogido != "" and not GameManager.partida_actual.items_recogidos.has(id_recogido):
					GameManager.partida_actual.items_recogidos.append(id_recogido)
				GameManager.quitar_item_tirado(id_recogido)
				_reproducir_tono(740.0, 0.16, 0.16)
				item_cerca.queue_free()
				item_cerca = null
				if not GameManager.ya_aviso_inventario:
					GameManager.ya_aviso_inventario = true
					MessageManager.mostrar_mensaje("Presiona la tecla I para abrir el inventario", 3.0)
			else:
				print("Mochila llena.")
		elif puerta_cerca != null:
			var mensaje_bloqueo := str(puerta_cerca.get("mensaje_bloqueo"))
			var requiere_llave := bool(puerta_cerca.get("requiere_llave")) or mensaje_bloqueo.to_lower().contains("llave")
			var nombre_requerido := str(puerta_cerca.get("nombre_item_requerido"))
			var llave_seleccionada := mochila.item_seleccionado != null and mochila.item_seleccionado.nombre == (nombre_requerido if nombre_requerido != "" else "Llave")
			if requiere_llave and not llave_seleccionada:
				if mensaje_bloqueo == "":
					mensaje_bloqueo = "Necesitas seleccionar la llave en el inventario."
				MessageManager.mostrar_mensaje(mensaje_bloqueo, 1.5)
				return
			if bool(puerta_cerca.get("finalizar_juego")):
				await _iniciar_secuencia_final()
				return
			if escena_destino == "":
				if mensaje_bloqueo != "":
					MessageManager.mostrar_mensaje(mensaje_bloqueo, 1.5)
			elif escena_destino == "res://Escenas/level_3d.tscn":
				if id_punto_retorno_2d == "":
					push_warning("Esta puerta no tiene configurado su punto de regreso 2D.")
					return
				GameManager.preparar_regreso_2d(get_tree().current_scene.scene_file_path, id_punto_retorno_2d)
				GameManager.puerta_destino_id = ""
				var error_3d: Error = get_tree().change_scene_to_file(escena_destino)
				if error_3d != OK:
					push_error("No se pudo abrir la escena de destino: %s" % escena_destino)
			else:
				GameManager.puerta_destino_id = id_puerta
				GameManager.direccion_salida = direccion_salida
				var error: Error = get_tree().change_scene_to_file(escena_destino) if escena_destino != "" else OK
				if error != OK:
					push_error("No se pudo abrir la escena de destino: %s" % escena_destino)


func _mochila_tiene_item(nombre_item: String) -> bool:
	for item in mochila.objetos.values():
		if item is Item and item.nombre == nombre_item:
			return true
	return false

func _on_mochila_item_seleccionado_cambiado(item_actual: Item):
	if item_actual != null and item_actual.nombre == "Linterna":
		tiene_linterna_equipada = true
		sprite_normal.visible = false
		sprite_lampara.visible = true
		flash_light.enabled = GameManager.linterna_encendida
		if not GameManager.tutorial_lampara_completado:
			GameManager.tutorial_lampara_completado = true
			await get_tree().create_timer(0.2).timeout
			MessageManager.mostrar_mensaje("Presiona la tecla I para cerrar el inventario y luego F para encender la linterna", 4.0)
	else:
		tiene_linterna_equipada = false
		flash_light.enabled = false
		GameManager.linterna_encendida = false
		sprite_normal.visible = true
		sprite_lampara.visible = false
	update_animation("idle" if velocity == Vector2.ZERO else "run")

func tirar_item(clave: String, item_a_tirar: Item) -> void:
	if item_a_tirar == null:
		return
	var ruta_escena := "res://Escenas/linterna_mundo.tscn"
	if item_a_tirar.nombre == "Llave":
		ruta_escena = "res://Escenas/llave_mundo.tscn"
	elif item_a_tirar.nombre != "Linterna":
		MessageManager.mostrar_mensaje("Este objeto todavía no tiene una representación en el mundo.", 2.0)
		return
	var escena := load(ruta_escena) as PackedScene
	if escena == null:
		push_error("No se pudo cargar la escena del objeto: " + ruta_escena)
		return

	var id_anterior = item_a_tirar.id_escena
	if id_anterior != "" and not GameManager.partida_actual.items_recogidos.has(id_anterior):
		GameManager.partida_actual.items_recogidos.append(id_anterior)
	var nuevo_id = item_a_tirar.nombre + "_soltado_" + str(Time.get_ticks_usec())
	item_a_tirar.id_escena = nuevo_id
	var item_suelto = escena.instantiate()
	item_suelto.data = item_a_tirar
	item_suelto.id_unico = nuevo_id
	get_parent().add_child(item_suelto)
	var colision_jugador: CollisionShape2D = $CollisionShape2D
	var colision_item: CollisionShape2D = item_suelto.get_node("CollisionShape2D")
	var desplazamiento_colision = colision_item.global_position - item_suelto.global_position
	var posicion_alineada = colision_jugador.global_position - desplazamiento_colision
	item_suelto.global_position = posicion_alineada + Vector2(0, 8)

	# Para la linterna, alinea el borde inferior de su area de recogida
	# con el borde inferior de la colision del jugador.
	if item_a_tirar.nombre == "Linterna":
		var forma_jugador: Shape2D = colision_jugador.shape
		var forma_item: Shape2D = colision_item.shape
		var mitad_alto_jugador := forma_jugador.get_rect().size.y * absf(colision_jugador.global_scale.y) * 0.5
		var mitad_alto_item := forma_item.get_rect().size.y * absf(colision_item.global_scale.y) * 0.5
		var borde_inferior_jugador := colision_jugador.global_position.y + mitad_alto_jugador
		var borde_inferior_item := colision_item.global_position.y + mitad_alto_item
		item_suelto.global_position.y += borde_inferior_jugador - borde_inferior_item
	item_suelto.z_index = 1
	GameManager.registrar_item_tirado(nuevo_id, item_a_tirar, item_suelto.global_position, get_tree().current_scene.scene_file_path)
	mochila.remover_item_por_clave(clave)

func _iniciar_secuencia_final() -> void:
	if _finalizando_juego:
		return
	_finalizando_juego = true
	velocity = Vector2.ZERO
	var capa := CanvasLayer.new()
	capa.layer = 100
	get_tree().current_scene.add_child(capa)
	var pantalla := ColorRect.new()
	pantalla.color = Color(0, 0, 0, 0)
	pantalla.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pantalla.mouse_filter = Control.MOUSE_FILTER_STOP
	capa.add_child(pantalla)
	var fundido := create_tween()
	fundido.tween_property(pantalla, "color:a", 1.0, 1.0)
	await fundido.finished
	GameManager.menu_desde_creditos = true
	var error := get_tree().change_scene_to_file("res://Escenas/creditos.tscn")
	if error != OK:
		GameManager.menu_desde_creditos = false
		_finalizando_juego = false
		push_error("No se pudo abrir la pantalla de créditos. Código: %s" % error)

func get_input() -> void:
	if _finalizando_juego or GameManager.is_dialogue_active or (ui_inventario != null and ui_inventario.visible):
		velocity = Vector2.ZERO
		update_animation("idle")
		return
	var input_direction := Input.get_vector("left", "right", "up", "down")
	if input_direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		update_animation("idle")
		return
	if abs(input_direction.x) > abs(input_direction.y):
		last_direction = "right" if input_direction.x > 0 else "left"
	else:
		last_direction = "down" if input_direction.y > 0 else "up"
	update_animation("run")
	update_flashlight_direction()
	velocity = input_direction * speed

func _reproducir_pisada() -> void:
	if reproductor_sonido == null:
		return
	var frecuencia_muestreo := 22050
	var duracion := 0.095
	var cantidad := int(frecuencia_muestreo * duracion)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = frecuencia_muestreo
	var datos := PackedByteArray()
	datos.resize(cantidad * 2)
	for i in range(cantidad):
		var t := float(i) / frecuencia_muestreo
		var envolvente := exp(-t * 34.0)
		var golpe := sin(TAU * 92.0 * t) * 0.55 + (randf() * 2.0 - 1.0) * 0.45
		var muestra := int(golpe * envolvente * 0.20 * 32767.0)
		datos.encode_s16(i * 2, muestra)
	audio.data = datos
	reproductor_sonido.stream = audio
	reproductor_sonido.play()

func _reproducir_tono(frecuencia: float, duracion: float, volumen: float) -> void:
	if reproductor_sonido == null:
		return
	var frecuencia_muestreo := 22050
	var cantidad := int(frecuencia_muestreo * duracion)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = frecuencia_muestreo
	var datos := PackedByteArray()
	datos.resize(cantidad * 2)
	for i in range(cantidad):
		var t := float(i) / frecuencia_muestreo
		var envolvente := pow(1.0 - float(i) / cantidad, 2.0)
		var muestra := int(sin(TAU * frecuencia * t) * envolvente * volumen * 32767.0)
		datos.encode_s16(i * 2, muestra)
	audio.data = datos
	reproductor_sonido.stream = audio
	reproductor_sonido.play()

func update_flashlight_direction() -> void:
	var offset := Vector2.ZERO
	var angle := 0.0
	match last_direction:
		"right": offset = Vector2(flashlight_distance, 0); angle = 0.0
		"left": offset = Vector2(-flashlight_distance, 0); angle = PI
		"up": offset = Vector2(0, -flashlight_distance); angle = -PI / 2
		"down": offset = Vector2(0, flashlight_distance); angle = PI / 2
	flash_light.position = offset
	flash_light.rotation = angle

func update_animation(state: String) -> void:
	var animacion = state + "_" + last_direction
	if tiene_linterna_equipada:
		var anim_lampara = animacion + "_linterna"
		if sprite_lampara.sprite_frames.has_animation(anim_lampara):
			sprite_lampara.play(anim_lampara)
	else:
		if sprite_normal.sprite_frames.has_animation(animacion):
			sprite_normal.play(animacion)
