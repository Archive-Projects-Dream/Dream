/*
 * Interior loading subsystem, ported from cmss13 code/controllers/subsystem/interior.dm
 * Loads vehicle interior map templates into reserved space on reserved z-levels.
 */

#define INTERIOR_BORDER_SIZE 2

SUBSYSTEM_DEF(interior)
	name = "Interiors"
	ss_flags = SS_NO_FIRE|SS_NO_INIT
	var/list/datum/interior/interiors = list()

/// Loads an interior, requires the interior datum
/datum/controller/subsystem/interior/proc/load_interior(datum/interior/interior)
	if(!interior || !istype(interior))
		CRASH("Invalid interior passed to SSinterior.load_interior()")

	var/datum/map_template/interior/template = interior.map_template

	var/height_to_request = template.height + INTERIOR_BORDER_SIZE
	var/width_to_request = template.width + INTERIOR_BORDER_SIZE

	var/datum/turf_reservation/reserved_area = SSmapping.request_turf_block_reservation(width_to_request, height_to_request, reservation_type = /datum/turf_reservation/interior)

	if(!reserved_area)
		log_world("SSinterior: no free reserved space for interior '[template.interior_id]' ([width_to_request]x[height_to_request])")
		return null

	var/turf/bottom_left = reserved_area.bottom_left_turfs[1]

	var/list/bounds = template.load(locate(bottom_left.x + (INTERIOR_BORDER_SIZE / 2), bottom_left.y + (INTERIOR_BORDER_SIZE / 2), bottom_left.z), centered = FALSE)

	if(!bounds)
		log_world("SSinterior: template '[template.interior_id]' failed to load (missing or invalid map file)")
		QDEL_NULL(reserved_area)
		return null

	var/list/turfs = block(bounds[MAP_MINX], bounds[MAP_MINY], bounds[MAP_MINZ], bounds[MAP_MAXX], bounds[MAP_MAXY], bounds[MAP_MAXZ])

	var/list/areas = list()
	for(var/turf/current_turf as anything in turfs)
		areas |= current_turf.loc

	for(var/area/current_area as anything in areas)
		// Interior areas are self-powered, ensure they behave as such
		current_area.power_light = TRUE
		current_area.power_equip = TRUE
		current_area.power_environ = TRUE

	interiors += interior
	return reserved_area

/// Finds which interior is at (x, y, z) and returns its interior datum
/datum/controller/subsystem/interior/proc/get_interior_by_coords(x, y, z)
	for(var/datum/interior/current_interior in interiors)
		var/list/turf/bounds = current_interior.get_bound_turfs()
		if(!bounds)
			continue
		if(z == bounds[1].z && x >= bounds[1].x && x <= bounds[2].x && y >= bounds[1].y && y <= bounds[2].y)
			return current_interior
	return

/// Checks if an atom is in an interior
/datum/controller/subsystem/interior/proc/in_interior(loc)
	if(!loc)
		CRASH("No loc passed to is_in_interior()")
	if(!isturf(loc))
		loc = get_turf(loc)

	var/datum/turf_reservation/interior/reservation = SSmapping.used_turfs[loc]

	if(!istype(reservation))
		return FALSE

	return TRUE

/// See [/datum/controller/subsystem/interior/proc/in_interior]
#define SSINTERIOR_TURF_IN_INTERIOR_FAST(loc) (!!SSmapping.used_turfs[loc])

/// Relays a playsound() call between vehicle interiors and the world around
/// their exterior, mirroring cmss13's sound handling: sounds made near a
/// vehicle are heard by its crew as if they stood next to the vehicle, and
/// sounds made inside an interior are heard outside from the vehicle itself.
/datum/controller/subsystem/interior/proc/relay_vehicle_sound(turf/source_turf, soundin, vol, vary, frequency, falloff_exponent, channel, pressure_affected, sound/sound_to_use, maxdistance, falloff_distance, use_reverb, min_volume, mixer_channel)
	if(!length(interiors))
		return
	// Sound made inside an interior: also audible around the exterior
	var/datum/interior/source_interior = get_interior_by_coords(source_turf.x, source_turf.y, source_turf.z)
	if(source_interior && source_interior.ready && !QDELETED(source_interior.exterior))
		var/turf/exterior_turf = get_turf(source_interior.exterior)
		if(exterior_turf && exterior_turf != source_turf && exterior_turf.z != source_turf.z)
			for(var/mob/listener as anything in get_hearers_in_range(maxdistance, exterior_turf, RECURSIVE_CONTENTS_CLIENT_MOBS, TRUE))
				var/turf/listener_turf = get_turf(listener)
				// mobs inside interiors get their own relay from their vehicle
				if(!listener_turf || in_interior(listener_turf))
					continue
				listener.playsound_local(exterior_turf, soundin, vol, vary, frequency, falloff_exponent, channel, pressure_affected, sound_to_use, maxdistance, falloff_distance, 1, use_reverb, min_volume, mixer_channel)
		return
	// Sound made out in the world: crews of nearby vehicles hear it inside
	for(var/datum/interior/vehicle_interior as anything in interiors)
		if(!vehicle_interior.ready || QDELETED(vehicle_interior.exterior))
			continue
		var/turf/exterior_turf = get_turf(vehicle_interior.exterior)
		if(!exterior_turf || exterior_turf.z != source_turf.z)
			continue
		if(get_dist(exterior_turf, source_turf) > maxdistance)
			continue
		for(var/mob/listener as anything in (vehicle_interior.get_passengers() || list()))
			if(QDELETED(listener) || !listener.client)
				continue
			// cmss13 relocates the listener onto the exterior turf before
			// computing direction and falloff, so the crew hears the outside
			// world as if they were standing next to the vehicle
			listener.playsound_local(source_turf, soundin, vol, vary, frequency, falloff_exponent, channel, pressure_affected, sound_to_use, maxdistance, falloff_distance, 1, use_reverb, min_volume, mixer_channel, exterior_turf)

#undef INTERIOR_BORDER_SIZE
