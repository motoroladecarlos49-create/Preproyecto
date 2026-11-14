extends Control

@onready var grid_container: GridContainer = $PanelContainer/GridContainer
@onready var btn_drop: Button = $BtnDrop

var mochila: Mochila
var player: Node
var modo_drop: bool = false

func _ready() -> void:
	var nodo_actual: Node = get_parent()
	while nodo_actual != null:
		if nodo_actual.has_method("tirar_item"):
			player = nodo_actual
			break
		nodo_actual = nodo_actual.get_parent()

	for slot in grid_container.get_children():
		slot.gui_input.connect(_on_slot_gui_input.bind(slot))

	btn_drop.pressed.connect(_on_btn_drop_pressed)
	hide()

func conectar_mochila():
	if mochila != null:
		if not mochila.mochila_actualizada.is_connected(redibujar_inventario):
			mochila.mochila_actualizada.connect(redibujar_inventario)
		if not mochila.item_seleccionado_cambiado.is_connected(actualizar_resaltado):
			mochila.item_seleccionado_cambiado.connect(actualizar_resaltado)
		redibujar_inventario()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventario"):
		if mochila == null:
			return
		visible = not visible
		if visible:
			redibujar_inventario()
			if mochila.objetos.size() > 0 and not GameManager.tutorial_lampara_completado:
				MessageManager.mostrar_mensaje("Haz clic para seleccionar un ítem", 2.0)
		else:
			modo_drop = false
			btn_drop.modulate = Color(1, 1, 1)

func _on_btn_drop_pressed():
	modo_drop = not modo_drop
	btn_drop.modulate = Color(1, 0.3, 0.3) if modo_drop else Color(1, 1, 1)

func _on_slot_gui_input(event: InputEvent, slot: Panel):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if slot.item_data != null:
			if modo_drop and player != null and player.has_method("tirar_item"):
				player.call("tirar_item", slot.clave_item, slot.item_data)
				redibujar_inventario()
				modo_drop = false
				btn_drop.modulate = Color(1, 1, 1)
			else:
				mochila.seleccionar_item(slot.clave_item)

func redibujar_inventario():
	if mochila == null:
		return
	var claves = mochila.objetos.keys()
	var slots = grid_container.get_children()
	for i in range(slots.size()):
		if i < claves.size():
			slots[i].llenar_espacio(mochila.objetos[claves[i]], claves[i])
		else:
			slots[i].vaciar_valores()
	actualizar_resaltado(mochila.item_seleccionado)

func actualizar_resaltado(item_actual: Item):
	for slot in grid_container.get_children():
		slot.set_seleccionado(slot.item_data != null and slot.item_data == item_actual)
