class_name MusBarCounter extends Node

# emits signals when a new bar passes in music based on its bpm and time signature

signal new_bar(bar: int)
signal beat

@export var bpm := 120.0
@export var beats_per_bar := 4.0
var bar := 0
var beat_nr := 0.0
var flbar := 0.0
var flbeat := 0.0


func _process(delta: float) -> void:
	flbar += delta / (60 * beats_per_bar / bpm)
	flbeat += delta / (60 / bpm)
	if flbeat >= beat_nr + 1:
		beat_nr += 1
		beat.emit()
	if flbar >= bar + 1:
		bar += 1
		new_bar.emit(bar)

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
