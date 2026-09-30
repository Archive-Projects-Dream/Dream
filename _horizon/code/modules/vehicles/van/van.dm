/*
 * Vans, ported from cmss13 code/modules/vehicles/van/van.dm, box_van.dm,
 * clf_van.dm, pizza_van.dm and interior.dm
 *
 * The "crawl under the van" mechanic is kept using client-side images; TG's
 * BlockedPassDirs equivalent is CanAllowThrough. Xeno weeds momentum loss is
 * not ported (no weeds in TG); overdrive remains driver-activated.
 */

//Trucks
//Read the documentation in multitile.dm before trying to decipher this stuff

/obj/vehicle/multitile/van
	name = "Colony Van"
	desc = "A rather old hunk of metal with six wheels, you know what to do. Entrance on the back and sides."
	layer = ABOVE_MOB_LAYER

	icon = '_horizon/icons/vehicles/obj/van.dmi'
	icon_state = "van_base"
	pixel_x = -16
	pixel_y = -16

	bound_width = 64
	bound_height = 64

	bound_x = 0
	bound_y = 0

	interior_map = /datum/map_template/interior/van

	entrances = list(
		"left" = list(2, 0),
		"right" = list(-1, 0),
		"back_left" = list(1, 2),
		"back_right" = list(0, 2)
	)

	vehicle_flags = VEHICLE_CLASS_WEAK

	passengers_slots = 8
	xenos_slots = 2

	misc_multipliers = list(
		"move" = 0.5, // fucking annoying how this is the only way to modify speed
		"accuracy" = 1,
		"cooldown" = 1
	)

	movement_sound = '_horizon/sounds/vehicles/tank_driving.ogg'
	honk_sound = '_horizon/sounds/vehicles/honk_2_truck.ogg'

	vehicle_light_range = 8

	move_max_momentum = 3

	hardpoints_allowed = list(
		/obj/item/hardpoint/locomotion/van_wheels,
	)

	move_turn_momentum_loss_factor = 1

	req_access = list()
	req_one_access = list()

	door_locked = FALSE

	mob_size_required_to_hit = MOB_SIZE_SMALL

	var/overdrive_next = 0
	var/overdrive_cooldown = 15 SECONDS
	var/overdrive_duration = 3 SECONDS
	var/overdrive_speed_mult = 0.3 // Additive (30% more speed, adds to 80% more speed)

	move_on_turn = TRUE

	var/list/mobs_under = list()
	var/image/under_image
	var/image/normal_image

	var/next_push = 0
	var/push_delay = 0.5 SECONDS

/obj/vehicle/multitile/van/Initialize(mapload)
	. = ..()
	under_image = image(icon, src, icon_state, layer = BELOW_MOB_LAYER)
	under_image.alpha = 127

	normal_image = image(icon, src, icon_state, layer = layer)

	icon_state = null

	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_LOGGED_IN, PROC_REF(add_default_image))

	for(var/logged_mob in GLOB.player_list)
		add_default_image(SSdcs, logged_mob)

//Mobs can crawl under the van
/obj/vehicle/multitile/van/CanAllowThrough(atom/movable/mover, border_dir)
	if(mover in mobs_under) //can't collide with the thing you're buckled to
		return TRUE

	if(isliving(mover))
		var/mob/living/moving_mob = mover
		if(moving_mob.body_position == LYING_DOWN)
			add_under_van(moving_mob)
			return TRUE

		if(moving_mob.mob_size >= MOB_SIZE_HUGE && next_push < world.time)
			if(try_move(border_dir, force = TRUE))
				next_push = world.time + push_delay
				return TRUE

	return ..()

/*
** PRESETS
*/
/obj/vehicle/multitile/van/pre_movement(direction)
	. = ..(direction)

	for(var/under_mob in mobs_under)
		var/mob/moving_under_mob = under_mob
		if(!(moving_under_mob.loc in locs))
			remove_under_van(moving_under_mob)

/obj/vehicle/multitile/van/proc/add_under_van(mob/living/crawling_mob)
	if(crawling_mob in mobs_under)
		return

	mobs_under += crawling_mob
	RegisterSignal(crawling_mob, COMSIG_QDELETING, PROC_REF(remove_under_van))
	RegisterSignal(crawling_mob, COMSIG_MOB_LOGIN, PROC_REF(add_client))
	RegisterSignal(crawling_mob, COMSIG_MOVABLE_MOVED, PROC_REF(check_under_van))

	if(crawling_mob.client)
		add_client(crawling_mob)

/obj/vehicle/multitile/van/proc/remove_under_van(mob/living/leaving_mob)
	SIGNAL_HANDLER
	mobs_under -= leaving_mob

	if(leaving_mob.client)
		leaving_mob.client.images -= under_image
		add_default_image(SSdcs, leaving_mob)

	UnregisterSignal(leaving_mob, list(
		COMSIG_QDELETING,
		COMSIG_MOB_LOGIN,
		COMSIG_MOVABLE_MOVED,
	))

/obj/vehicle/multitile/van/proc/check_under_van(mob/moving_mob, turf/oldloc, direction)
	SIGNAL_HANDLER
	if(!(moving_mob.loc in locs))
		remove_under_van(moving_mob)

/obj/vehicle/multitile/van/proc/add_client(mob/living/under_mob)
	SIGNAL_HANDLER
	under_mob.client.images += under_image
	under_mob.client.images -= normal_image

/obj/vehicle/multitile/van/proc/add_default_image(subsystem, mob/viewing_mob)
	SIGNAL_HANDLER
	if(viewing_mob?.client)
		viewing_mob.client.images += normal_image

/obj/vehicle/multitile/van/Destroy()
	for(var/under_mob in mobs_under)
		remove_under_van(under_mob)

	for(var/viewing_mob in GLOB.player_list)
		var/mob/player_mob = viewing_mob
		if(player_mob.client)
			player_mob.client.images -= normal_image

	QDEL_NULL(lighting_holder)

	return ..()

/obj/vehicle/multitile/van/attackby(obj/item/attacked_with, mob/user, list/modifiers, list/attack_modifiers)
	if(user.z != z)
		return ..()

	if(attacked_with.tool_behaviour == TOOL_WELDER && atom_integrity >= max_integrity)
		if(!attacked_with.tool_start_check(user, amount = 1))
			to_chat(user, span_warning("You need a lit welder!"))
			return
		var/obj/item/hardpoint/damaged_hardpoint
		for(var/obj/item/hardpoint/potential_hardpoint in hardpoints)
			if(potential_hardpoint.atom_integrity < potential_hardpoint.max_integrity)
				damaged_hardpoint = potential_hardpoint
				break

		if(damaged_hardpoint)
			damaged_hardpoint.handle_repair(attacked_with, user)
			update_appearance()
			return

	. = ..()

// Overdrive activation through SHIFT+click from the driver
/obj/vehicle/multitile/van/crew_mousedown(client/source, atom/object, turf/location, control, params)
	var/list/modifiers = params2list(params)
	if(modifiers[SHIFT_CLICK] && !modifiers[ALT_CLICK])
		var/seat = get_mob_seat(source?.mob)
		if(seat == VEHICLE_DRIVER)
			if(overdrive_next > world.time)
				to_chat(source.mob, span_warning("You can't activate overdrive yet! Wait [round((overdrive_next - world.time) / 10, 0.1)] seconds."))
				return

			misc_multipliers["move"] -= overdrive_speed_mult
			addtimer(CALLBACK(src, PROC_REF(reset_overdrive)), overdrive_duration)

			overdrive_next = world.time + overdrive_cooldown
			to_chat(source.mob, span_notice("You activate overdrive."))
			playsound(src, '_horizon/sounds/vehicles/overdrive_activate.ogg', 75, FALSE)
			return

	. = ..()

/obj/vehicle/multitile/van/proc/reset_overdrive()
	misc_multipliers["move"] += overdrive_speed_mult

// Ported from cmss13's /obj/vehicle/multitile/van/Collide(atom/A).
// The van's light bumper only crushes things while someone is actually
// driving it, and reinforced emplacements (barricades; walls are already
// gated by VEHICLE_CLASS_WEAK in the wall handler) simply block it.
/obj/vehicle/multitile/van/ram_obstacle(atom/obstacle)
	if(!seats[VEHICLE_DRIVER])
		return FALSE

	if(istype(obstacle, /obj/structure/barricade))
		return FALSE

	return ..()

/*
** PRESETS SPAWNERS
*/

/obj/effect/vehicle_spawner/van
	name = "Van Spawner"
	icon = '_horizon/icons/vehicles/obj/van.dmi'
	icon_state = "van_base"
	pixel_x = -16
	pixel_y = -16

/obj/effect/vehicle_spawner/van/Initialize(mapload)
	. = ..()
	spawn_vehicle()
	qdel(src)

//PRESET: no hardpoints
/obj/effect/vehicle_spawner/van/spawn_vehicle()
	var/obj/vehicle/multitile/van/spawned_van = new (loc)

	load_misc(spawned_van)
	handle_direction(spawned_van)
	spawned_van.update_appearance()

//PRESET: wheels installed, destroyed
/obj/effect/vehicle_spawner/van/decrepit/spawn_vehicle()
	var/obj/vehicle/multitile/van/spawned_van = new (loc)

	load_misc(spawned_van)
	load_hardpoints(spawned_van)
	handle_direction(spawned_van)
	load_damage(spawned_van)
	spawned_van.update_appearance()

/obj/effect/vehicle_spawner/van/decrepit/load_hardpoints(obj/vehicle/multitile/van/spawned_van)
	spawned_van.add_hardpoint(new /obj/item/hardpoint/locomotion/van_wheels)

//PRESET: wheels installed
/obj/effect/vehicle_spawner/van/fixed/spawn_vehicle()
	var/obj/vehicle/multitile/van/spawned_van = new (loc)

	load_misc(spawned_van)
	load_hardpoints(spawned_van)
	handle_direction(spawned_van)
	spawned_van.update_appearance()

/obj/effect/vehicle_spawner/van/fixed/load_hardpoints(obj/vehicle/multitile/van/spawned_van)
	spawned_van.add_hardpoint(new /obj/item/hardpoint/locomotion/van_wheels)
