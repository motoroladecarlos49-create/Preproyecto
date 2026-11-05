extends Control

@onready var grid_container: GridContainer = $PanelContainer/GridContainer
@onready var btn_drop: Button = $BtnDrop

@export var mochila: Mochila
var player: CharacterBody2D 
var modo_drop: bool = false

func _ready() -> void:
	if mochila == null:
		print("ERROR CRÍTICO: La Mochila no está asignada en el Inspector de la UI.")
		return
		
	var nodo_actual = get_parent()
	while nodo_actual != null:
		if nodo_actual is CharacterBody2D:
			player = nodo_actual
			break
		nodo_actual = nodo_actual.get_parent()

	mochila.mochila_actualizada.connect(redibujar_inventario)
	mochila.item_seleccionado_cambiado.connect(actualizar_resaltado)
	
	for slot in grid_container.get_children():
		slot.gui_input.connect(_on_slot_gui_input.bind(slot))
	
	btn_drop.pressed.connect(_on_btn_drop_pressed)
	
	redibujar_inventario()
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventario"):
		if mochila == null: return
			
		visible = not visible
		
		if visible:
			# Solo mostramos el mensaje si el tutorial NO ha sido completado
			if mochila.objetos.size() > 0 and not MessageManager.tutorial_lampara_completado:
				MessageManager.mostrar_mensaje("Haz clic para seleccionar un ítem", 2.0)
		else:
			modo_drop = false
			btn_drop.modulate = Color(1, 1, 1)

func _on_btn_drop_pressed():
	modo_drop = not modo_drop
	if modo_drop:
		btn_drop.modulate = Color(1, 0.3, 0.3)
	else:
		btn_drop.modulate = Color(1, 1, 1)

func _on_slot_gui_input(event: InputEvent, slot: Panel):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if slot.item_data != null:
			if modo_drop and player != null:
				player.tirar_item(slot.clave_item, slot.item_data)
				modo_drop = false
				btn_drop.modulate = Color(1, 1, 1)
			else:
				mochila.seleccionar_item(slot.clave_item)

func redibujar_inventario():
	if mochila == null: return
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
