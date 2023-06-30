extends Node2D


# enter digging minigame if yes
func _on_inside_interacted()->void:SOL.dialogue("inside_police_cell");SOL.\
dialogue_closed.connect(func():{"yes":func():LTS.level_transition(
"res://scenes/mining/scn_mining_game.tscn"),"no":func():pass}.get(
SOL.dialogue_choice).call())
