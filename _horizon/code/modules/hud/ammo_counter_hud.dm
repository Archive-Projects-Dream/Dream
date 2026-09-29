// horizon-dev-sync[bot] port from Shiptest
// Adds the ammo_counter screen object to the human HUD.
// Uses upstream's add_screen_object() so it gets properly added to
// the screen_groups system and shown to the client.

#define HUD_MOB_AMMO_COUNTER "mob_ammo_counter"

/datum/hud/human/initialize_screen_objects()
	. = ..()
	ammo_counter = add_screen_object(/atom/movable/screen/ammo_counter, HUD_MOB_AMMO_COUNTER, HUD_GROUP_INFO)
