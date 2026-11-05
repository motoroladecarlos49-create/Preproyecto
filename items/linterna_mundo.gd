extends Area2D

@export var data: Item

func _ready():
	if data != null:
		$Sprite2D.texture = data.icono 
	else:
		print("ADVERTENCIA: El objeto no tiene datos asignados.")

func _on_area_entered(area):
	if area.name == "AreaRecogida":
		area.get_parent().item_cerca = self
		print("¡El jugador está cerca del ítem!")

func _on_area_exited(area):
	if area.name == "AreaRecogida":
		if area.get_parent().item_cerca == self:
			area.get_parent().item_cerca = null
			print("El jugador se alejó del ítem.")
