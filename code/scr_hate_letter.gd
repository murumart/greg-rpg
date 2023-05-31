class_name HateMail

# this sucks

const ADJECTS := ["beloathed", "hated", "despised", "stupid", "beyond redemption", "abhorred", "execrated", "abominable", "detested", "repulsive", "condemned", "avoided", "cursed", "anathematised", "abominated", "shunned", "unpopular", "undesirable", "loathsome"]

const ADVERBS := ["awfully", "dreadfully", "disgracefully", "wretchedly", "wickedly", "unforgivably", "hatefully", "unpleasantly"]

# https://www.thesaurus.com/browse/hate
const NOUNS := ["hate", "animosity", "antagonism", "dislike", "enmity", "hatred", "horror", "hostility", "loathing", "pain", "rancor", "resentment", "revenge", "venom", "abhorrence", "abomination", "anathema", "animus", "antipathy", "aversion", "bother", "bugbear", "detestation", "disgust", "execration", "frost", "grievance", "gripe", "irritant", "malevolence", "malignity", "nuisance", "objection", "odium", "rankling", "repugnance", "repulsion", "revulsion", "scorn", "spite", "trouble", "black beast", "bete noire", "ill will", "mislike", "nasty look", "no love lost"]

const VERBS := ["hates", "loathes", "despises", "strangles", "abhors", "contemns", "detests", "scorns", "shuns", "abominates", "anathematises", "is disgusted with", "is allergic to", "deprecates", "derides", "is hostile to", "disapproves", "disparages", "disfavours", "spurns", "is repelled by", "has enough of", "has no use for", "looks down on", "objects to", "recoils from", "shudders at", "spits upon", "execrates"]


static func salutation() -> String:
	return (ADJECTS.slice(0, ADJECTS.size() / 2).pick_random() if randf() < 0.5 else ADJECTS.slice(ADJECTS.size() / 2, ADJECTS.size()).pick_random()) +" "+ NOUNS.pick_random()


static func sentence() -> String:
	return "you are my %s %s: my %s %s." % [NOUNS.pick_random(), ADJECTS.pick_random(), ADJECTS.pick_random(), NOUNS.pick_random()] if randf() < 0.5 else "my %s %s %s your %s %s." % [ADJECTS.pick_random(), NOUNS.pick_random(), VERBS.pick_random(), ADJECTS.pick_random(), NOUNS.pick_random()] if randf() > 0.25 else "my %s %s %s %s your %s %s." % [ADJECTS.pick_random(), NOUNS.pick_random(), ADVERBS.pick_random(), VERBS.pick_random(), ADJECTS.pick_random(), NOUNS.pick_random()]


static func letter(sender := "m.d.p") -> String:
	return "%s

%s %s %s

yours %s,
%s" % [salutation(), sentence(), sentence(), sentence(), ADVERBS.pick_random(), sender]

# tl;dr: FUCK YOU!!!!!!!!!!!!
