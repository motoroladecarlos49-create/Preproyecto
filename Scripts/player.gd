extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var flash_light: PointLight2D = $flashLight

@export var speed: float = 160
@export var flashlight_distance: float = 30.0  # a qué distancia se sitúa el origen de la luz

var last_direction: String = "down"
var interactua: bool = false

func _ready() -> void:
	flash_light.enabled = false
	update_flashlight_direction()

func _physics_process(_delta: float) -> void:
	get_input()
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_linterna"):
		flash_light.enabled = not flash_light.enabled

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
	# El offset mueve el ORIGEN de la luz hacia adelante, para que el cono nazca delante del player.
	var offset := Vector2.ZERO
	var angle := 0.0

	match last_direction:
		"right":
			offset = Vector2(flashlight_distance, 10)
			angle = 0.0
		"left":
			offset = Vector2(-flashlight_distance, 14)
			angle = PI
		"up":
			offset = Vector2(-2, -flashlight_distance)
			angle = -PI / 2
		"down":
			offset = Vector2(1, flashlight_distance)
			angle = PI / 2

	flash_light.position = offset
	flash_light.rotation = angle

func update_animation(state: String) -> void:
	animated_sprite_2d.play(state + "_" + last_direction)
