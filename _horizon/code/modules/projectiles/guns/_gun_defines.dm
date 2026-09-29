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
