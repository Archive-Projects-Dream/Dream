/*
 * Interior exits (doors), ported from cmss13 code/modules/vehicles/interior/interactable/doors.dm
 */

/obj/structure/interior_exit
	name = "interior door"
	desc = "I can get out of here if I go through this."
	icon = 'icons/effects/effects.dmi'
	icon_state = "blank"
	layer = INTERIOR_DOOR_LAYER

	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	anchored = TRUE

	// The interior this exit is tied to
	var/datum/interior/interior = null
	// Which entrance to exit through
	var/entrance_id = null

/obj/structure/interior_exit/attack_hand(mob/M, list/modifiers)

	// Check if dragging anything
	var/atom/dragged_atom = M.pulling

	var/obj/vehicle/multitile/V = interior.exterior
	var/exit_time = V.entrance_speed
	if(dragged_atom)
		exit_time = 2 SECONDS

	to_chat(M, span_notice("You start climbing out of [interior.exterior]."))
	if(!do_after(M, exit_time, target = src))
		to_chat(M, span_warning("Something has interrupted you."))
		return

	//Dragged stuff comes with us only if properly waited 2 seconds. No cheating!
	if(dragged_atom)
		interior.exit(dragged_atom)

	interior.exit(M)

/obj/structure/interior_exit/attack_ghost(mob/dead/observer/user)
	if(!interior)
		return ..()

	var/turf/vehicle_turf = get_turf(interior.exterior)
	if(!vehicle_turf)
		return ..()

	user.forceMove(vehicle_turf)

/obj/structure/interior_exit/vehicle
	name = "vehicle door"

/obj/structure/interior_exit/vehicle/Initialize(mapload)
	. = ..()
	update_appearance()

/obj/structure/interior_exit/vehicle/update_appearance(updates)
	. = ..()
	switch(dir)
		if(NORTH)
			pixel_y = 31
			layer = FLY_LAYER
		if(SOUTH)
			layer = INTERIOR_WALL_SOUTH_LAYER

/obj/structure/interior_exit/vehicle/proc/get_exit_turf()
	var/obj/vehicle/multitile/V = interior.exterior
	var/list/entrance_coords = V.entrances[entrance_id]
	return locate(V.x + entrance_coords[1], V.y + entrance_coords[2], V.z)

/obj/structure/interior_exit/vehicle/attack_hand(mob/M, list/modifiers)

	// Check if dragging anything
	var/atom/dragged_atom = M.pulling

	var/obj/vehicle/multitile/V = interior.exterior
	var/exit_time = V.entrance_speed
	if(dragged_atom)
		exit_time = 2 SECONDS

	to_chat(M, span_notice("You start climbing out of [interior.exterior]."))
	if(!do_after(M, exit_time, target = src))
		to_chat(M, span_warning("Something has interrupted you."))
		return

	var/turf/exit_turf = get_exit_turf()

	//Dragged stuff comes with us only if properly waited 2 seconds. No cheating!
	if(dragged_atom)
		interior.exit(dragged_atom, exit_turf)

	interior.exit(M, exit_turf)

/*
 * Per-vehicle door subtypes used by the interior maps.
 */
/obj/structure/interior_exit/vehicle/tank

/obj/structure/interior_exit/vehicle/van/left
/obj/structure/interior_exit/vehicle/van/right
/obj/structure/interior_exit/vehicle/van/backleft
/obj/structure/interior_exit/vehicle/van/backright

/obj/structure/interior_exit/vehicle/clf_van/left
/obj/structure/interior_exit/vehicle/clf_van/right
/obj/structure/interior_exit/vehicle/clf_van/backleft
/obj/structure/interior_exit/vehicle/clf_van/backright

/obj/structure/interior_exit/vehicle/box_van/left
/obj/structure/interior_exit/vehicle/box_van/right
/obj/structure/interior_exit/vehicle/box_van/backleft
/obj/structure/interior_exit/vehicle/box_van/backright

/obj/structure/interior_exit/vehicle/pizza_van/left
/obj/structure/interior_exit/vehicle/pizza_van/right
/obj/structure/interior_exit/vehicle/pizza_van/backleft
/obj/structure/interior_exit/vehicle/pizza_van/backright

/obj/structure/interior_exit/vehicle/apc
/obj/structure/interior_exit/vehicle/apc/rear
/obj/structure/interior_exit/vehicle/apc/rear/left
/obj/structure/interior_exit/vehicle/apc/rear/right

/obj/structure/interior_exit/vehicle/apc_pmc
/obj/structure/interior_exit/vehicle/apc_pmc/rear
/obj/structure/interior_exit/vehicle/apc_pmc/rear/left
/obj/structure/interior_exit/vehicle/apc_pmc/rear/right

/obj/structure/interior_exit/vehicle/arc
