extends Resource
class_name Character

# this will be interpreted by the battle system and dialogue system

@export_group("Appearance")
@export var name := ""
@export var voice_sound : AudioStream
@export var portrait : Texture

@export_group("Stats")
@export var level := 1
@export var attack := 1.0
@export var defense := 1.0
@export var speed := 1.0

@export_group("Items")
@export var inventory : Array[int]
@export var armour : int
@export var weapon : int

@export_group("")
@export var name_in_file : String = ""
