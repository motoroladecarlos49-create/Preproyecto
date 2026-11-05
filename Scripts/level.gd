extends Node2D # O el tipo de nodo que sea tu nivel

func _ready():
	# Esperamos un pequeño instante a que el nivel cargue y mostramos el mensaje
	await get_tree().create_timer(0.5).timeout
	MessageManager.mostrar_mensaje("Muévete con W, A, S, D", 3.0)
