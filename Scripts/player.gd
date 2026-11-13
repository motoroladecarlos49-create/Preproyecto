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

func _ready() -> void:
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

func _physics_process(_delta: float) -> void:
	get_input()
	move_and_slide()
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
		else:
			flash_light.enabled = false
			GameManager.linterna_encendida = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar"):
		if item_cerca != null:
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
				item_cerca.queue_free()
				item_cerca = null
				if not GameManager.ya_aviso_inventario:
					GameManager.ya_aviso_inventario = true
					MessageManager.mostrar_mensaje("Presiona la tecla I para abrir el inventario", 3.0)
			else:
				print("Mochila llena.")
		elif puerta_cerca != null:
			if escena_destino != "":
				if escena_destino == "res://Escenas/level_3d.tscn":
					if id_punto_retorno_2d == "":
						push_warning("Esta puerta no tiene configurado su punto de regreso 2D.")
						return
					GameManager.preparar_regreso_2d(get_tree().current_scene.scene_file_path, id_punto_retorno_2d)
					GameManager.puerta_destino_id = ""
				else:
					GameManager.puerta_destino_id = id_puerta
					GameManager.direccion_salida = direccion_salida
				var error: Error = get_tree().change_scene_to_file(escena_destino)
				if error != OK:
					push_error("No se pudo abrir la escena de destino: %s" % escena_destino)

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
	if escena_item_mundo == null or item_a_tirar == null:
		return
	var id_anterior = item_a_tirar.id_escena
	if id_anterior != "" and not GameManager.partida_actual.items_recogidos.has(id_anterior):
		GameManager.partida_actual.items_recogidos.append(id_anterior)
	var nuevo_id = item_a_tirar.nombre + "_soltado_" + str(Time.get_ticks_usec())
	item_a_tirar.id_escena = nuevo_id
	var item_suelto = escena_item_mundo.instantiate()
	item_suelto.data = item_a_tirar
	item_suelto.id_unico = nuevo_id
	get_parent().add_child(item_suelto)
	var colision_jugador: CollisionShape2D = $CollisionShape2D
	var colision_item: CollisionShape2D = item_suelto.get_node("CollisionShape2D")
	var desplazamiento_colision = colision_item.global_position - item_suelto.global_position
	var posicion_alineada = colision_jugador.global_position - desplazamiento_colision
	var posicion_anterior = global_position + Vector2(50, 50)
	item_suelto.global_position = posicion_alineada.lerp(posicion_anterior, 0.5)
	item_suelto.z_index = 1
	GameManager.registrar_item_tirado(nuevo_id, item_a_tirar, item_suelto.global_position, get_tree().current_scene.scene_file_path)
	mochila.remover_item_por_clave(clave)

func get_input() -> void:
	if GameManager.is_dialogue_active or (ui_inventario != null and ui_inventario.visible):
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
