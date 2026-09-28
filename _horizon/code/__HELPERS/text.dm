// horizon-dev-sync[bot] port
// Helper procs for flavour text used across horizon mechanics (gun jam
// messages, sharpness readouts, etc.). Ported from legacy
// modular_septic/code/__HELPERS/text.dm because the upstream /tg/station
// codebase no longer ships these helpers.

//Like capitalize, but you capitalize EVERYTHING
/proc/capitalize_like_old_man(t)
	. = t
	if(!length(t))
		return
	var/list/binguslist = splittext(t, " ")
	for(var/bingus in binguslist)
		binguslist -= bingus
		if(!length(bingus))
			binguslist += bingus
			continue
		var/chonker = uppertext(bingus[1])
		bingus = chonker + copytext(bingus, 1 + length(chonker))
		binguslist += bingus
	return jointext(binguslist, " ")

//Sometimes, \an does not work like you'd expect
/proc/prefix_a_or_an(text)
	if(!length(text))
		return "a"
	var/start = lowertext(text[1])
	if(start == "a" || start == "e" || start == "i" || start == "o" || start == "u")
		return "an"
	else
		return "a"

//Get only the initials of t joined together
/proc/get_name_initials(t)
	. = t
	if(!length(t))
		return
	var/list/binguslist = splittext(t, " ")
	for(var/bingus in binguslist)
		binguslist -= bingus
		if(!length(bingus))
			binguslist += bingus
			continue
		binguslist += uppertext(bingus[1])
	return jointext(binguslist, "")

/proc/fail_string(capitalize = FALSE)
	return copytext(capitalize ? capitalize(pick(GLOB.whoopsie)) : pick(GLOB.whoopsie), 1, -1)

/proc/fail_msg(capitalize = FALSE)
	var/msg = pick(GLOB.whoopsie)
	return capitalize ? capitalize(msg) : msg

/proc/random_adjective()
	return pick(GLOB.random_adjectives)

/proc/eww_msg()
	return capitalize(pick(GLOB.eww))

/proc/xbox_rage_msg()
	return capitalize(pick(GLOB.xbox_rage))

/proc/godforsaken_success()
	return capitalize(pick(GLOB.godforsaken_success))

/proc/godforsaken_failure()
	return capitalize(pick(GLOB.godforsaken_failure))

/proc/denominator_first()
	return capitalize(pick(GLOB.denominator_first))

/proc/denominator_last()
	return capitalize(pick(GLOB.denominator_last))

/proc/click_fail_msg()
	return span_alert(pick("I'm not ready!", "No!", "I did all i could!", "I can't!", "Not yet!"))

/proc/get_signs_from_number(num, index = 0)
	var/signs = num
	var/symbol = span_green("<b>+</b>")
	if(!signs)
		symbol = ""
	else if(signs < 0)
		symbol = span_red("<b>-</b>")
	signs = abs(signs)
	var/total_symbols = ""
	if(signs && symbol)
		if(index)
			signs = CEILING(signs/2, 1)
		else
			signs = FLOOR(signs/2, 1)
		var/bingus = 0
		while(bingus < signs)
			bingus++
			total_symbols += symbol
	return total_symbols

/proc/malbolge_string(text)
	var/malbolge = ""
	var/text_len = length(text)
	if(text_len >= 1)
		for(var/i in 1 to length(text))
			var/lowered_text = lowertext(text[i])
			if(!(lowered_text in GLOB.alphabet))
				malbolge += text[i]
			else
				if(lowered_text == text[i])
					malbolge += pick(GLOB.alphabet)
				else
					malbolge += pick(GLOB.alphabet_upper)
	return malbolge

/proc/chat_progress_characters(progressed = 0, total = 10)
	. = ""
	progressed = min(progressed, total)
	for(var/i in 1 to progressed)
		. += "*"
	var/remaining = total-progressed
	for(var/i in 1 to remaining)
		. += "-"

// Lists for the helpers above. Initialized lazily to keep startup cheap.
GLOBAL_LIST_INIT(whoopsie, list(
	"oh no!",
	"uh oh!",
	"yikes!",
	"ouch!",
	"oh dear...",
	"that didn't work!",
	"better luck next time!",
	"cringe!",
))

GLOBAL_LIST_INIT(random_adjectives, list(
	"funky",
	"spooky",
	"blursed",
	"cursed",
	"blessed",
	"stinky",
	"gnarly",
	"radical",
))

GLOBAL_LIST_INIT(eww, list(
	"eww!",
	"ewww!",
	"yuck!",
	"gross!",
	"disgusting!",
))

GLOBAL_LIST_INIT(xbox_rage, list(
	"AAAAA!",
	"FUS RO DAH!",
	"BLARGH!",
	"GRAAAH!",
	"WHY!",
	"NOOO!",
	"BLAGH!",
))

GLOBAL_LIST_INIT(godforsaken_success, list(
	"holy shit!",
	"by the gods!",
	"inconceivable!",
	"impossible!",
	"unbelievable!",
))

GLOBAL_LIST_INIT(godforsaken_failure, list(
	"god damn it!",
	"for fuck's sake!",
	"what a disaster!",
	"this is fine.",
	"are you kidding me?!",
))

GLOBAL_LIST_INIT(denominator_first, list(
	"first",
	"initially",
	"to begin with",
	"once upon a time",
))

GLOBAL_LIST_INIT(denominator_last, list(
	"lastly",
	"finally",
	"in conclusion",
	"and they lived happily ever after",
))
