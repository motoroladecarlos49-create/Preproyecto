extends Control

const NOMBRES: Array[String] = [
	"Valderrey Jimena",
	"Vallejos Carlos Anibal",
	"Veron Sack María Eugenia",
	"Videla Duhalde Dana Milagros"
]

var contenedor: VBoxContainer

func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var centrador := CenterContainer.new()
	centrador.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centrador)

	contenedor = VBoxContainer.new()
	contenedor.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor.add_theme_constant_override("separation", 18)
	centrador.add_child(contenedor)

	await _mostrar_mensaje_inicial()
	await _mostrar_integrantes()
	await get_tree().create_timer(2.0).timeout

	var salida := create_tween().set_parallel(true)
	for elemento in contenedor.get_children():
		salida.tween_property(elemento, "modulate:a", 0.0, 0.9)
	await salida.finished

	GameManager.menu_desde_creditos = true
	var error := get_tree().change_scene_to_file("res://Menus/menu_principal.tscn")
	if error != OK:
		push_error("No se pudo volver al menú principal. Código: %s" % error)

func _crear_texto(texto: String, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.modulate.a = 0.0
	contenedor.add_child(etiqueta)
	return etiqueta

func _mostrar_mensaje_inicial() -> void:
	var mensaje := _crear_texto("¡Gracias por jugar esta beta! :D", 36)
	var entrada := create_tween()
	entrada.tween_property(mensaje, "modulate:a", 1.0, 1.0)
	await entrada.finished
	await get_tree().create_timer(2.0).timeout
	var salida := create_tween()
	salida.tween_property(mensaje, "modulate:a", 0.0, 1.0)
	await salida.finished
	mensaje.queue_free()

func _mostrar_integrantes() -> void:
	var titulo := _crear_texto("Integrantes:", 34)
	var entrada_titulo := create_tween()
	entrada_titulo.tween_property(titulo, "modulate:a", 1.0, 0.8)
	await entrada_titulo.finished
	for nombre in NOMBRES:
		var etiqueta := _crear_texto(nombre, 27)
		var entrada := create_tween()
		entrada.tween_property(etiqueta, "modulate:a", 1.0, 0.7)
		await entrada.finished
		await get_tree().create_timer(0.35).timeout
