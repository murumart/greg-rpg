class_name GateIdMatchesPredicate extends Predicate

enum PresetGateIds {
	NONE,
	GATE_LOADING,
	GATE_ENTER_BATTLE,
	GATE_EXIT_BATTLE,
	GATE_EXIT_BIKING,
	GATE_EXIT_FISHING,
	GATE_BIKE_TRAVEL,
	GATE_EXIT_CUTSCENE,
	GATE_EXIT_GAMING,
}

@export var gate_id_preset: PresetGateIds = PresetGateIds.NONE
@export var gate_id_string: StringName


func _internal_check() -> String:
	if gate_id_preset != PresetGateIds.NONE:
		match gate_id_preset:
			PresetGateIds.GATE_LOADING: gate_id_string = LTS.GATE_LOADING
			PresetGateIds.GATE_ENTER_BATTLE: gate_id_string = LTS.GATE_ENTER_BATTLE
			PresetGateIds.GATE_EXIT_BATTLE: gate_id_string = LTS.GATE_EXIT_BATTLE
			PresetGateIds.GATE_EXIT_BIKING: gate_id_string = LTS.GATE_EXIT_BIKING
			PresetGateIds.GATE_EXIT_FISHING: gate_id_string = LTS.GATE_EXIT_FISHING
			PresetGateIds.GATE_BIKE_TRAVEL: gate_id_string = LTS.GATE_BIKE_TRAVEL
			PresetGateIds.GATE_EXIT_CUTSCENE: gate_id_string = LTS.GATE_EXIT_CUTSCENE
			PresetGateIds.GATE_EXIT_GAMING: gate_id_string = LTS.GATE_EXIT_GAMING
	if LTS.gate_id != gate_id_string:
		return fail_string
	return SUCCESS
