// horizon-dev-sync[bot] port
// Variables missing from upstream /tg/station codebase but referenced by
// horizon's _gun.dm. Upstream /tg/station moved flashlight attachable
// handling to /datum/component/seclite_attachable and bayonet handling to
// /datum/component/bayonet_attachable, but horizon's gun subtypes still
// set can_flashlight / can_bayonet vars (now removed) — those subtypes
// have been migrated to use add_seclight_point() / add_bayonet_point()
// overrides instead, matching upstream's pattern.

/obj/item/gun
	/// Reference to the autofire component, if any. Used by safety toggle
	/// code to refresh mouse pointer / update action buttons.
	/// Set automatically by AddComponent(/datum/component/automatic_fire).
	var/datum/component/automatic_fire/autofire_component

	/// Semi-auto cooldown flag. Legacy var read by horizon's on_autofire_start()
	/// and do_autofire() to bail out early. Defined here (not just on
	/// /obj/projectile) because _gun.dm checks it on the gun itself.
	var/semicd = FALSE

// Legacy: recoil buildup when wielded. Read by horizon's rifle.dm.
/obj/item/gun/ballistic
	var/wielded_recoil_buildup = 0

// Legacy: fire selector position. 1 = semi, 2 = burst, 3 = full auto.
// Upstream removed `select` in favour of burst_fire_selection toggle.
// Horizon's _automatic.dm and rifle.dm read/write `select` directly.
/obj/item/gun/ballistic/automatic
	var/select = 1
