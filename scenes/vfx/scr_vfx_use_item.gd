extends Node2D


func init(options := {}) -> void:
	print(options)
	var item_texture : Texture
	item_texture = options.get("item_texture", null)
	print(item_texture)
		
	if item_texture: $Sprite2D.texture = item_texture
