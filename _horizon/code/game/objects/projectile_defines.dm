// horizon-dev-sync[bot] port
// Variables missing from upstream /tg/station codebase but referenced by
// horizon mechanics (projectile organ damage, ammo casing bounce behaviour).
// Ported from legacy code/modules/projectiles/ammunition/_ammunition.dm and
// modular_septic/code/game/objects/obj_defines.dm.

/obj/item/ammo_casing
	/// If FALSE, the casing will not bounce / play bounce sounds when ejected.
	/// Set FALSE for energy casings, foam darts, etc. that shouldn't clang.
	var/heavy_metal = TRUE

/obj/projectile
	/// How good a given projectile is at causing organ damage on carbons.
	/// Higher values equal better shots at creating serious organ damage.
	var/organ_bonus = 0
	/// If this hits a human with no organ armor on the affected body part,
	/// add this to the organ mod. Some attacks may be significantly worse at
	/// organ damage if there's even a slight layer of armor to absorb some
	/// of it vs bare flesh.
	var/bare_organ_bonus = 0
