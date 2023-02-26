extends OverworldCharacter

const TWERP_SYNONYMS := [
	"twerp", "twerp", "twerp", "nitwit", "nincompoop", "sucker", "moron", "nullity", "insect"
]
const TUSSLE_SYNONYMS := ["tussle", "tussle", "tussle", "struggle", "scuffle", "brawl", "scramble"]


func _ready() -> void:
	super._ready()
	var enemies : Array[String] = []
	enemies.append("chimney")
	if randf() < 0.25: enemies.append("chimney")
	if randf() < 0.33: enemies.append("well")
	if randf() < 0.33: enemies.append("shopping_cart")
	if randf() < 0.1: enemies.append("shopping_cart")
	if randf() < 0.1: enemies.append("stabbing_fella")
	enemies.shuffle()
	battle_info = BattleInfo.new().set_enemies(enemies).set_music("daylightthief")


func chase(body) -> void:
	super.chase(body)
	SOL.dialogue_box.dial_concat("thug_catch_1", 0, [TWERP_SYNONYMS.pick_random(), TUSSLE_SYNONYMS.pick_random()])
