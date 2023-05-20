extends BattleEnemy


func _ready() -> void:
	super._ready()
	if DAT.cat_names.is_empty():
		DAT.cat_names = DIR.load_cat_names()
	self.actor_name = DAT.cat_names.pick_random()
