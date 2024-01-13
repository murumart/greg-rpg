class_name MusBarCounter extends Node

# emits signals when a new bar passes in music based on its bpm and time signature

signal new_bar(bar: int)
signal new_beat

@export var bpm := 120.0
@export var beats_per_bar := 4.0
var bars := 0
var beats := 0.0
var flbar := 0.0
var flbeat := 0.0


func _process(delta: float) -> void:
	flbar += delta / (60 * beats_per_bar / bpm)
	flbeat += delta / (60 / bpm)
	if flbeat >= beats + 1:
		beats += 1
		new_beat.emit()
	if flbar >= bars + 1:
		bars += 1
		new_bar.emit(bars)


func reset_floats() -> void:
	flbar = 0.0
	flbeat = 0.0


func reset_measures() -> void:
	bars = 0
	beats = 0


"
									   /
									  /
									 /
									/
								   /
								  /
								 /
								/
							   /
							  /
							 /
							/
						   /
						  /
						 /
						/
					   /
					  /
					 /
					/
				   /
				  /
				 /
				/
			   /
			  /
			 /
			/
		   /
		  /
		 /
		/
	   /
	  /
	 /
	/
   /
  /
 /
/
"
