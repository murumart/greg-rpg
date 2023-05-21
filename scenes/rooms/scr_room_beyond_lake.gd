extends Room

@onready var spirit := $Areas/SunSpirit


func _ready() -> void:
	super._ready()
	if DAT.get_data("sun_spirit_engaged", false):
		spirit.queue_free()


func _on_sun_spirit_inspected() -> void:
	$Areas/SunSpirit/AmbientLoop.playing = false
	DAT.set_data("sun_spirit_engaged", true)
