// horizon-dev-sync[bot] port from Shiptest
// Adds the ammo_counter screen object to the human HUD.

/datum/hud/human/initialize_screen_objects()
	. = ..()
	ammo_counter = new /atom/movable/screen/ammo_counter(null, mymob)
	screen_objects += ammo_counter
