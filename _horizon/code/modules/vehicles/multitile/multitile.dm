/*
 * Multitile vehicle core, ported from cmss13 code/modules/vehicles/multitile/multitile.dm
 *
 * As a rule of thumb, when defining some sort of coordinates for vehicles,
 * define them as they should be when the vehicle is facing SOUTH (the BYOND default).
 * This applies to for example interior entrances and hardpoint origins.
 *
 * Major adaptations for Horizon-Dream (TG codebase):
 * - frame health uses atom_integrity/max_integrity instead of cmss13's health var
 * - crew seats live in the interior; this object tracks them in the seats list
 * - crew mouse control is implemented with COMSIG_CLIENT_MOUSEDOWN/UP/DRAG
 *   signals registered on seated mobs' clients (no set_interaction in TG)
 * - skills, factions/IFF and minimap markers from cmss13 are not ported
 */

/obj/vehicle/multitile
	name = "multitile vehicle"
	desc = "Get inside to operate the vehicle."
	max_integrity = 1000
	//How big the vehicle is in pixels, defined facing SOUTH, which is the byond default (i.e. a 3x3 vehicle is going to be 96x96)
	bound_width = 32
	bound_height = 32
	//How much to offset the hitbox of the vehicle from the bottom-left source, defined facing SOUTH, which is the byond default (i.e. a 3x3 vehicle should have x/y at -32/-32)
	bound_x = 0
	bound_y = 0
	can_buckle = FALSE
	light_system = COMPLEX_LIGHT
	light_range = 5
	var/atom/movable/vehicle_light_holder/lighting_holder
	var/vehicle_light_range = 5
	var/vehicle_light_power = 2
	//Working cameras in the vehicles
	var/obj/machinery/camera/vehicle/camera = null
	var/obj/machinery/camera/vehicle/camera_int = null
	var/nickname //used for single-use verb to name the vehicle. Put anything here to prevent naming
	var/honk_sound = '_horizon/sounds/vehicles/honk_4_light.ogg'
	var/next_honk = 0 //to prevent spamming
	// Movement delay per tile, in deciseconds. Overridden by locomotion hardpoints.
	var/move_delay = VEHICLE_SPEED_STATIC
	// The next world.time when the vehicle can move
	var/next_move = 0
	// How much momentum the vehicle has. Increases by 1 each move
	var/move_momentum = 0
	// How much momentum the vehicle can achieve
	var/move_max_momentum = 5
	// How much momentum is lost when turning/rotating the vehicle
	var/move_turn_momentum_loss_factor = 0.5
	// Determines how much slower the vehicle is when it lacks its full momentum
	// When the vehicle has 0 momentum, its movement delay will be move_delay * momentum_build_factor
	// The movement delay gradually reduces up to move_delay when momentum increases
	var/move_momentum_build_factor = 1.3
	//Sound to play when moving
	var/movement_sound
	//Cooldown for next sound to play
	var/move_next_sound_play = 0
	//whether MP vehicle clamps are applied
	var/clamped = FALSE
	// List of all hardpoints attached to the vehicle
	var/list/hardpoints = list()
	//List of all hardpoints you can attach to this vehicle
	var/list/hardpoints_allowed = list()
	// Small mobs (vox armalis-ish, small drones) can't meaningfully damage this vehicle
	var/mob_size_required_to_hit = MOB_SIZE_SMALL
	//variable for various flags
	var/vehicle_flags = VEHICLE_CLASS_WEAK
	// Crew seats tracked as seat id = mob
	var/list/seats = list(
		VEHICLE_DRIVER = null,
	)
	// References to the active/chosen hardpoint for each seat
	var/active_hp = list(
		VEHICLE_DRIVER = null
	)
	// Map file name of the vehicle interior
	var/interior_map = null
	var/datum/interior/interior = null
	//common passenger slots
	var/passengers_slots = 2
	//non-crew mob passenger slots
	var/xenos_slots = 2
	//some vehicles have special slots for dead revivable corpses for various reasons
	//revivable corpses slots
	var/revivable_dead_slots = 0
	//To prevent the dead from taking up all passenger slots and making the vehicle un-enterable.
	var/perma_dead_slots = 2
	//Special roles categories slots. These allow to set specific roles in categories with their own slots.
	//For example, (list(JOB_TITLE) = 2) means that these roles will always have 2 slots reserved for them.
	//Only first encounter of job will be checked for slots, so don't put job in more than one category.
	var/list/role_reserved_slots = list()
	//list of stuff we do NOT want to be pulled inside
	var/list/forbidden_atoms = list(
		/obj/structure/door_assembly,
		/obj/structure/barricade,
		/obj/structure/window,
		/obj/structure/windoor_assembly,
	)
	var/wall_ram_damage = 30
	//allows more flexibility in ram damage
	var/vehicle_ram_multiplier = 1
	//Amount of seconds spent on entering/leaving. Always the same when dragging stuff (2 seconds)
	var/entrance_speed = 1 SECONDS
	//Whether or not entering the vehicle is ID restricted. Toggleable by the driver.
	var/door_locked = FALSE
	req_one_access = list(
		ACCESS_COMMAND,
		// You can't hide from the cops
		ACCESS_BRIG,
	)
	//All the connected entrances sorted by tag
	//Exits will be loaded by the interior manager and sorted by tag to match
	var/list/entrances = list()
	var/list/misc_multipliers = list(
		"move" = 1.0,
		"accuracy" = 1.0,
		"cooldown" = 1.0,
	)
	//Changes how much damage the vehicle takes
	var/list/dmg_multipliers = list(
		"all" = 1.0, //for when you want to make it invincible
		"acid" = 1.0,
		"slash" = 1.0,
		"bullet" = 1.0,
		"explosive" = 1.0,
		"blunt" = 1.0,
		"abstract" = 1.0) //abstract for when you just want to hurt it
	// This is more important than you think.
	// Explosive waves can propagate through the vehicle and hit it multiple times
	// Plain assignment: /atom already declares explosive_resistance in TG
	explosive_resistance = 200
	//Placeholders
	icon = '_horizon/icons/vehicles/obj/van.dmi'
	icon_state = "van_base"
	var/move_on_turn = FALSE
	/// Direction of the last successful move, used for ram/knockback logic
	var/last_move_dir = SOUTH
	/// world.time of the last move, cmss13 compatibility
	var/l_move_time = 0
/obj/vehicle/multitile/Initialize(mapload)
	. = ..()
	var/angle_to_turn = turning_angle(SOUTH, dir)
	rotate_entrances(angle_to_turn)
	rotate_bounds(angle_to_turn)
	if(bound_width > world.icon_size || bound_height > world.icon_size)
		lighting_holder = new(src)
		lighting_holder.set_light_range(vehicle_light_range)
		lighting_holder.set_light_power(vehicle_light_power)
		lighting_holder.set_light_on(vehicle_light_range || vehicle_light_power)
	else if(light_range)
		set_light_on(TRUE)
	healthcheck()
	update_appearance()
	GLOB.all_multi_vehicles += src
	return INITIALIZE_HINT_LATELOAD
/obj/vehicle/multitile/LateInitialize()
	. = ..()
	if(interior_map)
		interior = new(src)
		INVOKE_ASYNC(src, PROC_REF(do_create_interior))
/obj/vehicle/multitile/proc/do_create_interior()
	interior.create_interior(interior_map)
	if(!interior)
		to_chat(world, span_danger("Interior [interior_map] failed to load for [src]! Tell a developer!"))
		qdel(src)
		return
/obj/vehicle/multitile/Destroy()
	if(!QDELETED(interior))
		QDEL_NULL(interior)
	for(var/seat in seats)
		set_seated_mob(seat, null)
	QDEL_LAZYLIST(hardpoints)
	GLOB.all_multi_vehicles -= src
	return ..()
/obj/vehicle/multitile/proc/initialize_cameras()
	return
/obj/vehicle/multitile/proc/toggle_cameras_status(on)
	if(camera)
		camera.toggle_cam_status(on)
	if(camera_int)
		camera_int.toggle_cam_status(on)
// Note: unlike cmss13, Horizon-Dream's explosion subsystem reads the
// atom-level explosive_resistance var directly, so no
// get_explosion_resistance() hook is needed here.
/obj/vehicle/multitile/update_appearance(updates)
	. = ..()
	cut_overlays()
	if(atom_integrity < max_integrity)
		var/image/damage_overlay = image(icon, icon_state = "damaged_frame", layer = layer+0.1)
		damage_overlay.alpha = 255 * (1 - (atom_integrity / max_integrity))
		add_overlay(damage_overlay)
	var/amt_hardpoints = LAZYLEN(hardpoints)
	if(amt_hardpoints)
		for(var/obj/item/hardpoint/hardpoint in hardpoints)
			var/image/hardpoint_image = hardpoint.get_hardpoint_image()
			if(istype(hardpoint_image))
				hardpoint_image.layer = layer + hardpoint.hdpt_layer * 0.1
			else if(islist(hardpoint_image))
				var/list/image/hardpoint_image_list = hardpoint_image // Linter will complain about iterating on "an image" otherwise
				for(var/image/subimage in hardpoint_image_list)
					subimage.layer = layer + hardpoint.hdpt_layer * 0.1
			add_overlay(hardpoint_image)
	if(clamped)
		var/image/clamp_image = image(icon, icon_state = "vehicle_clamp", layer = layer+0.1)
		add_overlay(clamp_image)
//Normal examine() but tells the player what is installed and if it's broken
/obj/vehicle/multitile/examine(mob/user)
	. = ..()
	for(var/obj/item/hardpoint/installed_hardpoint in hardpoints)
		. += "There [installed_hardpoint.p_are()] \a [installed_hardpoint] module[installed_hardpoint.p_s()] installed."
		. += installed_hardpoint.examine(user)
	if(clamped)
		. += "There is a vehicle clamp attached."
/obj/vehicle/multitile/proc/load_hardpoints()
	return
/obj/vehicle/multitile/proc/load_damage()
	return
// Gets the dimensions of the vehicle hitbox, aka the dimensions of the vehicle itself
/obj/vehicle/multitile/proc/get_dimensions()
	return list("width" = (bound_width / world.icon_size), "height" = (bound_height / world.icon_size))
//Returns the ratio of damage to take, just a housekeeping thing
/obj/vehicle/multitile/proc/get_dmg_multi(type)
	if(!dmg_multipliers || !dmg_multipliers.Find(type))
		return 1
	return dmg_multipliers[type] * dmg_multipliers["all"]
//Generic proc for taking damage
//ALWAYS USE THIS WHEN INFLICTING DAMAGE TO THE VEHICLES
/obj/vehicle/multitile/proc/take_damage_type(damage, type, atom/attacker)
	var/all_broken = TRUE
	for(var/obj/item/hardpoint/installed_hardpoint in hardpoints)
		// Health check is done before the hardpoint takes damage
		// This way, the frame won't take damage at the same time hardpoints break
		if(installed_hardpoint.can_take_damage())
			installed_hardpoint.take_damage(floor(damage * get_dmg_multi(type)))
			all_broken = FALSE
	// If all hardpoints are broken, the vehicle frame begins taking full damage
	if(all_broken)
		atom_integrity = max(0, atom_integrity - damage * get_dmg_multi(type))
	else //otherwise, 1/10th of damage lands on the hull
		atom_integrity = max(0, atom_integrity - floor(damage * get_dmg_multi(type) / 10))
	if(ismob(attacker))
		var/mob/attacker_mob = attacker
		log_combat(attacker_mob, src, "damaged", addition = "[damage] [type] damage")
	else
		log_combat(attacker, src, "was damaged by", addition = "[damage] [type] damage")
	update_appearance()
/obj/vehicle/multitile/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	if(istype(arrived, /obj) && !istype(arrived, /obj/item/ammo_magazine/hardpoint) && !istype(arrived, /obj/item/hardpoint))
		arrived.forceMove(loc)
		return
	return ..()
// Add/remove verbs that should be given when a mob sits down or unbuckles here
/obj/vehicle/multitile/proc/add_seated_verbs(mob/living/seated_mob, seat)
	return
/obj/vehicle/multitile/proc/remove_seated_verbs(mob/living/seated_mob, seat)
	return
/obj/vehicle/multitile/proc/set_seated_mob(seat, mob/living/seated_mob)
	// Give/remove verbs
	if(QDELETED(seated_mob))
		var/mob/living/old_mob = seats[seat]
		remove_seated_verbs(old_mob, seat)
	else
		add_seated_verbs(seated_mob, seat)
	seats[seat] = seated_mob
	// Checked here because we want to be able to null the mob in a seat
	if(!istype(seated_mob))
		return FALSE
	register_crew_mouse(seated_mob)
	return TRUE
/// Registers mouse relay signals on the seated mob's client so weapons can be aimed by clicking.
/obj/vehicle/multitile/proc/register_crew_mouse(mob/living/seated_mob)
	if(!seated_mob.client)
		RegisterSignal(seated_mob, COMSIG_MOB_LOGIN, PROC_REF(on_crew_login))
		return
	RegisterSignal(seated_mob.client, COMSIG_CLIENT_MOUSEDOWN, PROC_REF(crew_mousedown))
	RegisterSignal(seated_mob.client, COMSIG_CLIENT_MOUSEUP, PROC_REF(crew_mouseup))
	RegisterSignal(seated_mob.client, COMSIG_CLIENT_MOUSEDRAG, PROC_REF(crew_mousedrag))
/// Unregisters mouse relay signals from a crew mob and its client.
/obj/vehicle/multitile/proc/unregister_crew_mouse(mob/living/seated_mob)
	UnregisterSignal(seated_mob, COMSIG_MOB_LOGIN)
	if(seated_mob.client)
		UnregisterSignal(seated_mob.client, list(COMSIG_CLIENT_MOUSEDOWN, COMSIG_CLIENT_MOUSEUP, COMSIG_CLIENT_MOUSEDRAG))
/// A seated mob logged in mid-seat; hook their new client up.
/// COMSIG_MOB_LOGIN is sent without extra arguments, so pull the client
/// from the source mob itself.
/obj/vehicle/multitile/proc/on_crew_login(mob/living/source)
	SIGNAL_HANDLER
	var/client/new_client = source.client
	if(!new_client)
		return
	RegisterSignal(new_client, COMSIG_CLIENT_MOUSEDOWN, PROC_REF(crew_mousedown))
	RegisterSignal(new_client, COMSIG_CLIENT_MOUSEUP, PROC_REF(crew_mouseup))
	RegisterSignal(new_client, COMSIG_CLIENT_MOUSEDRAG, PROC_REF(crew_mousedrag))
/// Get crewmember of seat.
/obj/vehicle/multitile/proc/get_seat_mob(seat)
	return seats[seat]
/// Get seat of crewmember.
/obj/vehicle/multitile/proc/get_mob_seat(mob/crew_member)
	for(var/seat in seats)
		if(seats[seat] == crew_member)
			return seat
	return null
/// Get active hardpoint of crewmember.
/obj/vehicle/multitile/proc/get_mob_hp(mob/crew_member)
	var/seat = get_mob_seat(crew_member)
	if(seat)
		return active_hp[seat]
	return null
/obj/vehicle/multitile/proc/get_passengers()
	if(interior)
		return interior.get_passengers()
	return null
/obj/vehicle/multitile/proc/load_role_reserved_slots()
	return
//Special armored vic healthcheck that mainly updates the hardpoint states
//proc/ definition: TG's /obj/vehicle has no healthcheck to override
/obj/vehicle/multitile/proc/healthcheck()
	var/all_broken = TRUE //Whether or not to call handle_all_modules_broken()
	for(var/obj/item/hardpoint/installed_hardpoint in hardpoints)
		if(installed_hardpoint.atom_integrity <= 0)
			installed_hardpoint.deactivate()
			installed_hardpoint.remove_buff(src)
		else
			all_broken = FALSE //if something exists but isn't broken
	if(all_broken)
		toggle_cameras_status()
		handle_all_modules_broken()
	//vehicle is dead, no more lights
	if(atom_integrity <= 0 && lighting_holder?.light_range)
		lighting_holder.set_light_on(FALSE)
	else if(lighting_holder && !lighting_holder.light)
		lighting_holder.set_light_on(TRUE)
	update_appearance()
/*
** PRESETS SPAWNERS
*/
//These help spawning vehicles that don't end up as subtypes, causing problems later with various checks
//as well as allowing customizations, like properly turning on mapped in direction and so on.

/obj/effect/vehicle_spawner
	name = "Vehicle Spawner"
//Main proc which handles spawning and adding hardpoints/damaging the vehicle
/obj/effect/vehicle_spawner/proc/spawn_vehicle()
	return
//Installation of modules kit
/obj/effect/vehicle_spawner/proc/load_hardpoints(obj/vehicle/multitile/spawned_vehicle)
	return
//Miscellaneous additions
/obj/effect/vehicle_spawner/proc/load_misc(obj/vehicle/multitile/spawned_vehicle)
	spawned_vehicle.load_role_reserved_slots()
	spawned_vehicle.initialize_cameras()
	//transfer mapped in edits
	if(color)
		spawned_vehicle.color = color
	if(name != initial(name))
		spawned_vehicle.name = name
	if(desc)
		spawned_vehicle.desc = desc
//Dealing enough damage to destroy the vehicle
/obj/effect/vehicle_spawner/proc/load_damage(obj/vehicle/multitile/spawned_vehicle)
	spawned_vehicle.take_damage_type(1e8, "abstract")
	spawned_vehicle.take_damage_type(1e8, "abstract")
	spawned_vehicle.healthcheck()
/obj/effect/vehicle_spawner/proc/handle_direction(obj/vehicle/multitile/spawned_vehicle)
	switch(dir)
		if(EAST)
			spawned_vehicle.try_rotate(90)
		if(WEST)
			spawned_vehicle.try_rotate(-90)
		if(NORTH)
			spawned_vehicle.try_rotate(90)
			spawned_vehicle.try_rotate(90)
/// A movable light source that follows the vehicle around, since multi-tile
/// bounds keep the vehicle's own light anchored to its bottom-left tile.
/atom/movable/vehicle_light_holder
	light_system = COMPLEX_LIGHT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
/atom/movable/vehicle_light_holder/Initialize(mapload, ...)
	. = ..()
	var/atom/attached_to = loc
	forceMove(attached_to.loc)
	RegisterSignal(attached_to, COMSIG_MOVABLE_MOVED, PROC_REF(handle_parent_move))
/atom/movable/vehicle_light_holder/proc/handle_parent_move(atom/movable/mover, atom/oldloc, direction)
	SIGNAL_HANDLER
	forceMove(get_turf(mover))
