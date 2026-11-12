extends Area2D

@export var data: Item
var id_unico: String = ""

func _ready():
	if data == null: return
	
	z_index = 1 
	
	# --- LA SOLUCIÓN MÁGICA ---
	# Si el GameManager dice que este ítem viene de ser tirado,
	# no revisamos la lista de recogidos, solo lo mostramos.
	if GameManager.item_recien_tirado:
		GameManager.item_recien_tirado = false # Apagamos la bandera
		$Sprite2D.texture = data.icono
		var escala_padre = get_parent().scale.x
		var escala_final = GameManager.obtener_escala_item(escala_padre)
		scale = Vector2(escala_final, escala_final)
		return # Salimos para que no se autodestruya
	# ---------------------------
	
	# Lógica normal para ítems que ya estaban en el mapa
	if id_unico == "":
		id_unico = data.nombre + "_" + str(global_position)
		data.id_escena = id_unico
	
	if id_unico in GameManager.partida_actual.items_recogidos:
		queue_free() 
		return
		
	$Sprite2D.texture = data.icono 
	
	var escala_padre = get_parent().scale.x
	var escala_final = GameManager.obtener_escala_item(escala_padre)
	scale = Vector2(escala_final, escala_final)

func _on_area_entered(area):
	if area.name == "AreaRecogida":
		area.get_parent().item_cerca = self

func _on_area_exited(area):
	if area.name == "AreaRecogida":
		if area.get_parent().item_cerca == self:
			area.get_parent().item_cerca = null
