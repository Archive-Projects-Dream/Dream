// [HORIZON-FIX] This is the ONLY /datum/hud/human/initialize_screen_objects
// definition in _horizon. ammo_counter_hud.dm used to define a second one,
// but this file compiles after it and silently shadowed it - so the ammo
// counter screen object was never created and the ammo_hud component
// null-derefed (hud.ammo_counter stayed null). The ammo counter line is
// merged in here.
/datum/hud/human/initialize_screen_objects()
	. = ..()
	add_screen_object(/atom/movable/screen/swap_hand, HUD_MOB_SWAPHAND_2, HUD_GROUP_STATIC, ui_style, ui_swaphand_position(mymob, 2))
	add_screen_object(/atom/movable/screen/progbar_container, HUDKEY_MOB_USE_TIMER, HUD_GROUP_STATIC)
	ammo_counter = add_screen_object(/atom/movable/screen/ammo_counter, HUD_MOB_AMMO_COUNTER, HUD_GROUP_INFO)
