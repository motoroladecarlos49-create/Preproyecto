extends CanvasLayer

@onready var panel_opciones: Control = $opciones/plane
@onready var fondo: ColorRect = $ColorRect

func _ready() -> void:
	visible = false
	panel_opciones.hide()
	fondo.show()

func _input(event: InputEvent) -> void:
	var es_escape = event is InputEventKey and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE)
	if not event.is_action_pressed("ui_cancel") and not es_escape:
		return
	if event.is_echo():
		return

	# Evita que Escape active también otros controles de la interfaz.
	get_viewport().set_input_as_handled()

	if get_tree().paused:
		visible = false
		get_tree().paused = false
	else:
		visible = true
		panel_opciones.hide()
		fondo.show()
		get_tree().paused = true

func _on_reanudar_pressed() -> void:
	visible = false
	get_tree().paused = false

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Menus/menu_principal.tscn")

func _on_opciones_pressed() -> void:
	fondo.hide()
	panel_opciones.show()

func _on_botonvolver_pressed() -> void:
	panel_opciones.hide()
	fondo.show()

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	var mode = DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
