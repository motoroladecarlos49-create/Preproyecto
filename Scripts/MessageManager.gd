extends CanvasLayer

var label_mensaje: Label
var timer: Timer

# Bandera global para saber si el tutorial de la lámpara ya se mostró
var tutorial_lampara_completado: bool = false 

func _ready():
	label_mensaje = Label.new()
	label_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_mensaje.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	
	label_mensaje.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	label_mensaje.offset_bottom = -50
	label_mensaje.offset_top = -100
	
	label_mensaje.add_theme_font_size_override("font_size", 22)
	label_mensaje.add_theme_color_override("font_color", Color.WHITE)
	label_mensaje.add_theme_color_override("font_shadow_color", Color.BLACK)
	label_mensaje.add_theme_constant_override("shadow_offset_x", 2)
	label_mensaje.add_theme_constant_override("shadow_offset_y", 2)
	
	add_child(label_mensaje)
	label_mensaje.hide()
	
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

func mostrar_mensaje(texto: String, duracion: float = 2.0):
	if label_mensaje.text == texto and timer.time_left > 0:
		return 
		
	label_mensaje.text = texto
	label_mensaje.show()
	timer.start(duracion)

func _on_timer_timeout():
	label_mensaje.hide()
	label_mensaje.text = "" 
