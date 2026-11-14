extends Area2D

@export var escena_destino: String = ""
@export var id_puerta_destino: String = ""
@export var direccion_salida_destino: String = "down"
@export var id_punto_retorno_2d: String = ""
@export var mensaje_bloqueo: String = ""
@export var mensaje_al_entrar: String = ""
@export var requiere_llave: bool = false
@export var nombre_item_requerido: String = "Llave"

func _on_area_entered(area: Area2D) -> void:
	if area.name == "AreaRecogida":
		if mensaje_al_entrar != "":
			MessageManager.mostrar_mensaje(mensaje_al_entrar, 1.5)
		area.get_parent().puerta_cerca = self
		area.get_parent().escena_destino = escena_destino
		area.get_parent().id_puerta = id_puerta_destino
		area.get_parent().direccion_salida = direccion_salida_destino
		area.get_parent().id_punto_retorno_2d = id_punto_retorno_2d

func _on_area_exited(area: Area2D) -> void:
	if area.name == "AreaRecogida":
		if area.get_parent().puerta_cerca == self:
			area.get_parent().puerta_cerca = null
			area.get_parent().escena_destino = ""
			area.get_parent().id_punto_retorno_2d = ""
