/*
 * Multitile vehicle movement, ported from cmss13 code/modules/vehicles/multitile/multitile_movement.dm
 *
 * Vehicles have momentum, which makes the movement code a bit complex.
 * To avoid race conditions between user inputs and timers for rolling movement,
 * the movement logic is split into 3 parts:
 *
 * - Pre-movement, which determines what movement inputs will be considered
 * - Movement, which executes the movement input chosen by the pre-movement proc
 * - Post-movement, which determines if the movement cycle should automatically be repeated
 */

// Called when someone tries to move the vehicle
/obj/vehicle/multitile/relaymove(mob/user, direction)
	if(user != seats[VEHICLE_DRIVER])
		return
	// Won't even consider moves when the vehicle is broken
	if(atom_integrity <= 0)
		return FALSE
	return pre_movement(direction)
// This determines what type of movement to execute
/obj/vehicle/multitile/proc/pre_movement(direction)
	if(world.time < next_move)
		return FALSE
	var/success = FALSE
	if(dir == turn(direction, 180) || dir == direction)
		var/old_dir = dir
		success = try_move(direction)
		// Keep dir when driving backwards
		setDir(old_dir)
	// Rotation/turning
	else
		success = try_rotate(turning_angle(dir, direction))
		if(move_on_turn)
			try_move(direction)
	return success
// Attempts to execute the given movement input
/obj/vehicle/multitile/proc/try_move(direction, force = FALSE)
	if(!can_move(direction))
		return FALSE
	if(!force)
		var/should_move = update_momentum(direction)
		update_next_move()
		if(!should_move)
			return FALSE
	var/turf/old_turf = get_turf(src)
	forceMove(get_step(src, direction))
	var/turf/current_loc = get_turf(src)
	for(var/obj/item/hardpoint/installed_hardpoint in hardpoints)
		installed_hardpoint.on_move(old_turf, current_loc, direction)
	if(movement_sound && world.time > move_next_sound_play)
		playsound(src, movement_sound, 20, extrarange = 30)
		move_next_sound_play = world.time + 10
	last_move_dir = direction
	if(force && (atom_integrity <= 0)) // Broken and forced movement (currently only big creatures pushing the wreck)
		interior?.drop_human_bodies(old_turf)
	return TRUE
// Rotates the vehicle by deg degrees if possible
/obj/vehicle/multitile/proc/try_rotate(deg)
	if(!can_rotate(deg))
		return FALSE
	move_momentum = move_momentum * move_turn_momentum_loss_factor
	if(abs(move_momentum) < 0.5)
		if(move_momentum < 0)
			move_momentum = -0.5
		else
			move_momentum = 0.5
	update_next_move()
	rotate_hardpoints(deg)
	rotate_entrances(deg)
	rotate_bounds(deg)
	setDir(turn(dir, deg), TRUE)
	last_move_dir = dir
	if(movement_sound && world.time > move_next_sound_play)
		playsound(src, movement_sound, 20, extrarange = 30)
		move_next_sound_play = world.time + 10
	update_appearance()
	return TRUE
/obj/vehicle/multitile/setDir(newdir, real_rotate = FALSE)
	if(!real_rotate)
		return
	. = ..()
// Increases/decreases the vehicle's momentum according to whether or not the user is steppin' on the gas or not
/obj/vehicle/multitile/proc/update_momentum(direction)
	// If we've stood still for long enough we go back to 0 momentum
	if(world.time > next_move + move_delay*move_momentum_build_factor)
		move_momentum = 0
	if(direction == dir)
		move_momentum = min(move_momentum + 1, move_max_momentum)
	else
		move_momentum = max(move_momentum - 1, -move_max_momentum)
	// Attempt to move in the opposite direction to our momentum
	if(direction == dir && move_momentum < 0 || direction != dir && move_momentum > 0)
		// Brakes or something
		move_momentum = 0
		return FALSE
	return TRUE
/obj/vehicle/multitile/proc/update_next_move()
	// 1/((m/M)*b) where m is momentum, M is max momentum and b is the build factor
	var/anti_build_factor = 1/((max(abs(move_momentum), 1)/move_max_momentum) * move_momentum_build_factor)
	next_move = world.time + move_delay * move_momentum_build_factor * anti_build_factor * misc_multipliers["move"]
	l_move_time = world.time
// This just checks if the vehicle can physically move in the given direction
// cmss13 relied on its custom turf/Enter loop calling the mover's Collide();
// Horizon-Dream's turfs don't do that, so the ram handling is done right here.
/obj/vehicle/multitile/proc/can_move(direction)
	var/can_still_move = TRUE
	var/bound_x_tiles = bound_x / world.icon_size
	var/bound_y_tiles = bound_y / world.icon_size
	var/turf/min_turf = locate(x + bound_x_tiles, y + bound_y_tiles, z)
	var/bound_width_tiles = bound_width / world.icon_size
	var/bound_height_tiles = bound_height / world.icon_size
	var/list/old_turfs = CORNER_BLOCK(min_turf, bound_width_tiles, bound_height_tiles)
	var/turf/new_loc = get_step(src, direction)
	min_turf = locate(new_loc.x + bound_x_tiles, new_loc.y + bound_y_tiles, z)
	for(var/turf/target_turf as anything in CORNER_BLOCK(min_turf, bound_width_tiles, bound_height_tiles))
		// only check the turfs we're moving to
		if(target_turf in old_turfs)
			continue

		// The turf itself (walls and friends)
		if(!target_turf.CanPass(src, get_dir(target_turf, src)))
			target_turf.handle_vehicle_bump(src)
			can_still_move = FALSE
			continue

		// Everything standing on the destination turf
		for(var/atom/movable/obstacle as anything in target_turf)
			if(obstacle == src)
				continue
			if(obstacle.Cross(src))
				continue
			// Ram it; TRUE means the obstacle was cleared out of the way
			if(!ram_obstacle(obstacle))
				can_still_move = FALSE

	// Crashed with something that stopped us
	if(!can_still_move)
		move_momentum = floor(move_momentum/2)
		update_next_move()
		interior_crash_effect()
	return can_still_move
/obj/vehicle/multitile/proc/can_rotate(deg)
	if(bound_width == bound_height)
		return TRUE
	//VHCLTODO: Add non-square checks here
	return FALSE
/obj/vehicle/multitile/proc/rotate_entrances(deg)
	entrances = rotate_origins(deg, entrances)
/obj/vehicle/multitile/proc/rotate_hardpoints(deg, update_icons = TRUE, list/specific_hardpoints = null)
	if(specific_hardpoints)
		for(var/obj/item/hardpoint/installed_hardpoint in specific_hardpoints)
			installed_hardpoint.rotate(deg)
		return
	for(var/obj/item/hardpoint/installed_hardpoint in hardpoints)
		installed_hardpoint.rotate(deg)
	if(update_icons)
		update_appearance()
// Rotates a list of relative coordinates around the center of the vehicle
/obj/vehicle/multitile/proc/rotate_origins(deg, list/origins, list/specific_indexes)
	//apply entry coord rotations
	for(var/origin in origins)
		//Don't rotate restricted origin points, unless we're doing a restricted only rotation
		if(specific_indexes)
			var/restricted = TRUE
			for(var/specific_index in specific_indexes)
				if(specific_index == origin)
					restricted = FALSE
					break
			if(restricted)
				continue
		var/origin_coord = origins[origin]
		/*
		   The root of the vehicle isn't always in the true center of the vehicle,
		   so simply rotating around the root doesn't work.
		   Instead, we do a bit of a detour that ultimately makes our life much simpler.
		   The idea is to find the true center of the vehicle, given in coordinates with the lower left
		   corner of the vehicle as the origin. Then we find the coordinates of the origin in the same
		   coordinate system and rotate the origin around the true center.
		*/
		// Note that these coordinates aren't world coordinates.
		// They're coordinates in the coordinate system with the minimum (lower left) corner of the vehicle as its origin
		// Find the root of the vehicle relative to the lower left corner of the vehicle
		var/list/root_coords = list(-bound_x / world.icon_size, -bound_y / world.icon_size)
		// Find the true center of the vehicle relative to the lower left corner of the vehicle
		var/list/center_coords = list(bound_width / (2*world.icon_size), bound_height / (2*world.icon_size))
		// Find the coordinates of the origin relative to the lower left corner of the vehicle
		var/list/origin_coords_abs = list(origin_coord[1] + root_coords[1], origin_coord[2] + root_coords[2])
		// Apply an offset of 0.5 so the origin coordinates are given as the center of the origin tile
		// instead of the lower left vertex of the origin tile. This makes the rotation play nice.
		origin_coords_abs[1] = origin_coords_abs[1] + 0.5
		origin_coords_abs[2] = origin_coords_abs[2] + 0.5
		// Rotate the origin around the center
		var/list/new_origin = RotateAroundAxis(origin_coords_abs, center_coords, deg)
		// And make the origin relative to the root again
		new_origin[1] = round(new_origin[1] - root_coords[1] - 0.5, 1)
		new_origin[2] = round(new_origin[2] - root_coords[2] - 0.5, 1)
		origins[origin] = new_origin
	return origins
/obj/vehicle/multitile/proc/rotate_bounds(deg)
	//If the vehicle isn't a perfect square, rotate the bounds around
	if(bound_width != bound_height && (dir != turn(dir, (deg + 180)) && dir != turn(dir, deg)))
		var/bound_swapped = bound_width
		var/pixel_swapped = bound_x
		bound_width = bound_height
		bound_height = bound_swapped
		bound_x = bound_y
		bound_y = pixel_swapped
/obj/vehicle/multitile/proc/interior_crash_effect()
	if(!interior)
		return
	// Not enough momentum for anything serious
	if(abs(move_momentum) <= 1)
		return
	var/fling_distance = ceil(move_momentum/move_max_momentum) * 2
	var/turf/target = interior.get_middle_turf()
	for(var/unused in 0 to fling_distance-1)
		// NOTE: We fling east/west because all interiors are front-facing east
		target = get_step(target, move_momentum > 0 ? EAST : WEST)
		if(!target)
			break
	var/list/bounds = interior.get_bound_turfs()
	for(var/turf/interior_turf as anything in block(bounds[1], bounds[2]))
		for(var/atom/movable/flung_atom in interior_turf)
			if(flung_atom.anchored)
				continue
			if(isliving(flung_atom))
				var/mob/living/flung_mob = flung_atom
				shake_camera(flung_mob, 2, ceil(move_momentum/move_max_momentum) * 1)
				if(!flung_mob.buckled)
					flung_mob.Knockdown(2 SECONDS)
					flung_mob.Stun(1 SECONDS)
			// YOU'RE LIKE A CAR CRASH IN SLOW MOTION!
			// IT'S LIKE I'M WATCHIN' YA FLY THROUGH A WINDSHIELD!
			INVOKE_ASYNC(flung_atom, TYPE_PROC_REF(/atom/movable, throw_at), target, fling_distance, 3, src, TRUE)
/// Explosions that originate inside the interior (ammunition cooking off and the like)
/obj/vehicle/multitile/proc/at_munition_interior_explosion_effect(devastation = 3, heavy = 5, light = 8)
	if(!interior)
		return
	var/turf/centre = interior.get_middle_turf()
	if(!centre)
		return
	var/turf/target = get_random_turf_in_range(centre, 2, 0)
	if(!target)
		target = centre
	// cmss13 used strength/falloff values here; those map onto
	// devastation/heavy/light ranges in Horizon-Dream's explosion model.
	explosion(target, devastation, heavy, light)