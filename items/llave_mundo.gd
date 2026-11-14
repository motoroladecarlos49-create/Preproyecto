extends Area2D

@export var data: Item
var id_unico: String = ""

func _ready() -> void:
	if data == null:
		return

	z_index = 1
	if id_unico == "":
		id_unico = data.id_escena
	if id_unico == "":
		id_unico = data.nombre + "_" + str(global_position)
		data.id_escena = id_unico

	if GameManager.partida_actual.items_recogidos.has(id_unico):
		queue_free()
		return

	data.id_escena = id_unico
	$Sprite2D.texture = data.icono

	var escala_padre := 1.0
	if get_parent() is Node2D:
		escala_padre = (get_parent() as Node2D).scale.x
	var escala_final := GameManager.obtener_escala_item(escala_padre)
	scale = Vector2(escala_final, escala_final)

func _on_area_entered(area: Area2D) -> void:
	if area.name == "AreaRecogida":
		area.get_parent().item_cerca = self

func _on_area_exited(area: Area2D) -> void:
	if area.name == "AreaRecogida" and area.get_parent().item_cerca == self:
		area.get_parent().item_cerca = null
