extends Control

@onready var contenedor_menu = $contenedorMenu
@onready var submenu_opciones = $submenuOpciones
@onready var slider_volumen = $submenuOpciones/MarginContainer/VBoxOpciones/contenedorvolumen/slidervolumen
@onready var pantalla_completa = $submenuOpciones/MarginContainer/VBoxOpciones/contenedorpantalla/pantallacompleta
@onready var bus_index = AudioServer.get_bus_index("Master")
@onready var option_button: OptionButton = $submenuOpciones/MarginContainer/VBoxOpciones/HBoxContainer/OptionButton



func _on_botonjugar_pressed() -> void:
	get_tree().change_scene_to_file("res://xx/x.tscn")
	
func _on_botonopciones_pressed() -> void:
	contenedor_menu.visible = false
	submenu_opciones.visible = true
	

func _on_botonsalir_pressed() -> void:
	get_tree().quit()


func _on_botoncerrar_pressed() -> void:
	submenu_opciones.visible = false
	contenedor_menu.visible = true



func _on_slidervolumen_value_changed(value: float) -> void:
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_index, db_value)
	AudioServer.set_bus_mute(bus_index, value == 0)


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_option_button_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1600, 900))
		1:
			DisplayServer.window_set_size(Vector2i(1280, 720))
		2:
			DisplayServer.window_set_size(Vector2i(720, 480))
			
	get_window().move_to_center()
