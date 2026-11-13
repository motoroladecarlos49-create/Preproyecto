extends CanvasLayer

@onready var panel_opciones: Control = $opciones/plane
@onready var fondo: ColorRect = $ColorRect
@onready var slider_volumen: HSlider = $opciones/plane/MarginContainer/VBoxContainer/contenedorvolumen/slidervolumen
@onready var check_pantalla: CheckButton = $opciones/plane/MarginContainer/VBoxContainer/contenedorp/pantallacompleta
@onready var selector_resolucion: OptionButton = $opciones/plane/MarginContainer/VBoxContainer/contenedorresolucion/optionbutton
@onready var etiqueta_estado: Label = $etiquetaestado
@onready var boton_cargar: Button = $botoncargar

var bus_index: int = AudioServer.get_bus_index("Master")
var resoluciones: Array[Vector2i] = [Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(720, 480)]

func _ready() -> void:
	visible = false
	panel_opciones.hide()
	fondo.show()
	_configurar_opciones()
	_actualizar_boton_cargar()

func _input(event: InputEvent) -> void:
	# Una pulsación completa abre o cierra la pausa; no depende de mantener Esc.
	if not (event is InputEventKey):
		return
	if event.keycode != KEY_ESCAPE and event.physical_keycode != KEY_ESCAPE:
		return
	if not event.pressed or event.echo:
		return

	get_viewport().set_input_as_handled()
	if visible:
		_cerrar_pausa()
	else:
		_abrir_pausa()

func _abrir_pausa() -> void:
	visible = true
	panel_opciones.hide()
	fondo.show()
	etiqueta_estado.text = ""
	_actualizar_boton_cargar()
	get_tree().paused = true

func _cerrar_pausa() -> void:
	visible = false
	get_tree().paused = false

func _on_reanudar_pressed() -> void:
	_cerrar_pausa()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Menus/menu_principal.tscn")

func _on_opciones_pressed() -> void:
	fondo.hide()
	panel_opciones.show()
	_configurar_opciones()

func _on_botonvolver_pressed() -> void:
	panel_opciones.hide()
	fondo.show()

func _on_guardar_pressed() -> void:
	var jugador := get_parent() as Node2D
	if GameManager.guardar_partida(jugador):
		etiqueta_estado.text = "Partida guardada correctamente."
	else:
		etiqueta_estado.text = "No se pudo guardar la partida."

func _on_cargar_pressed() -> void:
	if not GameManager.hay_partida_guardada():
		etiqueta_estado.text = "No hay una partida guardada válida."
		_actualizar_boton_cargar()
		return
	if not GameManager.cargar_partida():
		etiqueta_estado.text = "No se pudo cargar la partida."
	else:
		get_tree().paused = false

func _configurar_opciones() -> void:
	if bus_index >= 0:
		slider_volumen.min_value = 0.0
		slider_volumen.max_value = 1.0
		slider_volumen.step = 0.01
		slider_volumen.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(bus_index)))
		check_pantalla.set_pressed_no_signal(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
		selector_resolucion.clear()
		for resolucion in resoluciones:
			selector_resolucion.add_item("%d x %d" % [resolucion.x, resolucion.y])
		var tamano := get_window().size
		for i in range(resoluciones.size()):
			if resoluciones[i] == tamano:
				selector_resolucion.select(i)
				break

func _actualizar_boton_cargar() -> void:
	boton_cargar.disabled = not GameManager.hay_partida_guardada()

func _on_slidervolumen_value_changed(value: float) -> void:
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.001)))
	AudioServer.set_bus_mute(bus_index, value <= 0.0)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	var mode = DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func _on_option_button_item_selected(index: int) -> void:
	if index < 0 or index >= resoluciones.size():
		return
	get_window().size = resoluciones[index]
	get_window().move_to_center()
