extends Resource
class_name Character

signal leveled_up
signal message_owner

# resource for storing character data
# this will be interpreted by the battle system and dialogue system

const MAX_SPIRITS := 3

const UPGRADE_MIN := {
	"attack": 1, "defense": 1, "speed": 1, "max_health": 100, "max_magic": 30
}

const UPGRADE_MAX := {
	"attack": 99, "defense": 99, "speed": 99, "max_health": 200, "max_magic": 200
}

@export var name_in_file: StringName = &""

@export_group("Appearance")
@export var name := ""
@export_multiline var info := ""
@export var voice_sound: AudioStream
@export var portrait: Texture

@export_group("Stats")
@export var max_health := 100.0
@export var health := 100.0
@export var max_magic := 30.0
@export var magic := 30.0

@export_range(1, 99) var level := 1
@export var experience := 0: set = set_experience
@export_range(1.0, 99.0) var attack := 1.0
@export_range(1.0, 99.0) var defense := 1.0
@export_range(1.0, 99.0) var speed := 1.0
@export var defeated_characters: Dictionary

@export_group("Items and Spirits")
@export var inventory: Array[String] = []
@export var spirits: Array[String] = []
@export var unused_sprits: Array[String] = []
@export var armour: String = ""
@export var weapon: String = ""


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


# load character changes from save file
# this is used for saving health and such
func load_from_dict(dict: Dictionary) -> void:
	for k in dict.keys():
		var value: Variant = dict[k]
		if value is Array:
			var typarray: Array[String] = []
			typarray.append_array(value)
			value = typarray
		set(k, value)


# base stat + armour + weapon increases for it
func get_stat(nimi: String) -> int:
	var stat := roundi(
			get(nimi)
			+ (ResMan.get_item(armour).payload.get(nimi + "_increase")
			if armour else 0)
			+ (ResMan.get_item(weapon).payload.get(nimi + "_increase")
			if weapon else 0)
	)
	return stat


# actually does not return a percentage. literally unplayable
func health_perc() -> float:
	return health / max_health


# xp to get to the specified level
func xp2lvl(lvl: int) -> int:
	return roundi(Math.LEVEL_UP_CURVE.sample_baked(remap(lvl, 1, 99, 0.0, 1.0)) * lvl)


# currently only greg can functionally gain xp and level up
func add_experience(amount: int, speak := false) -> void:
	SOL.dialogue_box.dial_concat("levelup", 1, ["0", "0"])
	var _old_level := level
	if speak:
		SOL.dialogue_box.dial_concat("get_experience", 0, [amount])
		SOL.dialogue("get_experience")
	for i in amount:
		if level >= 99:
			break
		experience += 1
		if experience >= xp2lvl(level + 1):
			if speak and (
					level + 1 == 50 and not DAT.get_data("vampire_defeated", false)
					or level + 1 == 60 and not DAT.get_data("president_defeated", false)
			):
				SOL.dialogue("levelup_confirmation")
				await SOL.dialogue_closed
				if SOL.dialogue_choice == "no":
					return
			experience = 0
			level_up()
	leveled_up.emit()


func level_up(by := 1, overflow := false, talk := true) -> void:
	if by < 1:
		level -= by
		printerr("reduced level of " + name_in_file)
		return

	var curve := preload("res://resources/res_stat_add_curve.tres")
	var spirits_to_add := []
	for t in by:
		# max level is 99
		if level >= 99 and not overflow: return
		level += 1
		var upgrades := {
			"attack": 0, "defense": 0, "speed": 0, "max_health": 0, "max_magic": 0
		}
		# less chance of gaining a point in a stat as level gets higher
		var upgrade_chance := curve.sample(remap(level, 1, 99, 0.0, 1.0))
		for k in upgrades:

			var perfect_inc: float = (UPGRADE_MAX[k]-UPGRADE_MIN[k])/99.0
			var perfect_stat: float = (
				(UPGRADE_MAX[k]-UPGRADE_MIN[k])/99.0 * level
			) + UPGRADE_MIN[k] - 1

			# except every 11 levels, missed points catch up then
			if level % 11 == 0:
				set(k, roundf(perfect_stat))
			else:
				set(k, roundf(get(k) + (perfect_inc * upgrade_chance)))
			if level == 99:
				set(k, roundf(UPGRADE_MAX[k]))
		# spirits
		if level % 11 == 0:
			var sp: String = DAT.get_levelup_spirit(level)
			if sp.length():
				spirits_to_add.append(sp)

	if talk:
		SOL.dialogue_box.dial_concat("levelup", 1, [name, level])
		SOL.dialogue("levelup")
	for sp in spirits_to_add:
		DAT.grant_spirit(sp, DAT.get_data("party", ["greg"]).find(name_in_file), talk)


func handle_item(id: String) -> void:
	var item = ResMan.get_item(id)
	if item.use == Item.Uses.ARMOUR:
		if armour:
			inventory.append(armour)
		armour = id
		SND.play_sound(load("res://sounds/equip.ogg"))
		DAT.set_data("equipped_item", true)
	elif item.use == Item.Uses.WEAPON:
		if weapon:
			inventory.append(weapon)
		weapon = id
		SND.play_sound(load("res://sounds/equip.ogg"))
		DAT.set_data("equipped_item", true)
	else:
		handle_payload(item.payload)


# no status effects in the overworld for characters
func handle_payload(pld: BattlePayload) -> void:
	var health_change := 0.0
	health_change += pld.health
	health_change += pld.health_percent / 100.0 * health
	health_change += pld.max_health_percent / 100.0 * max_health
	health = minf(health + health_change, max_health)
	magic = minf(magic + pld.magic + (pld.magic_percent / 100.0 * magic) + (pld.max_magic_percent / 100.0 * max_magic), max_magic)
	if pld.meta.get("skateboard", false):
		message_owner.emit(&"skateboard_equipped")
	if pld.meta.get("cellphone", false):
		message_owner.emit(&"cellphone_called")
	if pld.meta.get("map", false):
		message_owner.emit(&"map_viewed")


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


# defeated characters are stored in dictionaries. i give up.
func add_defeated_character(nimi: StringName) -> void:
	defeated_characters[nimi] = defeated_characters.get(nimi, 0) + 1


func add_defeated_characters(them: Dictionary) -> void:
	for a in them.keys():
		defeated_characters[a] = defeated_characters.get(a, 0) + them[a]


# NOTE:
# actors that have any delay between their deadly hurt and actual death
# won't be registred.
func get_defeated_character(nimi: StringName) -> int:
	return defeated_characters.get(nimi, 0)


func has_spirit(type: String) -> bool:
	return type in spirits or type in unused_sprits

