// horizon-dev-sync[bot] port
// Minimal attribute / diceroll stubs so horizon projectile code compiles.
// The legacy modular_septic attribute system is not yet ported; the code
// here returns neutral results so gameplay still flows through.
//
// Override these procs on specific subtypes if you want richer behaviour.

/// Lightweight attributes datum - placeholder so user.attributes is non-null.
/datum/attributes
	var/strength = 10
	var/intelligence = 10
	var/dexterity = 10
	var/endurance = 10

/// Lazy accessor for mob.attributes - keeps code paths like
/// `if(istype(user) && user.attributes && ...)` working without changes.
/mob
	var/datum/attributes/attributes

/mob/Initialize(mapload)
	. = ..()
	if(!attributes)
		attributes = new /datum/attributes

/// Returns a diceroll result in [DICE_CRIT_FAILURE .. DICE_CRIT_SUCCESS].
/// Default impl just returns DICE_NEUTRAL so non-attribute mobs behave
/// consistently until the proper system is ported.
/mob/proc/diceroll(modifier = 0, context = DICE_CONTEXT_PHYSICAL)
	return DICE_NEUTRAL

/mob/living/diceroll(modifier = 0, context = DICE_CONTEXT_PHYSICAL)
	if(stat >= DEAD)
		return DICE_FAILURE
	return DICE_NEUTRAL
