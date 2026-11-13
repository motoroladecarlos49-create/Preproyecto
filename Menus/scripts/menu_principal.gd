extends Control

@onready var contenedor_menu: VBoxContainer = $contenedorMenu
@onready var submenu_opciones: PanelContainer = $submenuOpciones
@onready var bus_index: int = AudioServer.get_bus_index("Master")
@onready var option_button: OptionButton = $submenuOpciones/MarginContainer/VBoxOpciones/HBoxContainer/optionbutton

var boton_continuar: Button
var dialogo_nueva_partida: ConfirmationDialog

func _ready() -> void:
	submenu_opciones.hide()
	_configurar_opciones()
	if GameManager.hay_partida_guardada():
		_agregar_boton_continuar()

func _agregar_boton_continuar() -> void:
	boton_continuar = Button.new()
	boton_continuar.name = "botoncontinuar"
	boton_continuar.text = "Continuar"
	boton_continuar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	boton_continuar.add_theme_font_size_override("font_size", 35)
	boton_continuar.pressed.connect(_on_botoncontinuar_pressed)
	contenedor_menu.add_child(boton_continuar)
	contenedor_menu.move_child(boton_continuar, 1)

func _on_botonjugar_pressed() -> void:
	if GameManager.hay_partida_guardada():
		dialogo_nueva_partida = ConfirmationDialog.new()
		dialogo_nueva_partida.title = "Nueva partida"
		dialogo_nueva_partida.dialog_text = "Ya existe una partida guardada. Si comienzas una nueva, se eliminará ese guardado. ¿Quieres continuar?"
		dialogo_nueva_partida.ok_button_text = "Iniciar nueva partida"
		dialogo_nueva_partida.confirmed.connect(_iniciar_nueva_partida)
		add_child(dialogo_nueva_partida)
		dialogo_nueva_partida.popup_centered()
	else:
		_iniciar_nueva_partida()

func _iniciar_nueva_partida() -> void:
	if not GameManager.eliminar_partida_guardada():
		push_error("No se pudo eliminar el guardado anterior. No se inició una nueva partida.")
		return
	GameManager.iniciar_partida_nueva()
	get_tree().change_scene_to_file("res://Escenas/habitacion1.tscn")

func _on_botoncontinuar_pressed() -> void:
	if not GameManager.cargar_partida():
		push_warning("No se pudo cargar la partida guardada.")

func _on_botonopciones_pressed() -> void:
	contenedor_menu.hide()
	submenu_opciones.show()
	_configurar_opciones()

func _on_botonsalir_pressed() -> void:
	get_tree().quit()

func _on_botoncerrar_pressed() -> void:
	submenu_opciones.hide()
	contenedor_menu.show()

func _configurar_opciones() -> void:
	if bus_index < 0:
		return
	var slider: HSlider = $submenuOpciones/MarginContainer/VBoxOpciones/contenedorvolumen/slidervolumen
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(bus_index)))
	var check: CheckButton = $submenuOpciones/MarginContainer/VBoxOpciones/contenedorpantalla/pantallacompleta
	check.set_pressed_no_signal(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	var tamano := get_window().size
	for i in range(3):
		var resolucion := [Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(720, 480)][i]
		if resolucion == tamano:
			option_button.select(i)
			break

func _on_slidervolumen_value_changed(value: float) -> void:
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.001)))
	AudioServer.set_bus_mute(bus_index, value <= 0.0)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	var mode = DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func _on_option_button_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1600, 900))
		1:
			DisplayServer.window_set_size(Vector2i(1280, 720))
		2:
			DisplayServer.window_set_size(Vector2i(720, 480))
	get_window().move_to_center()
