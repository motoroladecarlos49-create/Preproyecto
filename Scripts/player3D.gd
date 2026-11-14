extends CharacterBody3D

@export var speed: float = 2.0
@export var fuerza_salto: float = 0.0
@export var sensivilidad_mouse: float = 0.0005

@export_range(0.1, 1.0) var multiplicador_agachado: float = 0.4
@export var altura_normal: float = 1.8
@export var altura_agachado: float = 1.0
@export var offset_camara_agachado: float = 0.4
@export var velocidad_transicion: float = 8.0

@onready var camera_3d: Camera3D = $Camera3D
@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var luz_linterna: OmniLight3D = $CollisionShape3D/SpotLight3D
@onready var ui_inventario: Control = get_node_or_null("CanvasLayer/UI_inventario") as Control

var pitch: float = 0.0
var esta_agachado: bool = false
var altura_camara_original: float = 0.0
var altura_camara_objetivo: float = 0.0
var altura_collider_objetivo: float = 0.0
var salida_cerca: bool = false
var item_cerca_3d: Node3D = null
var mochila: Mochila
var tiene_linterna_equipada: bool = false

@onready var salida_3d: Area3D = get_tree().current_scene.get_node_or_null("Salida3D") as Area3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	altura_camara_original = camera_3d.position.y
	altura_camara_objetivo = altura_camara_original
	altura_collider_objetivo = altura_normal

	if GameManager.mochila_global == null:
		GameManager.mochila_global = Mochila.new()
	mochila = GameManager.mochila_global

	if ui_inventario != null:
		ui_inventario.mochila = mochila
		ui_inventario.conectar_mochila()

	if not mochila.item_seleccionado_cambiado.is_connected(_on_mochila_item_seleccionado_cambiado):
		mochila.item_seleccionado_cambiado.connect(_on_mochila_item_seleccionado_cambiado)
	_on_mochila_item_seleccionado_cambiado(mochila.item_seleccionado)

	GameManager.restaurar_items_tirados_3d(get_tree().current_scene)
	if GameManager.carga_pendiente:
		if GameManager.partida_actual.jugador_en_3d:
			global_position = GameManager.partida_actual.posicion_jugador_3d
		GameManager.carga_pendiente = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensivilidad_mouse)
		pitch = clampf(pitch - event.relative.y * sensivilidad_mouse, deg_to_rad(-89), deg_to_rad(89))
		camera_3d.rotation.x = pitch

	if event.is_action_pressed("toggle_linterna") and tiene_linterna_equipada:
		GameManager.linterna_encendida = not GameManager.linterna_encendida
		luz_linterna.visible = GameManager.linterna_encendida

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar"):
		if ui_inventario != null and ui_inventario.visible:
			return
		if item_cerca_3d != null:
			if _esta_mirando_item_3d(item_cerca_3d):
				_recoger_item_3d()
		elif salida_cerca:
			GameManager.volver_a_escena_2d()

func _physics_process(delta: float) -> void:
	if ui_inventario != null and ui_inventario.visible:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var quiere_agacharse = Input.is_action_pressed("crouch")
	if not quiere_agacharse and esta_agachado and not _puede_levantarse():
		quiere_agacharse = true
	esta_agachado = quiere_agacharse
	var vel_actual = speed * multiplicador_agachado if esta_agachado else speed

	var direccion = Vector3.ZERO
	if Input.is_action_pressed("up"):
		direccion -= transform.basis.z
	if Input.is_action_pressed("down"):
		direccion += transform.basis.z
	if Input.is_action_pressed("left"):
		direccion -= transform.basis.x
	if Input.is_action_pressed("right"):
		direccion += transform.basis.x
	direccion = direccion.normalized()

	velocity.x = direccion.x * vel_actual
	velocity.z = direccion.z * vel_actual

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	elif Input.is_action_just_pressed("jump") and not esta_agachado:
		velocity.y = fuerza_salto

	altura_camara_objetivo = altura_camara_original - (offset_camara_agachado if esta_agachado else 0.0)
	altura_collider_objetivo = altura_agachado if esta_agachado else altura_normal
	camera_3d.position.y = lerp(camera_3d.position.y, altura_camara_objetivo, delta * velocidad_transicion)

	if collider.shape is CapsuleShape3D:
		collider.shape.height = lerp(collider.shape.height, altura_collider_objetivo, delta * velocidad_transicion)
	elif collider.shape is BoxShape3D:
		collider.shape.size.y = lerp(collider.shape.size.y, altura_collider_objetivo, delta * velocidad_transicion)

	move_and_slide()

	if salida_3d != null:
		var esta_dentro := salida_3d.get_overlapping_bodies().has(self)
		if esta_dentro and not salida_cerca and not GameManager.ya_aviso_salida_3d:
			GameManager.ya_aviso_salida_3d = true
			MessageManager.mostrar_mensaje("Presiona 'E' para volver por la puerta", 3.0)
		salida_cerca = esta_dentro

	if item_cerca_3d != null and is_instance_valid(item_cerca_3d) and not GameManager.ya_aviso_llave_3d:
		var item_cercano_data := item_cerca_3d.get("data") as Item
		if item_cercano_data != null and item_cercano_data.nombre == "Llave" and _esta_mirando_item_3d(item_cerca_3d):
			GameManager.ya_aviso_llave_3d = true
			MessageManager.mostrar_mensaje("Presiona 'E' para recoger la llave", 1.8)

func establecer_item_cerca_3d(item: Node3D) -> void:
	item_cerca_3d = item

func inventario_cambiado(abierto: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if abierto else Input.MOUSE_MODE_CAPTURED


func _esta_mirando_item_3d(item: Node3D) -> bool:
	if not is_instance_valid(item):
		return false
	var origen := camera_3d.global_position
	var direccion := -camera_3d.global_transform.basis.z.normalized()
	var consulta := PhysicsRayQueryParameters3D.create(origen, origen + direccion * 2.5)
	consulta.exclude = [self]
	consulta.collide_with_bodies = true
	consulta.collide_with_areas = false
	var impacto := get_world_3d().direct_space_state.intersect_ray(consulta)
	if impacto.is_empty():
		return false
	var objetivo := impacto.get("collider") as Node
	return objetivo == item or item.is_ancestor_of(objetivo)

func _recoger_item_3d() -> void:
	if not is_instance_valid(item_cerca_3d):
		item_cerca_3d = null
		return
	var objeto = item_cerca_3d
	var item_data = objeto.get("data") as Item
	if item_data == null or not mochila.agregar_item(item_data):
		MessageManager.mostrar_mensaje("No hay espacio en el inventario.", 2.0)
		return

	var id_recogido = str(objeto.get("id_unico"))
	if id_recogido != "" and not GameManager.partida_actual.items_recogidos.has(id_recogido):
		GameManager.partida_actual.items_recogidos.append(id_recogido)
	GameManager.quitar_item_tirado_3d(id_recogido)
	if item_data.nombre == "Linterna":
		GameManager.linterna_encendida = bool(objeto.get("esta_encendida"))
	objeto.queue_free()
	item_cerca_3d = null
	GameManager.ya_aviso_recoger = false

func tirar_item(clave: String, item_a_tirar: Item) -> void:
	if item_a_tirar == null:
		return

	var ruta_escena := ""
	match item_a_tirar.nombre:
		"Linterna":
			ruta_escena = "res://Escenas/linterna_3d.tscn"
		"Llave":
			ruta_escena = "res://Escenas/llave_3d.tscn"
		_:
			MessageManager.mostrar_mensaje("Este objeto todavía no tiene una representación 3D para soltarlo.", 2.0)
			return

	var escena_item := load(ruta_escena) as PackedScene
	if escena_item == null:
		push_error("No se pudo cargar la escena 3D del objeto: " + ruta_escena)
		return

	var id_anterior := item_a_tirar.id_escena
	if id_anterior != "" and not GameManager.partida_actual.items_recogidos.has(id_anterior):
		GameManager.partida_actual.items_recogidos.append(id_anterior)

	var nuevo_id := item_a_tirar.nombre + "_3d_soltado_" + str(Time.get_ticks_usec())
	item_a_tirar.id_escena = nuevo_id
	var item_suelto := escena_item.instantiate() as RigidBody3D
	if item_suelto == null:
		push_error("La escena del objeto no tiene una raíz RigidBody3D: " + ruta_escena)
		return

	item_suelto.set("data", item_a_tirar)
	item_suelto.set("id_unico", nuevo_id)
	var estado_encendida := item_a_tirar.nombre == "Linterna" and GameManager.linterna_encendida
	if item_suelto.has_method("configurar_estado"):
		item_suelto.configurar_estado(estado_encendida)

	get_tree().current_scene.add_child(item_suelto)
	var direccion := -global_transform.basis.z.normalized()
	item_suelto.global_position = global_position + direccion * 0.85 + Vector3.UP * 0.22
	if item_a_tirar.nombre == "Linterna":
		item_suelto.global_rotation = Vector3(0, rotation.y + PI / 2.0, 0)
	item_suelto.linear_velocity = direccion * 0.55 + Vector3.UP * 0.35

	GameManager.registrar_item_tirado_3d(
		nuevo_id,
		item_a_tirar,
		item_suelto.global_position,
		get_tree().current_scene.scene_file_path,
		estado_encendida,
		ruta_escena
	)
	mochila.remover_item_por_clave(clave)

func _on_mochila_item_seleccionado_cambiado(item_actual: Item) -> void:
	tiene_linterna_equipada = item_actual != null and item_actual.nombre == "Linterna"
	luz_linterna.visible = tiene_linterna_equipada and GameManager.linterna_encendida

func _puede_levantarse() -> bool:
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + Vector3.UP * altura_normal
	)
	query.exclude = [self]
	return space.intersect_ray(query).is_empty()
