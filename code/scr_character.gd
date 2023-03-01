extends Resource
class_name Character

signal leveled_up

# this will be interpreted by the battle system and dialogue system

const UPGRADE_MIN := {
	"attack": 1, "defense": 1, "speed": 1, "max_health": 100, "max_magic": 30
}

const UPGRADE_MAX := {
	"attack": 99, "defense": 99, "speed": 99, "max_health": 200, "max_magic": 200
}

@export var name_in_file : StringName = &""

@export_group("Appearance")
@export var name := ""
@export_multiline var info := ""
@export var voice_sound : AudioStream
@export var portrait : Texture

@export_group("Stats")
@export var max_health := 100.0
@export var health := 100.0
@export var max_magic := 30.0
@export var magic := 30.0

@export_range(1, 99) var level := 1
@export var experience := 0 : set = set_experience
@export_range(1.0, 99.0) var attack := 1.0
@export_range(1.0, 99.0) var defense := 1.0
@export_range(1.0, 99.0) var speed := 1.0
@export var defeated_characters : Array[String] = []

@export_group("Items and Spirits")
@export var inventory : Array[String] = []
@export var spirits : Array[String] = []
@export var unused_sprits: Array[String] = []
@export var armour : String = ""
@export var weapon : String = ""


func get_saveable_dict() -> Dictionary:
	return {
		"max_health": max_health,
		"health": health,
		"max_magic": max_magic,
		"magic": magic,
		"level": level,
		"experience": experience,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"defeated_characters": defeated_characters,
		"inventory": inventory,
		"spirits": spirits,
		"unused_sprits": unused_sprits,
		"armour": armour,
		"weapon": weapon,
	}


func load_from_dict(dict: Dictionary) -> void:
	for k in dict.keys():
		var value : Variant = dict[k]
		if value is Array:
			var typarray : Array[String] = []
			typarray.append_array(value)
			value = typarray
		set(k, value)


func get_stat(nimi: String) -> int:
	var stat := roundi(get(nimi) + (DAT.get_item(armour).payload.get("%s_increase" % nimi) if armour else 0) + (DAT.get_item(weapon).payload.get("%s_increase" % nimi) if weapon else 0))
	return stat


func health_perc() -> float:
	return health / max_health


func xp2lvl(lvl: int) -> float:
	var lvlpow := lvl**1.8
	var lvldiv := lvlpow/55.0
	return lvl * 1.3 + lvldiv


func add_experience(amount: int, speak := false) -> void:
	var old_level := level
	if speak:
		SOL.dialogue_box.dial_concat("get_experience", 0, [amount])
		SOL.dialogue("get_experience")
	for i in amount:
		experience = experience + 1
		if experience >= xp2lvl(level):
			experience = 0
			level_up()
			if old_level != level and name_in_file in DAT.A.get("party", ["greg"]):
				var dialogue_key := "levelup"
				if name_in_file == "greg":
					if level % 11 == 0:
						dialogue_key = "levelup_with_spirit"
						DAT.grant_spirit(DAT.get_levelup_spirit(level), 0, false)
						SOL.dialogue_box.dial_concat(dialogue_key, 2, [DAT.get_spirit(DAT.get_levelup_spirit(level)).name])
				SOL.dialogue_box.dial_concat(dialogue_key, 1, [name, level])
				SOL.dialogue(dialogue_key)
	print("emitting levelup")
	leveled_up.emit()


func level_up(by := 1, overflow := false) -> void:
	if by < 1: return
	for t in by:
		if level >= 99 and not overflow: return
		level += 1
		var upgrades := {
			"attack": 0, "defense": 0, "speed": 0, "max_health": 0, "max_magic": 0
		}
		var upgrade_chance := maxf(((99 - pow(level, 2)/167.0)/100.0) - randf()*0.33, 0)
		for k in upgrades:
			
			var perfect_inc : float = (UPGRADE_MAX[k]-UPGRADE_MIN[k])/99.0
			var perfect_stat : float = (
				(UPGRADE_MAX[k]-UPGRADE_MIN[k])/99.0 * level
			) + UPGRADE_MIN[k] - 1
			
			if level % 11 == 0:
				set(k, roundf(perfect_stat))
			else:
				set(k, roundf(get(k) + (perfect_inc * upgrade_chance)))
			if level == 99:
				set(k, roundf(UPGRADE_MAX[k]))


func handle_item(id: String) -> void:
	var item = DAT.get_item(id)
	if item.use == Item.Uses.ARMOUR:
		if armour:
			inventory.append(armour)
		armour = id
		SND.play_sound(load("res://sounds/snd_equip.ogg"))
	elif item.use == Item.Uses.WEAPON:
		if weapon:
			inventory.append(weapon)
		weapon = id
		SND.play_sound(load("res://sounds/snd_equip.ogg"))
	else:
		handle_payload(item.payload)


func handle_payload(pld: BattlePayload) -> void:
	var health_change := 0.0
	health_change += pld.health
	health_change += pld.health_percent / 100.0 * health
	health_change += pld.max_health_percent / 100.0 * max_health
	health = minf(health + health_change, max_health)
	magic = minf(magic + pld.magic + (pld.magic_percent / 100.0 * magic) + (pld.max_magic_percent / 100.0 * max_magic), max_magic)


func fully_heal() -> void:
	health = max_health
	magic = max_magic


func mostly_heal() -> void:
	if health < 0.8 * max_health:
		health = roundf(max_health * 0.8)
	if magic < 0.8 * max_magic:
		magic = roundf(max_magic * 0.8)


func extinguish_duplicate_spirits() -> void:
	for s in spirits.size():
		var srt := spirits[s]
		for y in range(1, spirits.size()):
			var srt2 := spirits[y]
			if srt == srt2: spirits.erase(srt2)


func set_experience(to: int) -> void:
	experience = to


func add_defeated_character(nimi : StringName) -> void:
	var found_in_array := false
	for i in defeated_characters:
		if i.contains(nimi):
			found_in_array = true
			var number = int(i.lstrip(nimi).lstrip(&"_"))
			defeated_characters.erase(i)
			defeated_characters.append(StringName(nimi + &"_" + str(number + 1)))
	if not found_in_array:
		defeated_characters.append(nimi + &"_1")


func get_defeated_character(nimi: StringName) -> int:
	for i in defeated_characters:
		if i.contains(nimi):
			var number := int(i.lstrip(nimi).lstrip(&"_"))
			return number
	return 0


func has_spirit(type: String) -> bool:
	if type in unused_sprits:
		return true
	if type in unused_sprits:
		return true
	return false

