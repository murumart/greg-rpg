extends RefCounted
class_name SongsList

var songs := {
	"air_conditioning": {
		"title": "air conditioning",
		"link": "res://music/mus_air_conditioning.ogg"
	},
	"ac_scary": {
		"title": "ac_scary",
		"link": "res://music/mus_ac_scary.ogg"
	},
	"arent_you_excited": {
		"title": "aren't you excited?",
		"link": "res://music/mus_arent_you_excited.ogg"
	},
	"bike_spirit": {
		"title": "bike_spirit",
		"link": "res://music/mus_bike_spirit.ogg"
	},
	"birds": {
		"title": "birdsong",
		"link": "res://music/mus_birds.ogg"
	},
	"daylightthief": {
		"title": "daylightthief",
		"link": "res://music/mus_daylightthief.ogg",
	},
	"defeat": {
		"title": "so guys, we died it",
		"link": "res://music/mus_defeat.ogg",
		"loop": false
	},
	"development_hell": {
		"title": "development hell",
		"link": "res://music/mus_development_hell.ogg",
	},
	"dry_summer": {
		"title": "dry summer",
		"link": "res://music/mus_dry_summer.ogg",
	},
	"entirely_just": {
		"title": "entirely just",
		"link": "res://music/mus_entirely_just.ogg",
	},
	"favourable_silence": {
		"title": "favourable silence",
		"link": "res://music/mus_favourable_silence.ogg",
		"default_volume": -5,
	},
	"greenhouse": {
		"title": "webcat - greenhouse",
		"link": "res://music/mus_greenhouse.ogg"
	},
	"greg_battle": {
		"title": "greg battle",
		"link": "res://music/mus_greg_battle.ogg"
	},
	"lily_lesson": {
		"title": "lily lesson",
		"link": "res://music/mus_lily_lesson.ogg"
	},
	"overrun": {
		"title": "overrun",
		"link": "res://music/mus_overrun.ogg"
	},
	"shitty_entrance_of_the_gladiators": {
		"title": "julius fucik - entrance of the gladiators",
		"link": "res://music/mus_entrance_of_the_gladiators.ogg"
	},
	"touch_me": {
		"title": "touch me",
		"link": "res://music/mus_touch_me.ogg"
	},
	"victory": {
		"title": "so guys, we did it",
		"link": "res://music/mus_victory.ogg",
		"loop": false
	}
}


func _init() -> void:
	for i in 7:
		songs["menu_%s" % (i + 1)] = {
			"title": ("radio - menu%s" % (i + 1)),
			"link": "res://music/menu/mus_menu%s.ogg" % (i + 1),
			"loop": false
		}
