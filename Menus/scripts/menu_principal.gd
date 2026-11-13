extends Control

const FUENTE_MENU: Font = preload("res://fuente/immortal/IMMORTAL.ttf")

@onready var contenedor_menu: VBoxContainer = $contenedorMenu
@onready var submenu_opciones: PanelContainer = $submenuOpciones
@onready var titulo: Label = $contenedorMenu/texto
@onready var boton_jugar: Button = $contenedorMenu/botonjugar
@onready var boton_opciones: Button = $contenedorMenu/botonopciones
@onready var boton_salir: Button = $contenedorMenu/botonsalir
@onready var titulo_opciones: Label = $submenuOpciones/MarginContainer/VBoxOpciones/texto2
@onready var slider_volumen: HSlider = $submenuOpciones/MarginContainer/VBoxOpciones/contenedorvolumen/slidervolumen
@onready var check_pantalla: CheckButton = $submenuOpciones/MarginContainer/VBoxOpciones/contenedorpantalla/pantallacompleta
@onready var option_button: OptionButton = $submenuOpciones/MarginContainer/VBoxOpciones/contenedorresolucion/optionbutton
@onready var boton_volver: Button = $submenuOpciones/MarginContainer/VBoxOpciones/botoncerrar

var bus_index: int = AudioServer.get_bus_index("Master")
var boton_continuar: Button
var dialogo_nueva_partida: ConfirmationDialog
var resoluciones: Array[Vector2i] = [Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(720, 480)]

func _ready() -> void:
	submenu_opciones.hide()
	_aplicar_estilo()
	_configurar_opciones()
	if GameManager.hay_partida_guardada():
		_agregar_boton_continuar()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	if event.keycode != KEY_ESCAPE and event.physical_keycode != KEY_ESCAPE:
		return
	if not event.pressed or event.echo or not submenu_opciones.visible:
		return
	get_viewport().set_input_as_handled()
	_volver_al_menu()

func _agregar_boton_continuar() -> void:
	boton_continuar = Button.new()
	boton_continuar.name = "botoncontinuar"
	boton_continuar.text = "CONTINUAR"
	boton_continuar.custom_minimum_size = Vector2(330, 58)
	boton_continuar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_estilizar_boton(boton_continuar, 25)
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
	_volver_al_menu()

func _volver_al_menu() -> void:
	submenu_opciones.hide()
	contenedor_menu.show()

func _configurar_opciones() -> void:
	if bus_index >= 0:
		var volumen_actual: float = 0.0 if AudioServer.is_bus_mute(bus_index) else db_to_linear(AudioServer.get_bus_volume_db(bus_index))
		slider_volumen.set_value_no_signal(volumen_actual)

	check_pantalla.set_pressed_no_signal(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	option_button.clear()
	var tamano_actual: Vector2i = get_window().size
	for i in range(resoluciones.size()):
		option_button.add_item("%d x %d" % [resoluciones[i].x, resoluciones[i].y])
		if resoluciones[i] == tamano_actual:
			option_button.select(i)

func _on_slidervolumen_value_changed(value: float) -> void:
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.001)))
	AudioServer.set_bus_mute(bus_index, value <= 0.0)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func _on_option_button_item_selected(index: int) -> void:
	if index < 0 or index >= resoluciones.size():
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(resoluciones[index])
	get_window().move_to_center()
	check_pantalla.set_pressed_no_signal(false)

func _aplicar_estilo() -> void:
	titulo.add_theme_font_override("font", FUENTE_MENU)
	titulo.add_theme_font_size_override("font_size", 58)
	titulo.add_theme_color_override("font_color", Color("#ead7ad"))
	titulo.add_theme_color_override("font_shadow_color", Color("#11131b"))
	titulo.add_theme_constant_override("shadow_offset_x", 3)
	titulo.add_theme_constant_override("shadow_offset_y", 4)
	titulo_opciones.add_theme_font_override("font", FUENTE_MENU)
	titulo_opciones.add_theme_font_size_override("font_size", 36)
	titulo_opciones.add_theme_color_override("font_color", Color("#ead7ad"))
	var botones: Array[Button] = [boton_jugar, boton_opciones, boton_salir, boton_volver]
	for i in range(botones.size()):
		_estilizar_boton(botones[i], 27 if i < 3 else 22)
	check_pantalla.add_theme_font_override("font", FUENTE_MENU)
	option_button.add_theme_font_override("font", FUENTE_MENU)
	option_button.add_theme_font_size_override("font_size", 20)

func _estilizar_boton(boton: Button, tamano_fuente: int) -> void:
	boton.add_theme_font_override("font", FUENTE_MENU)
	boton.add_theme_font_size_override("font_size", tamano_fuente)
	boton.custom_minimum_size = Vector2(330, 58)
	boton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#252735")
	normal.border_color = Color("#a88c5b")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(9)
	normal.content_margin_left = 18.0
	normal.content_margin_right = 18.0
	normal.content_margin_top = 10.0
	normal.content_margin_bottom = 10.0
	boton.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#3b3b4b")
	hover.border_color = Color("#e0c58a")
	boton.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#171923")
	boton.add_theme_stylebox_override("pressed", pressed)
