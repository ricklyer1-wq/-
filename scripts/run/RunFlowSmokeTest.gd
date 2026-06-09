extends SceneTree

func _initialize() -> void:
	var manager_script = load("res://scripts/run/RunManager.gd")
	var manager = manager_script.new()
	root.add_child(manager)
	
	var battle_scene = load("res://scenes/battle/BattleScene.tscn")
	var instance = battle_scene.instantiate()
	root.add_child(instance)
	
	var file = FileAccess.open("res://ui_inspection.log", FileAccess.WRITE)
	if file:
		file.store_line("=== BattleScene Direct Children ===")
		for child in instance.get_children():
			file.store_line("  Child: " + child.name + " Class: " + child.get_class())
		file.close()
	quit()
