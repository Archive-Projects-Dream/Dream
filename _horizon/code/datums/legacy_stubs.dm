// =============================================================================
// Pollutants (legacy modular_septic pollution system)
// =============================================================================

/datum/pollutant
	/// Display name of this pollutant.
	var/name = "Unknown Pollutant"
	/// Color of the pollutant overlay.
	var/color = "#808080"

/datum/pollutant/incredible_gas
	name = "Incredible Gas"
	color = "#00ff88"

// Turf pollution stub
/turf/proc/pollute_turf(datum/pollutant/pollutant, amount = 1)
	return

// =============================================================================
// Smoke effect system (legacy smoke_spread/bad)
// Upstream renamed /datum/effect_system/smoke_spread to
// /datum/effect_system/fluid_spread/smoke. We alias the legacy path so
// horizon's launcher.dm compiles. Upstream's /datum/effect_system already
// has a start() proc, so we only add set_up() as a stub.
// =============================================================================

/datum/effect_system/smoke_spread
/datum/effect_system/smoke_spread/bad

/datum/effect_system/smoke_spread/proc/set_up(amount = 5, silent = FALSE, turf/location)
	return

// =============================================================================
// Ammo casing stubs for legacy ammo types
// =============================================================================

/// Legacy: batteries ammo casing used by the bolt_acr energy gun.
/// Upstream removed the energy/bolt_acr.dm file; the ammo_casing/batteries
/// type is stubbed here so ammo_stack_types.dm compiles.
/obj/item/ammo_casing/batteries
	name = "battery casing"
	desc = "A standardized energy cell casing."
	icon_state = "s-casing"
	caliber = CALIBER_BATTERY
	projectile_type = /obj/projectile/energy
