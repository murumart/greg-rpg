extends Room

@onready var spirit := $Areas/SunSpirit


func _ready() -> void:
	super._ready()


func _on_sun_spirit_inspected() -> void:
	$Areas/SunSpirit/AmbientLoop.playing = false
