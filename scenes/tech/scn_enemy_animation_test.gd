extends Node2D

var enemy: BattleEnemy

@onready var option_button: OptionButton = $OptionButton
@onready var line_edit: LineEdit = $LineEdit


func _ready() -> void:
	for k: StringName in ResMan.characters.keys():
		option_button.add_item(k)
	option_button.item_selected.connect(func(item: int):
		if is_instance_valid(enemy):
			enemy.queue_free()
		var enemy_name := option_button.get_item_text(item)
		_add_enemy(enemy_name)
	)
	line_edit.text_submitted.connect(func(text: String):
		if is_instance_valid(enemy):
			enemy.animate(text)
	)
	option_button.grab_focus()


func _add_enemy(character_id: StringName) -> void:
	var character: Character = ResMan.get_character(character_id)
	var node: BattleActor
	if DIR.enemy_scene_exists(character_id):
		node = load(DIR.enemy_scene_path(character_id)).instantiate()
		node.load_character(character_id)
	else:
		node = preload("res://scenes/tech/scn_battle_enemy.tscn").instantiate()
		node.load_character(character_id)
		var sprite_new := Sprite2D.new()
		node.add_child(sprite_new)
		sprite_new.texture = preload(
				"res://sprites/characters/battle/spr_enemy_battle.png")
		node.effect_center = Vector2i(0, -20)
	enemy = node
	add_child(enemy)
