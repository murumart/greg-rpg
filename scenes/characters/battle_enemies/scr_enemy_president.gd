extends BattleEnemy

const BackgroundType := preload("res://scenes/battle_backgrounds/scr_president_background.gd")

var background: BackgroundType

var progress := 0
var mentioned_electric_resistance := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	if LTS.get_current_scene().name == "Battle":
		background = LTS.get_current_scene().background_container.get_child(0)
		background.enemy_requested.connect(LTS.get_current_scene().request_new_enemy)
		if background.skip_intro:
			return
	var tw := create_tween()
	tw.tween_property(self, "global_position:y", 190.0, 7.0).from(189.0)
	tw.tween_property(self, "global_position:y", 1.0, 14)
	tw.parallel().tween_property(self, "modulate", Color.WHITE, 30
			).from(Color.BLACK)


func hurt(amount: float, h_gender: int) -> void:
	if h_gender == Genders.ELECTRIC and not mentioned_electric_resistance:
		mentioned_electric_resistance = true
		SOL.dialogue("president_resistance")
	amount = _progress_check(amount)
	super(amount, h_gender)


func _progress_check(damage: float) -> float:
	if (character.health - damage) / character.max_health < 0.5 and progress == 0:
		progress = 1
		SOL.dialogue("president_50")
		damage += (character.health - damage) - character.max_health * 0.7
	elif (character.health - damage) / character.max_health < 0.33 and progress == 1:
		progress = 2
		SOL.dialogue("president_33")
		damage += (character.health - damage) - character.max_health * 0.33
		if not is_instance_valid(background):
			return damage
		SOL.dialogue_closed.connect(func():
			teammate_requested.emit(self, "dish")
			background.dish_time(reference_to_team_array.back())
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2(0.2, 0.2), 2.0)
			tw.finished.connect(func():
				died.emit(self)
			)
		, CONNECT_ONE_SHOT)
	return damage
