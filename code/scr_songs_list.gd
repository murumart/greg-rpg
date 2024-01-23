class_name SongsList extends RefCounted

# list of all music

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
		"title": "bike spirit",
		"link": "res://music/mus_bike_spirit.ogg"
	},
	"birds": {
		"title": "birdsong",
		"link": "res://music/mus_birds.ogg"
	},
	"catfight": {
		"title": "catfight",
		"link": "res://music/mus_catfight.ogg"
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
	"fisher_hut": {
		"title": "radio & murumart - a smoke in the tropical paradise that is a fisherman's hut",
		"link": "res://music/mus_fisher_hut.ogg",
	},
	"fishing_game": {
		"title": "i will dip you in saurce",
		"link": "res://music/mus_fishing_game.ogg",
	},
	"foreign_fauna": {
		"title": "foreign fauna",
		"link": "res://music/mus_animal_fight.ogg",
	},
	"gaming": {
		"title": "gaming",
		"link": "res://music/mus_gaming.ogg"
	},
	"geezer": {
		"title": "quit PISSING ME OFF GEEZER",
		"link": "res://music/mus_geezer.ogg"
	},
	"greenhouse": {
		"title": "webcatz - greenhouse",
		"link": "res://music/mus_greenhouse.ogg"
	},
	"grandma_scary": {
		"title": "mental",
		"link": "res://music/mus_grandma_scary.ogg"
	},
	"greg_battle": {
		"title": "greg battle",
		"link": "res://music/mus_greg_battle.ogg"
	},
	"lakeside": {
		"title": "whale of a time",
		"link": "res://music/mus_lakeside.ogg"
	},
	"lake_battle": {
		"title": "drum and perch",
		"link": "res://music/mus_lake_battle.ogg"
	},
	"lily_lesson": {
		"title": "lily lesson",
		"link": "res://music/mus_lily_lesson.ogg"
	},
	"lion": {
		"title": "lion",
		"link": "res://music/mus_lion.ogg"
	},
	"mail_mission": {
		"title": "mail mission",
		"link": "res://music/mus_mail_mission.ogg"
	},
	"police": {
		"title": "poosetajad",
		"link": "res://music/mus_police.ogg"
	},
	"preturberance": {
		"title": "perturberance",
		"link": "res://music/mus_perturberance.ogg"
	},
	"overrun": {
		"title": "overrun",
		"link": "res://music/mus_overrun.ogg"
	},
	"shitty_entrance_of_the_gladiators": {
		"title": "julius fucik - entrance of the gladiators",
		"link": "res://music/mus_entrance_of_the_gladiators.ogg"
	},
	"snail_mourning": {
		"title": "snail mourning",
		"link": "res://music/mus_snail_mourning.ogg"
	},
	"staredown": {
		"title": "staredown",
		"link": "res://music/mus_staredown.ogg"
	},
	"mail_man": {
		"title": "the friendly postman",
		"link": "res://music/mus_mail_man.ogg"
	},
	"touch_me": {
		"title": "touch me",
		"link": "res://music/mus_touch_me.ogg"
	},
	"vampire_fight": {
		"title": "girl unboxing",
		"link": "res://music/mus_vampire_fight.ogg",
	},
	"victory": {
		"title": "so guys, we did it",
		"link": "res://music/mus_victory.ogg",
		"loop": false
	},
	"warstory": {
		"title": "stood down and greeted us",
		"link": "res://music/mus_warstory.ogg",
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
	var time := Time.get_ticks_msec()
	for k in songs:
		songs[k]["_stream"] = load(songs[k]["link"])
	print("loading songs took ", Time.get_ticks_msec() - time, "ms")
