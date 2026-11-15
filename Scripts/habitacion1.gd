extends Node2D # O el tipo de nodo que sea tu nivel

func _ready():
	# Esperamos un pequeño instante a que el nivel cargue y mostramos el mensaje
	await get_tree().create_timer(0.5).timeout
	if not GameManager.tutorial_movimiento_completado:
		GameManager.tutorial_movimiento_completado = true
		MessageManager.mostrar_mensaje("Muévete con W, A, S, D", 3.0)

func _on_area_cajonera_area_entered(area: Area2D) -> void:
	if area.name == "AreaRecogida":
		area.get_parent().cajonera_cerca = true

func _on_area_cajonera_area_exited(area: Area2D) -> void:
	if area.name == "AreaRecogida":
		area.get_parent().cajonera_cerca = false
