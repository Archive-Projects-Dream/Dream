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

// (The legacy /datum/effect_system/smoke_spread stubs were removed -
// launcher.dm now uses upstream's do_smoke() / fluid_spread smoke directly.)

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
