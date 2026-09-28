// horizon-dev-sync[bot] port
// Auto-sync accepted_magazine_type with spawn_magazine_type.
//
// Upstream /tg/station renamed the legacy `mag_type` var to two separate
// vars: `accepted_magazine_type` (what mags the gun accepts) and
// `spawn_magazine_type` (what mag the gun spawns with). The legacy
// modular_septic code only set `mag_type` (which served both purposes).
//
// When the horizon gun code was migrated, `mag_type` was replaced with
// `spawn_magazine_type`, but `accepted_magazine_type` was left at the
// upstream default (/obj/item/ammo_box/magazine/m10mm). This caused:
//   1. CRASH on Initialize: "[gun] spawned with a magazine type that
//      isn't allowed by its accepted_magazine_type!"
//   2. Players couldn't insert magazines into the gun (insert_magazine()
//      checks istype(AM, accepted_magazine_type)).
//
// This override auto-syncs accepted_magazine_type = spawn_magazine_type
// if accepted_magazine_type wasn't explicitly set by the gun subtype.
// We detect "not explicitly set" by checking if it still equals the
// upstream default AND spawn_magazine_type is set to something else.

/obj/item/gun/ballistic/Initialize(mapload)
	// If the gun defines spawn_magazine_type but not accepted_magazine_type
	// (i.e. it still has the upstream default), auto-sync them so the gun
	// actually accepts the magazines it spawns with.
	if(spawn_magazine_type && accepted_magazine_type == initial(accepted_magazine_type))
		accepted_magazine_type = spawn_magazine_type
	return ..()
