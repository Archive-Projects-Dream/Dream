// horizon-dev-sync[bot] port from CEV-Eris
// Safety indicator HUD button for guns.
// Shows safety ON/OFF status as a clickable HUD element.
// Adapted from Eris /obj/screen/item_action/top_bar/gun/safety to work
// with upstream /tg/station's /datum/action system.

/// Safety indicator action button.
/// Appears in the player's HUD when holding a gun with a safety system.
/// Positioned just above the drop/throw button (ui_drop_throw area).
/// Clicking it toggles the safety (same as right-click on the gun).
/datum/action/item_action/toggle_safety
	name = "Toggle Safety"
	button_icon = '_horizon/icons/ui/gun_actions.dmi'
	button_icon_state = "safety1"
	default_button_position = "EAST-1:28,SOUTH+1:27"

/datum/action/item_action/toggle_safety/New(Target)
	. = ..()
	update_icon()

/datum/action/item_action/toggle_safety/proc/update_icon()
	if(!target || !istype(target, /obj/item/gun))
		return
	var/obj/item/gun/G = target
	if(G.safety_flags & GUN_SAFETY_ENABLED)
		button_icon_state = "safety1"
	else
		button_icon_state = "safety0"
	build_all_button_icons()

/// When clicked, toggle the gun's safety.
/datum/action/item_action/toggle_safety/Trigger(mob/clicker, trigger_flags)
	// Run upstream's availability + COMSIG_ACTION_TRIGGER checks first.
	if(!..())
		return FALSE
	if(!target || !istype(target, /obj/item/gun))
		return FALSE
	var/obj/item/gun/G = target
	if(!(G.safety_flags & GUN_SAFETY_HAS_SAFETY))
		return FALSE
	G.toggle_safety(clicker)
	update_icon()
	return TRUE
