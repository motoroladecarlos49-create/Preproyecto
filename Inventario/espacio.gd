extends Panel

@onready var icono_item: TextureRect = $TextureRect
@onready var label: Label = $Label

var item_data: Item = null
var clave_item: String = ""
var color_original: Color # Variable para guardar el color base

signal item_soltado(clave_origen, clave_destino)

func _ready():
	# Guardamos el color que le pusiste al Panel en el editor
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
	self_modulate = color_original # Volvemos a su color original
	hide()

func set_seleccionado(seleccionado: bool):
	if seleccionado:
		# Resaltado notorio: Amarillo brillante
		self_modulate = Color(1.0, 0.9, 0.2) 
		
		# (Opcional) Si prefieres un resaltado Cian:
		# self_modulate = Color(0.0, 1.0, 1.0)
	else:
		# Volver al color normal cuando se deselecciona
		self_modulate = color_original

# --- LÓGICA DE DRAG & DROP ---
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Panel

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not item_data: # Si este slot está vacío
		item_soltado.emit(data.clave_item, "") 
		llenar_espacio(data.item_data, data.clave_item)
		data.vaciar_valores()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not item_data: return null
	var drag_preview = TextureRect.new()
	drag_preview.texture = icono_item.texture
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_preview.custom_minimum_size = Vector2(32, 32)
	set_drag_preview(drag_preview)
	return self
