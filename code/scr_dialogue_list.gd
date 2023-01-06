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
			"[color=#00ff00]just kidding. dumbass![/color]"
		],
		[
			"[color=#00ff00]you had lots of fun making the engine last time, remember?[/color]"
		],
		[
			"[color=#00ff00]but when it came to making the actual gameplay...[/color]"
		],
		[
			"[color=#00ff00]you got bored as hell.[/color]"
		],
		[
			"[color=#00ff00]what makes you think this time will be any different?[/color]"
		],
		[
			"[color=#00ff00]at least it will be fun to watch you fail again.[/color]"
		],
	],
	"test2be": [
		[
			"[color=#00ff00]no, i'm not talking to you, greg.[/color]"
		],
		[
			"[color=#00ff00]why would i ever talk to you?[/color]"
		],
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
	],
}


static func get_dialogue(key: String) -> Array:
	assert(key in dialogues)
	return dialogues.get(key, []) as Array
