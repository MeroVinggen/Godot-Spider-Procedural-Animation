@tool
extends Node3D

@export var show_debug_items: bool = true :
	set(value):
		show_debug_items = value
	
		for item: Node in Engine.get_main_loop().get_nodes_in_group("debug_item"):
			if value:
				item.visible = true
			else:
				item.visible = false


func _ready() -> void:
	print("-------------------------")
	print("press 'R' to reload scene")
	print("press 'right mouse click' + 'WASD' to control the camera")
	print("-------------------------")


func _unhandled_input(event):
	if event is InputEventKey and event.keycode == KEY_R and event.pressed:
		get_tree().reload_current_scene()
