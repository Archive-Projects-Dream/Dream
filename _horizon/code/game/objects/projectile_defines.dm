// horizon-dev-sync[bot] port
// Variables/procs on /obj/projectile and /obj/item/ammo_casing that are
// referenced by horizon mechanics but not present in upstream /tg/station.

/obj/item/ammo_casing
	/// If FALSE, the casing will not bounce / play bounce sounds when ejected.
	/// Set FALSE for energy casings, foam darts, etc. that shouldn't clang.
	var/heavy_metal = TRUE

/obj/projectile
	/// Legacy Angle member (capital A). Upstream uses lowercase `angle`, but
	/// horizon's visual_effect() reads P.Angle to compute particle velocity.
	var/Angle

	/// If TRUE, the projectile deals no damage. Used by /obj/projectile/blood.
	var/nodamage = FALSE

	/// Semi-auto cooldown flag. Read by horizon's on_autofire_start() and
	/// do_autofire() to bail out early.
	var/semicd = FALSE

/// Override of upstream's set_angle() to keep the legacy `Angle` member
/// (capital A) in sync with upstream's lowercase `angle`. Horizon code
/// reads P.Angle to compute particle velocity components.
/obj/projectile/set_angle(new_angle)
	. = ..()
	Angle = angle
