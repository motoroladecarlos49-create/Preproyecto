extends Panel

@onready var icono_item: TextureRect = $TextureRect
@onready var label: Label = $Label

var item_data: Item = null
var clave_item: String = ""
var color_original: Color 

func _ready():
	color_original = self_modulate

func llenar_espacio(item: Item, nueva_clave: String):
	item_data = item
	clave_item = nueva_clave
	label.text = str(item.cantidad) if item.apilable and item.cantidad > 1 else ""
	icono_item.texture = item.icono
	show()

func vaciar_valores():
	item_data = null
	clave_item = ""
	label.text = ""
	icono_item.texture = null
	self_modulate = color_original
	hide()

func set_seleccionado(seleccionado: bool):
	if seleccionado:
		self_modulate = Color(1.0, 0.9, 0.2) 
	else:
		self_modulate = color_original
