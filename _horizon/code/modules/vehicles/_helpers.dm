/*
 * Small helpers shared by the multitile vehicle system, ported from cmss13
 * (floor, get_random_turf_in_range) and kept here because Horizon-Dream does
 * not define them.
 */

/// Rounds down to the nearest integer, like cmss13's floor().
/proc/floor(x)
	return round(x)

/// Picks a random turf within dist_max of the center turf, at least dist_min away.
/proc/get_random_turf_in_range(atom/center, dist_max, dist_min = 0)
	if(!center)
		return null
	var/list/valid_turfs = list()
	var/turf/center_turf = get_turf(center)
	for(var/turf/nearby_turf in RANGE_TURFS(dist_max, center_turf))
		if(dist_min && get_dist(center_turf, nearby_turf) < dist_min)
			continue
		valid_turfs += nearby_turf
	if(!length(valid_turfs))
		return null
	return pick(valid_turfs)

/*
 * Resolves which multitile vehicle a mob is crewing, if any.
 * Replaces cmss13's mob.interactee lookups: in Horizon-Dream the crew sits in
 * crew seats (chairs) inside the interior, so the vehicle is reached through
 * the seat the mob is buckled to. Passenger seats don't grant control.
 */
/mob/proc/get_multitile_vehicle()
	var/obj/structure/chair/comfy/vehicle/crew_seat = buckled
	if(istype(crew_seat))
		return crew_seat.vehicle
	return null
