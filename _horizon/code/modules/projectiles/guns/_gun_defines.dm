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

	// ~ATTACHMENTS (Shiptest attachment system)
	/// Assoc list of attachment slot -> how many attachments fit in that slot. See ATTACHMENT_DEFAULT_SLOT_AVAILABLE.
	var/list/slot_available = ATTACHMENT_DEFAULT_SLOT_AVAILABLE
	/// Whitelist of attachment types this gun accepts. Defaults to all attachments.
	var/list/valid_attachments = list(/obj/item/attachment)
	/// Assoc list of attachment slot -> list("x" = n, "y" = n) pixel offsets for that slot's overlay.
	var/list/slot_offsets = null
	/// Attachment typepaths this gun spawns with already installed.
	var/list/default_attachments = null
