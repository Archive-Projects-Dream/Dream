/*
 * Hardpoint ammunition magazines, ported from cmss13
 * code/modules/vehicles/hardpoints/hardpoint_ammo.dm
 *
 * cmss13 magazines reference /datum/ammo types; in Horizon-Dream the
 * projectiles are bound to the hardpoints themselves, so the magazines are
 * simple counter-based containers (current_rounds/max_rounds) that reload
 * the weapon they are loaded into.
 */

/// Counter-based magazine base, mirroring cmss13's /obj/item/ammo_magazine API.
/// Horizon-Dream's native ammo boxes are casing-based, which is a poor fit for
/// vehicle-scale magazines, so the vehicles keep their own simple type.
/obj/item/ammo_magazine
	name = "magazine"
	desc = "A magazine of ammunition."
	icon = '_horizon/icons/vehicles/obj/ammo.dmi'
	icon_state = "ace_autocannon"
	w_class = WEIGHT_CLASS_BULKY
	obj_flags = CONDUCTS_ELECTRICITY
	/// How many rounds are left in the magazine
	var/current_rounds = 0
	/// How many rounds the magazine can hold
	var/max_rounds = 0
/obj/item/ammo_magazine/Initialize(mapload)
	. = ..()
	if(!current_rounds)
		current_rounds = max_rounds
/obj/item/ammo_magazine/examine(mob/user)
	. = ..()
	. += "There [current_rounds == 1 ? "is" : "are"] [current_rounds] round\s left."
//Special ammo magazines for hardpoint modules. Some aren't here since you can use normal magazines on them
/obj/item/ammo_magazine/hardpoint
	name = "hardpoint magazine"
	desc = "A magazine of ammunition for a vehicle hardpoint."
	icon = '_horizon/icons/vehicles/obj/ammo.dmi'
	icon_state = "ace_autocannon"
	w_class = WEIGHT_CLASS_BULKY
	/// Which hardpoint type this magazine fits, purely informational
	var/gun_type
/obj/item/ammo_magazine/hardpoint/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	if(attacking_item.type != type)
		to_chat(user, span_warning("You need another [initial(name)] to be able to transfer ammo."))
		return
	transfer_ammo(attacking_item, user)
/obj/item/ammo_magazine/hardpoint/proc/transfer_ammo(obj/item/ammo_magazine/hardpoint/source_mag, mob/user)
	if(current_rounds == max_rounds)
		to_chat(user, span_warning("[src] is already full."))
		return
	if(source_mag.current_rounds == 0)
		to_chat(user, span_warning("[source_mag] is empty, find a new one."))
		return
	user.visible_message(span_warning("[user] starts refilling [src]."), span_warning("You start refilling [src]."))
	if(!do_after(user, 5 SECONDS, target = src))
		user.visible_message(span_warning("[user] stops refilling [src]."), span_warning("You stop refilling [src]."))
		return
	var/transferred_rounds = min(max_rounds - current_rounds, source_mag.current_rounds)
	source_mag.current_rounds -= transferred_rounds
	current_rounds += transferred_rounds
	source_mag.update_appearance()
	update_appearance()
	user.visible_message(span_warning("[user] finishes refilling [src]."), span_warning("You finish refilling [src]. Ammo count: [current_rounds]."))
/obj/item/ammo_magazine/hardpoint/update_appearance(updates)
	. = ..()
// AC3-E Autocannon magazine
/obj/item/ammo_magazine/hardpoint/ace_autocannon
	name = "AC3-E Autocannon Magazine"
	desc = "A 40 round magazine holding 20mm shells for the AC3-E autocannon."
	icon_state = "ace_autocannon"
	max_rounds = 40
	current_rounds = 40
	gun_type = /obj/item/hardpoint/primary/autocannon
/obj/item/ammo_magazine/hardpoint/ace_autocannon/update_appearance(updates)
	. = ..()
	if(current_rounds > 0)
		icon_state = "ace_autocannon"
	else
		icon_state = "ace_autocannon_empty"
// LTB Cannon magazine
/obj/item/ammo_magazine/hardpoint/ltb_cannon
	name = "LTB Cannon Magazine"
	desc = "A primary armament cannon magazine."
	icon_state = "ltbcannon_4"
	max_rounds = 4
	current_rounds = 4
	gun_type = /obj/item/hardpoint/primary/cannon
/obj/item/ammo_magazine/hardpoint/ltb_cannon/update_appearance(updates)
	. = ..()
	icon_state = "ltbcannon_[current_rounds]"
// LTAA-AP Minigun magazine
/obj/item/ammo_magazine/hardpoint/ltaaap_minigun
	name = "LTAA-AP Minigun Magazine"
	desc = "A magazine of 7.62x51mm AP ammo for a heavy minigun. Filled to the brim with highly precise armor-penetrating rounds."
	icon_state = "ltaa"
	max_rounds = 500
	current_rounds = 500
	gun_type = /obj/item/hardpoint/primary/minigun
// Primary flamer fuel tank
/obj/item/ammo_magazine/hardpoint/primary_flamer
	name = "DRG-N Flamethrower Tank"
	desc = "A tank of highly-combustible napalm for the DRG-N Offensive Flamer Unit."
	icon_state = "flametank_large"
	max_rounds = 100
	current_rounds = 100
	gun_type = /obj/item/hardpoint/primary/flamer
// Boyars Dualcannon magazine
/obj/item/ammo_magazine/hardpoint/boyars_dualcannon
	name = "PARS-159 Dualcannon Magazine"
	desc = "A 90 round magazine holding 20mm shells for the PARS-159 Boyars Dualcannon."
	icon_state = "dual_cannon"
	max_rounds = 90
	current_rounds = 90
	gun_type = /obj/item/hardpoint/primary/dualcannon
// ARC sentry magazine
/obj/item/ammo_magazine/hardpoint/arc_sentry
	name = "RE700 Rotary Cannon Magazine"
	desc = "A 150 round magazine of 12.7mm rounds for the RE700 Rotary Cannon."
	icon_state = "sentry"
	max_rounds = 150
	current_rounds = 150
	gun_type = /obj/item/hardpoint/primary/arc_sentry
// M56 Cupola ammo box
/obj/item/ammo_magazine/hardpoint/m56_cupola
	name = "M56 Cupola Ammo Box"
	desc = "A 700 round ammo box for the M56 Cupola."
	icon_state = "m56_box"
	max_rounds = 700
	current_rounds = 700
	gun_type = /obj/item/hardpoint/secondary/m56cupola
// Frontal cannon uses cupola-compatible boxes
/obj/item/ammo_magazine/hardpoint/m56_cupola/frontal_cannon
	name = "RE-RE700 Frontal Cannon Ammo Box"
	desc = "A 700 round ammo box for the RE-RE700 Frontal Cannon."
	gun_type = /obj/item/hardpoint/secondary/frontalcannon
// Secondary flamer fuel tank
/obj/item/ammo_magazine/hardpoint/secondary_flamer
	name = "LZR-N Flamethrower Tank"
	desc = "A tank of napalm fuel for the LZR-N Flamer Unit."
	icon_state = "flametank_small"
	max_rounds = 60
	current_rounds = 60
	gun_type = /obj/item/hardpoint/secondary/small_flamer
// Grenade launcher magazine
/obj/item/ammo_magazine/hardpoint/tank_glauncher
	name = "M92T Grenade Launcher Magazine"
	desc = "A magazine of 18 M40 grenades for the M92T Grenade Launcher."
	icon_state = "glauncher"
	max_rounds = 18
	current_rounds = 18
	gun_type = /obj/item/hardpoint/secondary/grenade_launcher
// TOW launcher magazine
/obj/item/ammo_magazine/hardpoint/towlauncher
	name = "TOW Launcher Magazine"
	desc = "A magazine of 6 TOW missiles."
	icon_state = "tow"
	max_rounds = 6
	current_rounds = 6
	gun_type = /obj/item/hardpoint/secondary/towlauncher
// Flare launcher magazine
/obj/item/ammo_magazine/hardpoint/flare_launcher
	name = "M-87F Flare Launcher Magazine"
	desc = "A magazine of 30 flares."
	icon_state = "flare"
	max_rounds = 30
	current_rounds = 30
	gun_type = /obj/item/hardpoint/support/flare_launcher
// Turret smoke screen charges
/obj/item/ammo_magazine/hardpoint/turret_smoke
	name = "M34A2-A Turret Smoke Screen Charges"
	desc = "A box of smoke screen charges for the M34A2-A Multipurpose Turret."
	icon_state = "smoke"
	max_rounds = 10
	current_rounds = 10
	gun_type = /obj/item/hardpoint/holder/tank_turret
// Firing port weapon ammo (auto-reloads, but can be swapped)
/obj/item/ammo_magazine/hardpoint/firing_port_weapon
	name = "M56 FPW Magazine"
	desc = "A 700 round magazine for the M56 Firing Port Weapon."
	icon_state = "m56_box"
	max_rounds = 700
	current_rounds = 700
	gun_type = /obj/item/hardpoint/special/firing_port_weapon
