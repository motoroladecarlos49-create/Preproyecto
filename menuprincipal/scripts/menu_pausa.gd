extends CanvasLayer

@onready var plane = $opciones/plane
@onready var fondo = $ColorRect
@onready var pantalla_completa = $plane/MarginContainer/VBoxContainer/contenedorpantalla/pantallacompleta

func _ready() -> void:
	visible= false
	get_tree().paused = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if get_tree().paused:
			visible = false
			get_tree().paused = false
		else:
			visible = true
			get_tree().paused = true

func _on_reanudar_pressed() -> void:
	visible = false 
	get_tree().paused = false 

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://menu_principal.tscn")


func _on_opciones_pressed() -> void:
	fondo.visible = false
	plane.visible = true


func _on_botonvolver_pressed() -> void:
	plane.visible = false
	fondo.visible = true


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
