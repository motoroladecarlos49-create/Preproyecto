extends CanvasLayer

const FUENTE_MENU: Font = preload("res://fuente/immortal/IMMORTAL.ttf")

@onready var fondo: ColorRect = $ColorRect
@onready var titulo: Label = $titulo
@onready var boton_reanudar: Button = $reanudar
@onready var boton_opciones: Button = $opciones
@onready var boton_guardar: Button = $botonguardar
@onready var boton_cargar: Button = $botoncargar
@onready var boton_menu: Button = $menu
@onready var panel_opciones: PanelContainer = $plane
@onready var titulo_opciones: Label = $plane/MarginContainer/VBoxContainer/titulo_opciones
@onready var slider_volumen: HSlider = $plane/MarginContainer/VBoxContainer/contenedorvolumen/slidervolumen
@onready var check_pantalla: CheckButton = $plane/MarginContainer/VBoxContainer/contenedorp/pantallacompleta
@onready var selector_resolucion: OptionButton = $plane/MarginContainer/VBoxContainer/contenedorresolucion/optionbutton
@onready var boton_volver: Button = $plane/MarginContainer/VBoxContainer/botonvolver
@onready var etiqueta_estado: Label = $etiquetaestado



func _ready() -> void:
	visible = false
	panel_opciones.hide()
	fondo.show()
	_aplicar_estilo()
	_mostrar_menu_pausa()
	_configurar_opciones()
	_actualizar_boton_cargar()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	if event.keycode != KEY_ESCAPE and event.physical_keycode != KEY_ESCAPE:
		return
	if not event.pressed or event.echo:
		return

	get_viewport().set_input_as_handled()
	if not visible:
		_abrir_pausa()
	elif panel_opciones.visible:
		_volver_a_pausa()
	else:
		_cerrar_pausa()

func _abrir_pausa() -> void:
	visible = true
	panel_opciones.hide()
	fondo.show()
	etiqueta_estado.text = ""
	_mostrar_menu_pausa()
	_actualizar_boton_cargar()
	get_tree().paused = true

func _cerrar_pausa() -> void:
	visible = false
	get_tree().paused = false

func _mostrar_menu_pausa() -> void:
	titulo.show()
	boton_reanudar.show()
	boton_opciones.show()
	boton_guardar.show()
	boton_cargar.show()
	boton_menu.show()
	etiqueta_estado.show()

func _ocultar_menu_pausa() -> void:
	titulo.hide()
	boton_reanudar.hide()
	boton_opciones.hide()
	boton_guardar.hide()
	boton_cargar.hide()
	boton_menu.hide()
	etiqueta_estado.hide()

func _on_reanudar_pressed() -> void:
	_cerrar_pausa()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Menus/menu_principal.tscn")

func _on_opciones_pressed() -> void:
	_ocultar_menu_pausa()
	fondo.show()
	panel_opciones.show()
	_configurar_opciones()

func _volver_a_pausa() -> void:
	panel_opciones.hide()
	_mostrar_menu_pausa()

func _on_botonvolver_pressed() -> void:
	_volver_a_pausa()

func _on_guardar_pressed() -> void:
	var jugador := get_parent() as Node2D
	if GameManager.guardar_partida(jugador):
		etiqueta_estado.text = "PARTIDA GUARDADA"
		_actualizar_boton_cargar()
	else:
		etiqueta_estado.text = "NO SE PUDO GUARDAR"

func _on_cargar_pressed() -> void:
	if not GameManager.hay_partida_guardada():
		etiqueta_estado.text = "NO HAY UNA PARTIDA GUARDADA"
		_actualizar_boton_cargar()
		return
	if GameManager.cargar_partida():
		get_tree().paused = false
	else:
		etiqueta_estado.text = "NO SE PUDO CARGAR LA PARTIDA"

func _configurar_opciones() -> void:
	slider_volumen.min_value = 0.0
	slider_volumen.max_value = 1.0
	slider_volumen.step = 0.01
	var volumen_actual: float = GameManager.obtener_volumen_general()
	slider_volumen.set_value_no_signal(volumen_actual)
	_actualizar_relleno_volumen(volumen_actual)

	check_pantalla.set_pressed_no_signal(GameManager.obtener_pantalla_completa())
	selector_resolucion.clear()
	var resoluciones: Array[Vector2i] = GameManager.obtener_resoluciones_disponibles()
	var tamano_actual: Vector2i = GameManager.obtener_resolucion_ventana()
	for i in range(resoluciones.size()):
		selector_resolucion.add_item("%d x %d" % [resoluciones[i].x, resoluciones[i].y])
		if resoluciones[i] == tamano_actual:
			selector_resolucion.select(i)

func _actualizar_boton_cargar() -> void:
	boton_cargar.disabled = not GameManager.hay_partida_guardada()
	boton_cargar.modulate = Color(1, 1, 1, 1) if not boton_cargar.disabled else Color(0.65, 0.65, 0.65, 0.75)

func _on_slidervolumen_value_changed(value: float) -> void:
	_actualizar_relleno_volumen(value)
	GameManager.establecer_volumen_general(value)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	GameManager.establecer_pantalla_completa(toggled_on)

func _on_option_button_item_selected(index: int) -> void:
	var resoluciones: Array[Vector2i] = GameManager.obtener_resoluciones_disponibles()
	if index < 0 or index >= resoluciones.size():
		return
	GameManager.establecer_resolucion_ventana(resoluciones[index])
	check_pantalla.set_pressed_no_signal(false)


func _aplicar_estilo() -> void:
	titulo.add_theme_font_override("font", FUENTE_MENU)
	titulo.add_theme_font_size_override("font_size", 54)
	titulo_opciones.add_theme_font_override("font", FUENTE_MENU)
	titulo_opciones.add_theme_font_size_override("font_size", 34)
	var botones: Array[Button] = [boton_reanudar, boton_opciones, boton_guardar, boton_cargar, boton_menu, boton_volver]
	for i in range(botones.size()):
		var boton: Button = botones[i]
		boton.add_theme_font_override("font", FUENTE_MENU)
		boton.add_theme_font_size_override("font_size", 25)
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
	check_pantalla.add_theme_font_override("font", FUENTE_MENU)
	selector_resolucion.add_theme_font_override("font", FUENTE_MENU)
	boton_volver.add_theme_font_size_override("font_size", 22)


func _actualizar_relleno_volumen(value: float) -> void:
	var relleno: TextureRect = slider_volumen.get_node("relleno_textura")
	var material_relleno: ShaderMaterial = relleno.material as ShaderMaterial
	material_relleno.set_shader_parameter("fill_amount", clampf(value, 0.0, 1.0))
