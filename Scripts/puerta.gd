extends Area2D

@export var escena_destino: String = "" 
@export var id_puerta_destino: String = "" 
@export var direccion_salida_destino: String = "down" 
@export var id_punto_retorno_2d: String = ""
@export var mensaje_bloqueo: String = ""
@export var mensaje_al_entrar: String = ""

func _on_area_entered(area):
	if area.name == "AreaRecogida":
		if mensaje_al_entrar != "":
			MessageManager.mostrar_mensaje(mensaje_al_entrar, 1.5)
		area.get_parent().puerta_cerca = self
		area.get_parent().escena_destino = escena_destino
		area.get_parent().id_puerta = id_puerta_destino
		area.get_parent().direccion_salida = direccion_salida_destino
		area.get_parent().id_punto_retorno_2d = id_punto_retorno_2d
		print("El jugador está cerca de la puerta.")

func _on_area_exited(area):
	if area.name == "AreaRecogida":
		if area.get_parent().puerta_cerca == self:
			area.get_parent().puerta_cerca = null
			area.get_parent().escena_destino = ""
			area.get_parent().id_punto_retorno_2d = ""
