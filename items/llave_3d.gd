extends RigidBody3D

@export var data: Item
var id_unico: String = ""

func _ready() -> void:
	if data == null:
		return

	add_to_group("items_tirados_3d")

	if id_unico == "":
		id_unico = data.id_escena
	if id_unico == "":
		id_unico = "Llave_3D_mapa"
		data.id_escena = id_unico

	if GameManager.partida_actual.items_recogidos.has(id_unico):
		queue_free()
		return

	data.id_escena = id_unico

func _on_area_recogida_body_entered(body: Node3D) -> void:
	if body.has_method("establecer_item_cerca_3d"):
		body.establecer_item_cerca_3d(self)

func _on_area_recogida_body_exited(body: Node3D) -> void:
	if body.has_method("establecer_item_cerca_3d") and body.get("item_cerca_3d") == self:
		body.establecer_item_cerca_3d(null)
