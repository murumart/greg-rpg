extends Node2D

@onready var science_g_uy: OverworldCharacter = $ScienceGUy


func _ready() -> void:
	if "town_east" in DAT.get_data("visited_rooms", []):
		science_g_uy.queue_free()
		return
	if DAT.get_data("popo_blockade_lifted", false):
		science_g_uy.default_lines = ["science_guy_free_1", "science_guy_free_2"]
