// horizon-dev-sync[bot] port
// Compatibility shim: legacy modular_septic code uses /obj/item/gun/ballistic/sawoff(),
// but upstream /tg/station renamed it to try_sawoff() and split the actual
// sawing logic into do_sawoff(). This base proc keeps the legacy call sites
// in _ballistic.dm working without rewriting them.

/// Legacy sawoff entrypoint - delegates to upstream's try_sawoff().
/// Returns truthy when the gun was successfully sawn off.
/obj/item/gun/ballistic/proc/sawoff(mob/user, obj/item/saw)
	return try_sawoff(user, saw)
