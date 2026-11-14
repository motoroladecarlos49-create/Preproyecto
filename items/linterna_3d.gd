extends RigidBody3D

@export var data: Item
var id_unico: String = ""
var esta_encendida: bool = false

@onready var luz: OmniLight3D = $Luz

func _ready() -> void:
	if data == null:
		return

	if id_unico == "":
		id_unico = data.id_escena
	if id_unico == "":
		id_unico = data.nombre + "_3d_" + str(global_position)
		data.id_escena = id_unico

	if GameManager.partida_actual.items_recogidos.has(id_unico):
		queue_free()
		return

	data.id_escena = id_unico
	luz.visible = esta_encendida

func configurar_estado(encendida: bool) -> void:
	esta_encendida = encendida
	if is_node_ready():
		luz.visible = esta_encendida

func _on_area_recogida_body_entered(body: Node3D) -> void:
	if body.has_method("establecer_item_cerca_3d"):
		body.establecer_item_cerca_3d(self)

func _on_area_recogida_body_exited(body: Node3D) -> void:
	if body.has_method("establecer_item_cerca_3d") and body.get("item_cerca_3d") == self:
		body.establecer_item_cerca_3d(null)
