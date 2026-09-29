/obj/item/ammo_casing
	/// If FALSE, the casing will not bounce / play bounce sounds when ejected.
	/// Set FALSE for energy casings, foam darts, etc. that shouldn't clang.
	var/heavy_metal = TRUE

/obj/projectile
	/// If TRUE, the projectile deals no damage. Used by /obj/projectile/blood.
	var/nodamage = FALSE

	/// Semi-auto cooldown flag. Read by horizon's on_autofire_start() and
	/// do_autofire() to bail out early.
	var/semicd = FALSE
