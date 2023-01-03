extends RichTextLabel
class_name TextBox

var tween_reference : Tween


func _ready() -> void:
	visible_ratio = 0
	visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	bbcode_enabled = true


func speak_text(options := {}):
	var speaking_speed := options.get("speaking_speed", 1.0) as float
	
	skip_to_end()
	visible_ratio = 0.0
	var tw := create_tween()
	tween_reference = tw
	tw.tween_property(self, "visible_ratio", 1.0, OPT.text_speak_time * speaking_speed)


func skip_to_end():
	visible_ratio = 1.0
	if is_instance_valid(tween_reference):
		tween_reference.kill()


func set_text(into: String):
	text = into
