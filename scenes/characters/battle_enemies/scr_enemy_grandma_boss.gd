extends BattleEnemy

const UNSUITABLE_FOR_BUFFING := ["summon_vacuum", "smallshield"]
const USUAL := preload("res://sprites/characters/battle/grandma/spr_battle.png")
const USE_ITEM := preload("res://sprites/characters/battle/grandma/spr_use_item.png")
const USE_SPIRIT := preload("res://sprites/characters/battle/grandma/spr_use_spirit.png")
const ATTACK := preload("res://sprites/characters/battle/grandma/spr_attack.png")

@export var enemy_health_toughness_curve: Curve

@onready var healing_items := self.character.inventory.filter(func(a):
		return ResMan.get_item(a).use == Item.Uses.HEALING)
@onready var hurting_items := self.character.inventory.filter(func(a):
		return ResMan.get_item(a).use == Item.Uses.HURTING)
@onready var buffing_items := self.character.inventory.filter(func(a):
		return ResMan.get_item(a).use == Item.Uses.BUFFING)
@onready var debuffing_items := self.character.inventory.filter(func(a):
		return ResMan.get_item(a).use == Item.Uses.DEBUFFING)
@onready var magic_replenishing_items := self.character.inventory.filter(func(a):
		var item := ResMan.get_item(a)
		return (item.payload.get_magic_change(
				character.magic, character.max_magic) > 0
				or item.payload.effects.any(func(b):
					return (b as StatusEffect).name == &"inspiration")))

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	super()
	magic_replenishing_items.sort_custom(func(a, b):
		return (ResMan.get_item(a).payload.get_magic_change(character.magic, character.max_magic)
				< ResMan.get_item(b).payload.get_magic_change(
						character.magic, character.max_magic)))
	healing_items.sort_custom(func(a, b):
		return (ResMan.get_item(a).payload.get_health_change(character.health, character.max_health)
				< ResMan.get_item(b).payload.get_health_change(
						character.health, character.max_health))
	)


func ai_action() -> void:
	var target := pick_target()
	print("deb: ", get_debuff_severity(self))
	print("gregdeb: ", get_debuff_severity(target))
	toughness = enemy_health_toughness_curve.sample_baked(
			target.character.health_perc() + get_debuff_severity(self))
	if character.health_perc() <= 1.0 - toughness:
		if health_replenish():
			return
	if target in crittable:
		attack(target)
		return
	if reference_to_team_array.size() < 2:
		if try_use_spirit("summon_vacuum", self):
			return
	if ((not has_status_effect(&"shield") and rng.randf() <= 1.0 - toughness)
			or self in target.crittable):
		if try_use_spirit("smallshield", self):
			return
	if not is_buffed(self) and rng.randf() <= 1.0 - toughness:
		if not buffing_spirits.is_empty() and rng.randf() < 0.67:
			var spirit: String = Math.determ_pick_random(buffing_spirits, rng)
			if not is_unsuitable_for_buffing(spirit, target):
				if try_use_spirit(spirit, self):
					return
		if not buffing_items.is_empty():
			var item: String = Math.determ_pick_random(buffing_items, rng)
			use_item(item, self)
			return
	if (get_debuff_severity(target) < 0.2 * (1.0 - toughness) and rng.randf() < 0.95
			or target.has_status_effect(&"sleepy") and rng.randf() < 0.89):
		if not debuffing_spirits.is_empty() and rng.randf() < 0.78:
			var spirit: String = Math.determ_pick_random(debuffing_spirits, rng)
			if try_use_spirit(spirit, target):
				return
		if not buffing_items.is_empty():
			var item: String = Math.determ_pick_random(debuffing_items, rng)
			use_item(item, target)
			return
	attack(target)


func try_use_spirit(spirit: String, on_whom: BattleActor, replenish_magic := true) -> bool:
	var spirit_instance := ResMan.get_spirit(spirit)
	var enough_magic := spirit_instance.cost <= character.magic
	if not enough_magic:
		if replenish_magic:
			return magic_replenish(spirit_instance.cost)
		return false
	use_spirit(spirit, on_whom)
	return true


func magic_replenish(needed: int) -> bool:
	var found := ""
	for s_item in magic_replenishing_items:
		var item := ResMan.get_item(s_item)
		if (item.payload.get_magic_change(character.magic, character.max_magic)
				+ character.magic >= needed):
			found = s_item
			break
	if not found and (magic_replenishing_items.is_empty() or rng.randf() < 0.25):
		return false
	if not found:
		found = Math.determ_pick_random(magic_replenishing_items, rng)
	use_item(found, self)
	return true


func health_replenish() -> bool:
	if not healing_spirits.is_empty():
		var spirit: String = Math.determ_pick_random(healing_spirits, rng)
		if try_use_spirit(spirit, self, false):
			return true
	var found := ""
	for s_item in healing_items:
		var item := ResMan.get_item(s_item)
		if (item.payload.get_health_change(character.health, character.max_health)
				+ character.health >= character.max_health):
			found = s_item
			break
	if not found and (healing_items.is_empty() or rng.randf() < 0.1):
		return false
	if not found:
		found = healing_items.back()
	use_item(found, self)
	return true


func use_item(item: String, whom: BattleActor) -> void:
	super(item, whom)
	healing_items.erase(item)
	hurting_items.erase(item)
	buffing_items.erase(item)
	debuffing_items.erase(item)
	magic_replenishing_items.erase(item)
	sprite.texture = USE_ITEM
	get_tree().create_timer(0.7).timeout.connect(func(): sprite.texture = USUAL)


func use_spirit(spirit: String, whom: BattleActor) -> void:
	sprite.texture = USE_SPIRIT
	get_tree().create_timer(0.7).timeout.connect(func(): sprite.texture = USUAL)
	super(spirit, whom)


func attack(whom: BattleActor) -> void:
	super(whom)
	sprite.texture = ATTACK
	get_tree().create_timer(0.4).timeout.connect(func(): sprite.texture = USUAL)


func is_debuffed(whom: BattleActor) -> bool:
	return (
		whom.get_attack() < whom.character.attack
		or whom.get_defense() < whom.character.defense
		or whom.get_speed() < whom.character.speed
		or whom.has_status_effect(&"sopping")
	)


func is_buffed(whom: BattleActor) -> bool:
	return (
		whom.get_attack() > whom.character.attack
		or whom.get_defense() > whom.character.defense
		or whom.get_speed() > whom.character.speed
	)


static func get_debuff_severity(whom: BattleActor) -> float:
	var sev := 0.0
	for x in whom.status_effects.values():
		x = x as BattleStatusEffect
		if ((x.type.s_id == &"attack" or x.type.s_id == &"defense" or x.type.s_id == &"speed")
				and x.strength < 1):
			sev -= x.strength * 0.1 - x.duration * 0.03
		if x.type.s_id == &"sopping":
			sev += x.strength * 0.21 + x.duration * 0.08
		if x.type.s_id == &"fire":
			sev += x.strength * 0.1 + x.duration * 0.07
		if x.type.s_id == &"poison":
			sev += x.strength * 0.12 + x.duration * 0.07
		if x.type.s_id == &"little":
			sev += x.strength * 0.1 + x.duration * 0.12
		if x.type.s_id == &"sleepy":
			sev += x.strength * 0.1 + x.duration * 0.3
	return sev * 0.06


func is_unsuitable_for_buffing(spirit: String, enemy: BattleActor) -> bool:
	if enemy.character.armour == "frankling_badge" and spirit == "grandma_electric":
		return false
	return spirit in UNSUITABLE_FOR_BUFFING
