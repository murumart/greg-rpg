extends RefCounted
class_name DialogueList

enum {TEXT, CHARACTER, TEXT_SPEED}

# this could've been json

const dialogues := {
	"test": [
		[
			"hello world!"
		],
		[
			"just kidding. dumbass."
		],
		[
			"you had lots of fun making the engine last time..."
		],
		[
			"but when it came to making the actual gameplay..."
		],
		[
			"you got bored as hell."
		],
		[
			"what makes you think this time will be any different?"
		]
	]
}


static func get_dialogue(key: String) -> Array:
	return dialogues.get(key, []) as Array
