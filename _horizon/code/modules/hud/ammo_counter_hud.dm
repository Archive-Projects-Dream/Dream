// horizon-dev-sync[bot] port from Shiptest
// Adds the ammo_counter screen object to the human HUD.
// Uses upstream's add_screen_object() so it gets properly added to
// the screen_groups system and shown to the client.
//
// [HORIZON-FIX] initialize_screen_objects() is NOT defined here anymore:
// it was duplicated in code/progress_bar/hud.dm, which compiles after this
// file and silently shadowed this definition - the ammo counter screen was
// never created. The canonical merged definition (swap_hand + progbar +
// ammo_counter) lives in code/progress_bar/hud.dm.

#define HUD_MOB_AMMO_COUNTER "mob_ammo_counter"
