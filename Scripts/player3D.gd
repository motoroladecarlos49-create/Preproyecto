extends CharacterBody3D

# --- MOVIMIENTO ---
@export var speed: float = 2.0 
@export var fuerza_salto: float = 0
@export var sensivilidad_mouse: float = 0.0005

# --- AGACHARSE ---
@export_range(0.1, 1.0) var multiplicador_agachado: float = 0.4
@export var altura_normal: float = 1.8
@export var altura_agachado: float = 1.0
@export var offset_camara_agachado: float = 0.4   # 👈 mitad aprox. del cambio total
@export var velocidad_transicion: float = 8.0

@onready var camera_3d: Camera3D = $Camera3D
@onready var collider: CollisionShape3D = $CollisionShape3D

var pitch: float = 0.0
var esta_agachado: bool = false

var altura_camara_original: float = 0.0
var altura_camara_objetivo: float = 0.0
var altura_collider_objetivo: float = 0.0
var salida_cerca: bool = false
@onready var salida_3d: Area3D = get_tree().current_scene.get_node_or_null("Salida3D") as Area3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	altura_camara_original = camera_3d.position.y
	altura_camara_objetivo = altura_camara_original
	altura_collider_objetivo = altura_normal


func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensivilidad_mouse)
		
		pitch = clamp(pitch - event.relative.y * sensivilidad_mouse, deg_to_rad(-89), deg_to_rad(89))
		camera_3d.rotation.x = pitch
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar") and salida_cerca:
		GameManager.volver_a_escena_2d()


func _physics_process(delta: float) -> void:
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
	else:
		if Input.is_action_just_pressed("jump") and not esta_agachado:
			velocity.y = fuerza_salto
	
	# --- TRANSICIÓN SUAVE DE ALTURAS ---
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


func _puede_levantarse() -> bool:
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + Vector3.UP * altura_normal
	)
	query.exclude = [self]
	var result = space.intersect_ray(query)
	return result.is_empty()
