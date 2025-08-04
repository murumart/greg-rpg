extends Resource
class_name Character

signal leveled_up
signal message_owner
signal armour_changed(to: StringName)

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
@export var unused_spirits: Array[String] = []
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
		"unused_spirits": unused_spirits,
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
static func xp2lvl(lvl: int) -> int:
	return roundi(Math.LEVEL_UP_CURVE.sample_baked(lvl * 0.01) * lvl)


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
			if name_in_file == &"greg":
				if await limit_levelup():
					return
			experience = 0
			level_up()
	leveled_up.emit()


func limit_levelup() -> bool:
	const required: Dictionary[int, StringName] = {
		40: &"flower_hollyhock",
		50: &"flower_yellow_balsam",
		60: &"flower_nasturtium",
		70: &"flower_rose",
		80: &"flower_meadowsweet",
	}

	if (level + 1 in required and required[level + 1] not in inventory):
		var dlg := DialogueBuilder.new()
		dlg.add_line(dlg.ml("[center]level... not up.[/center]"))
		dlg.add_line(dlg.ml("the %s is still missing. find it." % ResMan.get_item(required[level + 1]).name))
		await dlg.speak_choice()
		return true
	return false


func level_up(by := 1, overflow := false, talk := true) -> void:
	if by < 0:
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
		var sp: String = DAT.get_levelup_spirit(level)
		if not sp.is_empty():
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
		armour_changed.emit(id)
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
	var health_change := pld.get_health_change(health, max_health)
	var magic_change := pld.get_magic_change(magic, max_magic)
	health = clampf(health + health_change, 1.0, max_health)
	magic = clampf(magic + magic_change, 0.0, max_magic)
	if pld.message_user:
		message_owner.emit(pld.message_user)
	if pld is BattlePayloadFishing and name_in_file in DAT.get_data("party", ["greg"]):
		pld.set_fishing_data()


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
	return type in spirits or type in unused_spirits


func _to_string() -> String:
	return "Character " + name + "(l%sa%sd%ss%s)" % [level, attack, defense, speed]
