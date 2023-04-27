extends Node2D


func init(options := {}) -> void:
	var item_texture : Texture
	item_texture = options.get("item_texture", null)
	
	if item_texture: $Sprite2D.texture = item_texture
