// horizon-dev-sync[bot] port
// Variables missing from upstream /tg/station codebase but referenced by
// horizon's _firing.dm (which reads ranged_hit_zone_modifier from a bodypart
// to compute hit-zone diceroll modifiers).

/obj/item/bodypart
	/// Accuracy modifier for ranged combat when this bodypart is targeted.
	/// Read by horizon's _firing.dm ready_proj().
	var/ranged_hit_zone_modifier = 0
