extends CanvasLayer

const FUENTE_MENU: Font = preload("res://fuente/immortal/IMMORTAL.ttf")

var panel_mensaje: PanelContainer
var label_mensaje: Label
var timer: Timer

func _ready() -> void:
	panel_mensaje = PanelContainer.new()
	panel_mensaje.name = "PanelMensajeTutorial"
	panel_mensaje.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel_mensaje.offset_left = 120.0
	panel_mensaje.offset_top = -132.0
	panel_mensaje.offset_right = -120.0
	panel_mensaje.offset_bottom = -38.0
	panel_mensaje.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.075, 0.082, 0.12, 0.94)
	estilo.border_color = Color("#a88c5b")
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(10)
	estilo.shadow_color = Color(0, 0, 0, 0.5)
	estilo.shadow_size = 10
	estilo.content_margin_left = 24.0
	estilo.content_margin_right = 24.0
	estilo.content_margin_top = 12.0
	estilo.content_margin_bottom = 12.0
	panel_mensaje.add_theme_stylebox_override("panel", estilo)
	add_child(panel_mensaje)

	label_mensaje = Label.new()
	label_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_mensaje.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_mensaje.add_theme_font_override("font", FUENTE_MENU)
	label_mensaje.add_theme_font_size_override("font_size", 22)
	label_mensaje.add_theme_color_override("font_color", Color("#ead7ad"))
	label_mensaje.add_theme_color_override("font_shadow_color", Color("#11131b"))
	label_mensaje.add_theme_constant_override("shadow_offset_x", 2)
	label_mensaje.add_theme_constant_override("shadow_offset_y", 2)
	panel_mensaje.add_child(label_mensaje)
	panel_mensaje.hide()

	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

func mostrar_mensaje(texto: String, duracion: float = 2.0) -> void:
	if label_mensaje.text == texto and timer.time_left > 0.0:
		return
	label_mensaje.text = texto
	panel_mensaje.show()
	timer.start(duracion)

func _on_timer_timeout() -> void:
	panel_mensaje.hide()
	label_mensaje.text = ""
