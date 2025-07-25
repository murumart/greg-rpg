extends Node2D


func init(options := {}):
	if options.get("silent", false):
		return
	$AudioStreamPlayer.play()
