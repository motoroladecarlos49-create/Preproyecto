extends CharacterBody2D

@export var mochila : Mochila
@export var escena_item_mundo: PackedScene

@onready var sprite_normal: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite_lampara: AnimatedSprite2D = $SpriteLampara
@onready var flash_light: PointLight2D = $flashLight

@export var speed: float = 160
@export var flashlight_distance: float = 5.0 

var last_direction: String = "down"
var item_cerca: Node = null 
var puerta_cerca: Node = null 
var tiene_linterna_equipada: bool = false

# --- BANDERAS LOCALES PARA TUTORIALES ---
var ya_aviso_inventario: bool = false
var ya_aviso_recoger: bool = false

func _ready() -> void:
	flash_light.enabled = false
	sprite_lampara.visible = false 
	update_flashlight_direction()
	if mochila != null:
		mochila.item_seleccionado_cambiado.connect(_on_mochila_item_seleccionado_cambiado)

func _physics_process(_delta: float) -> void:
	get_input()
	move_and_slide()
	
	if item_cerca != null:
		if not ya_aviso_recoger:
			MessageManager.mostrar_mensaje("Presiona 'E' para recoger el ítem", 2.0)
			ya_aviso_recoger = true
			
	elif puerta_cerca != null:
		MessageManager.mostrar_mensaje("Presiona 'E' para interactuar con la puerta", 0.2)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_linterna"):
		if tiene_linterna_equipada:
			flash_light.enabled = not flash_light.enabled
		else:
			flash_light.enabled = false
			print("No puedes usar la lámpara si no la tienes seleccionada.")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar"):
		if item_cerca != null:
			var exito = mochila.agregar_item(item_cerca.data)
			if exito:
				item_cerca.queue_free() 
				item_cerca = null
				print("¡Ítem recogido con éxito!")
				
				if not ya_aviso_inventario:
					ya_aviso_inventario = true
					MessageManager.mostrar_mensaje("Presiona 'I' para abrir tu inventario", 3.0)
			else:
				print("Mochila llena, no puedes recoger más.")
				
		elif puerta_cerca != null:
			print("Abriendo puerta...")

func _on_mochila_item_seleccionado_cambiado(item_actual: Item):
	if item_actual != null and item_actual.nombre == "Linterna": 
		tiene_linterna_equipada = true
		sprite_normal.visible = false
		sprite_lampara.visible = true
		
		# --- TUTORIAL DE LA LINTERNA (SOLO UNA VEZ EN LA PARTIDA) ---
		if not MessageManager.tutorial_lampara_completado:
			MessageManager.tutorial_lampara_completado = true # Lo marcamos como completado
			await get_tree().create_timer(0.2).timeout
			MessageManager.mostrar_mensaje("Cierra el inventario con 'I' y presiona 'F' para usar la lámpara", 4.0)
			
	else:
		tiene_linterna_equipada = false
		flash_light.enabled = false
		sprite_normal.visible = true
		sprite_lampara.visible = false
	
	update_animation("idle" if velocity == Vector2.ZERO else "run")

func tirar_item(clave: String, item_a_tirar: Item):
	if escena_item_mundo == null: return
		
	var item_suelto = escena_item_mundo.instantiate()
	item_suelto.data = item_a_tirar
	get_parent().add_child(item_suelto)
	item_suelto.global_position = global_position + Vector2(10, 100) 
	item_suelto.scale = Vector2(230, 230) 
	
	var index_player = get_index()
	get_parent().move_child(item_suelto, index_player)
	
	mochila.remover_item_por_clave(clave)

func get_input() -> void:
	if GameManager.is_dialogue_active:
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
