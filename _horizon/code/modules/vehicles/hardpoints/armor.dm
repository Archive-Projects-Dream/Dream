/*
 * Armor hardpoints, ported from cmss13
 * code/modules/vehicles/hardpoints/armor/.dm
 *
 * The snowplow's snow-layer clearing is adapted to leave generic debris;
 * TG turfs don't track cmss13-style snow bleed layers.
 */

/obj/item/hardpoint/armor
	name = "armor hardpoint"
	desc = "Primary armor source."
	slot = HDPT_ARMOR
	hdpt_layer = HDPT_LAYER_ARMOR
	damage_multiplier = 0.5
	max_integrity = 1000
/obj/item/hardpoint/armor/ballistic
	name = "\improper Ballistic Armor"
	desc = "Protects the vehicle from high-penetration weapons."
	icon_state = "ballistic_armor"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "ballistic_armor"
	type_multipliers = list(
		"bullet" = 0.67,
		"slash" = 0.67,
		"all" = 0.9
	)
/obj/item/hardpoint/armor/caustic
	name = "\improper Caustic Armor"
	desc = "Protects vehicles from most types of acid."
	icon_state = "caustic_armor"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "caustic_armor"
	type_multipliers = list(
		"acid" = 0.67,
		"all" = 0.9
	)
/obj/item/hardpoint/armor/concussive
	name = "\improper Concussive Armor"
	desc = "Protects the vehicle from high-impact weapons."
	icon_state = "concussive_armor"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "concussive_armor"
	type_multipliers = list(
		"blunt" = 0.67,
		"all" = 0.9
	)
/obj/item/hardpoint/armor/paladin
	name = "\improper Paladin Armor"
	desc = "Protects the vehicle from large incoming explosive projectiles."
	icon_state = "paladin_armor"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "paladin_armor"
	type_multipliers = list(
		"explosive" = 0.67,
		"all" = 0.9
	)
/obj/item/hardpoint/armor/snowplow
	name = "\improper Snowplow"
	desc = "Clears a path in the snow for friendlies. It doesn't seem to have much use beyond that."
	icon_state = "snowplow"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "snowplow"
	max_integrity = 150
	activatable = TRUE
/obj/item/hardpoint/armor/snowplow/livingmob_interact(mob/living/bumped_mob)
	var/turf/target_turf = get_step(bumped_mob, owner.dir)
	target_turf = get_step(bumped_mob, owner.dir)
	target_turf = get_step(bumped_mob, owner.dir)
	bumped_mob.throw_at(target_turf, 4, 3, src, TRUE)
	bumped_mob.apply_damage(7 + rand(0, 3), BRUTE)
/obj/item/hardpoint/armor/snowplow/on_move(turf/old_turf, turf/new_turf, move_dir)
	if(atom_integrity <= 0)
		return
	if(dir != move_dir)
		return
	var/turf/ahead = get_step(new_turf, move_dir)
	var/list/turfs_ahead = list(ahead, get_step(ahead, turn(move_dir, 90)), get_step(ahead, turn(move_dir, -90)))
	for(var/turf/open/open_turf in turfs_ahead)
		// Plow away snow layers ahead of the vehicle
		if(istype(open_turf, /turf/open/misc/asteroid/snow) && !open_turf.density)
			open_turf.ScrapeAway(1, CHANGETURF_INHERIT_AIR)
