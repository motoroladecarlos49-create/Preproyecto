extends CanvasLayer

@onready var panel_opciones: Control = $opciones/plane
@onready var fondo: ColorRect = $ColorRect

func _ready() -> void:
	visible = false
	panel_opciones.hide()
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
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
