extends Area2D

@export var escena_destino: String = "" 
@export var id_puerta_destino: String = "" 
@export var direccion_salida_destino: String = "down" 

func _on_area_entered(area):
	if area.name == "AreaRecogida":
		area.get_parent().puerta_cerca = self
		area.get_parent().escena_destino = escena_destino
		area.get_parent().id_puerta = id_puerta_destino
		area.get_parent().direccion_salida = direccion_salida_destino
		print("El jugador está cerca de la puerta.")

func _on_area_exited(area):
	if area.name == "AreaRecogida":
		if area.get_parent().puerta_cerca == self:
			area.get_parent().puerta_cerca = null
			area.get_parent().escena_destino = ""
