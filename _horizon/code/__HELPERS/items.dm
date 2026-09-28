// horizon-dev-sync[bot] port
// Helper proc for translating sharpness flags into human-readable text.
// Ported from legacy modular_septic/code/__HELPERS/items.dm.

/proc/translate_sharpness(sharpness = NONE)
	. = list()
	if(sharpness & SHARP_IMPALING)
		. += "impaling"
	if(sharpness & SHARP_POINTY)
		. += "piercing"
	if(sharpness & SHARP_EDGED)
		. += "cutting"
	return english_list(., "blunt")
