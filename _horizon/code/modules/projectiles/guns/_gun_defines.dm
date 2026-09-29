// horizon-dev-sync[bot] port
// Variables missing from upstream /tg/station codebase but referenced by
// horizon's _gun.dm.

/obj/item/gun
	/// Reference to the autofire component, if any. Used by safety toggle
	/// code to refresh mouse pointer / update action buttons.
	/// Set automatically by AddComponent(/datum/component/automatic_fire).
	var/datum/component/automatic_fire/autofire_component

	/// Semi-auto cooldown flag. Legacy var read by horizon's on_autofire_start()
	/// and do_autofire() to bail out early.
	var/semicd = FALSE

// Legacy: fire selector position. 1 = semi, 2 = burst, 3 = full auto.
// Defined here (loaded before _automatic.dm) so `select = 3` in
// _automatic.dm doesn't trigger a "var_before_def" warning.
/obj/item/gun/ballistic/automatic
	var/select = 1
