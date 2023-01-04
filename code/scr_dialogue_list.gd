extends RefCounted
class_name DialogueList

enum {TEXT, CHARACTER, TEXT_SPEED}
enum Characters {GREG}

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
	],
	"gregtest": [
		[
			"i think...",
			Characters.GREG
		],
		[
			"i think...",
			Characters.GREG,
			0.5
		],
		[
			"...",
			Characters.GREG,
			0.01
		]
	]
}


static func get_dialogue(key: String) -> Array:
	return dialogues.get(key, []) as Array
