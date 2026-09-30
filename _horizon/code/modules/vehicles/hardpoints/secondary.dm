/*
 * Secondary hardpoints (support guns), ported from cmss13
 * code/modules/vehicles/hardpoints/secondary/*.dm
 */

/obj/item/hardpoint/secondary
	name = "secondary hardpoint"
	desc = "Smaller support gun."

	slot = HDPT_SECONDARY

	damage_multiplier = 0.125

	activatable = TRUE

// M56 Cupola
/obj/item/hardpoint/secondary/m56cupola
	name = "\improper M56 Cupola"
	desc = "A secondary weapon for tanks. It's a heavy machine gun that was adjusted to be permanently fixed to its mount. You swear you can still see some weld tacks."

	icon_state = "m56_cupola"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "m56cupola"
	activation_sounds = list('sound/items/weapons/gun/smartgun/smartgun_shoot_1.ogg', 'sound/items/weapons/gun/smartgun/smartgun_shoot_2.ogg', 'sound/items/weapons/gun/smartgun/smartgun_shoot_3.ogg', 'sound/items/weapons/gun/smartgun/smartgun_shoot_1.ogg')

	max_integrity = 350
	firing_arc = 120

	projectile_type = /obj/projectile/bullet/vehicle/cupola

	ammo = new /obj/item/ammo_magazine/hardpoint/m56_cupola
	max_clips = 1

	muzzle_flash_pos = list(
		"1" = list(8, -1),
		"2" = list(-7, -15),
		"4" = list(6, -10),
		"8" = list(-5, 7)
	)

	scatter = 3
	gun_firemode = HARDPOINT_FIREMODE_AUTOMATIC
	gun_firemode_list = list(
		HARDPOINT_FIREMODE_AUTOMATIC,
	)
	fire_delay = 0.3 SECONDS

// LZR-N Flamer Unit
/obj/item/hardpoint/secondary/small_flamer
	name = "\improper LZR-N Flamer Unit"
	desc = "A secondary weapon for tanks that spews hot fire."

	icon_state = "flamer"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "flamer"
	activation_sounds = list('_horizon/sounds/vehicles/weapons/flamethrower.ogg')

	max_integrity = 300
	firing_arc = 120

	projectile_type = /obj/projectile/bullet/vehicle/flame

	ammo = new /obj/item/ammo_magazine/hardpoint/secondary_flamer
	max_clips = 1

	use_muzzle_flash = FALSE

	var/max_range = 7

	px_offsets = list(
		"1" = list(2, 14),
		"2" = list(-2, 3),
		"4" = list(3, 0),
		"8" = list(-3, 18)
	)

	scatter = 6
	fire_delay = 3.0 SECONDS

/obj/item/hardpoint/secondary/small_flamer/try_fire(atom/target_atom, mob/living/user, params)
	if(get_turf(target_atom) in owner.locs)
		to_chat(user, span_warning("The target is too close."))
		return NONE

	return ..()

// Bleihagel RE-RE700 Frontal Cannon
/obj/item/hardpoint/secondary/frontalcannon
	name = "\improper Bleihagel RE-RE700 Frontal Cannon"
	desc = "The marketing department over at Bleihagel would have you believe that the RE-RE700 is an original design. However, experts who pried the cover off the cannon have discovered an object with a striking similarity to the popular M56 Cupola. It is still unknown why the cannon has two barrels."
	icon = '_horizon/icons/vehicles/obj/hardpoints/apc.dmi'

	icon_state = "front_cannon"
	disp_icon = '_horizon/icons/vehicles/obj/apc.dmi'
	disp_icon_state = "frontalcannon"
	activation_sounds = list('sound/items/weapons/gun/smartgun/smartgun_shoot_1.ogg', 'sound/items/weapons/gun/smartgun/smartgun_shoot_2.ogg', 'sound/items/weapons/gun/smartgun/smartgun_shoot_3.ogg')

	damage_multiplier = 0.11

	max_integrity = 350
	firing_arc = 120

	origins = list(0, -1)

	projectile_type = /obj/projectile/bullet/vehicle/cupola

	ammo = new /obj/item/ammo_magazine/hardpoint/m56_cupola/frontal_cannon
	max_clips = 1

	use_muzzle_flash = TRUE
	angle_muzzleflash = FALSE
	muzzleflash_icon_state = "muzzle_flash_double"

	muzzle_flash_pos = list(
		"1" = list(-14, 46),
		"2" = list(15, -76),
		"4" = list(62, -26),
		"8" = list(-62, -26)
	)

	scatter = 4
	gun_firemode = HARDPOINT_FIREMODE_AUTOMATIC
	gun_firemode_list = list(
		HARDPOINT_FIREMODE_AUTOMATIC,
	)
	fire_delay = 0.3 SECONDS

/obj/item/hardpoint/secondary/frontalcannon/pmc
	icon_state = "front_cannon_wy"
	disp_icon_state = "frontalcannon_wy"

// M92T Grenade Launcher
/obj/item/hardpoint/secondary/grenade_launcher
	name = "\improper M92T Grenade Launcher"
	desc = "A magazine fed secondary grenade launcher for tanks that shoots grenades."

	icon_state = "glauncher"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "glauncher"
	activation_sounds = list('sound/items/weapons/gun/general/grenade_launch.ogg')

	max_integrity = 500
	firing_arc = 90

	projectile_type = /obj/projectile/bullet/vehicle/grenade

	ammo = new /obj/item/ammo_magazine/hardpoint/tank_glauncher
	max_clips = 3

	use_muzzle_flash = FALSE

	px_offsets = list(
		"1" = list(0, 17),
		"2" = list(0, 0),
		"4" = list(6, 0),
		"8" = list(-6, 17)
	)

	scatter = 10
	fire_delay = 3.0 SECONDS

/obj/item/hardpoint/secondary/grenade_launcher/try_fire(atom/target_atom, mob/living/user, params)
	if(get_turf(target_atom) in owner.locs)
		to_chat(user, span_warning("The target is too close."))
		return NONE

	return ..()

// TOW Launcher
/obj/item/hardpoint/secondary/towlauncher
	name = "\improper TOW Launcher"
	desc = "A secondary weapon for tanks that shoots rockets. It loads multiple rockets at once."

	icon_state = "tow_launcher"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "towlauncher"

	max_integrity = 500
	firing_arc = 60

	projectile_type = /obj/projectile/bullet/vehicle/tow_missile

	ammo = new /obj/item/ammo_magazine/hardpoint/towlauncher
	max_clips = 1

	px_offsets = list(
		"1" = list(1, 10),
		"2" = list(-1, 5),
		"4" = list(0, 0),
		"8" = list(0, 18)
	)

	muzzle_flash_pos = list(
		"1" = list(8, -1),
		"2" = list(-8, -16),
		"4" = list(5, -8),
		"8" = list(-5, 10)
	)

	scatter = 4
	fire_delay = 15.0 SECONDS
