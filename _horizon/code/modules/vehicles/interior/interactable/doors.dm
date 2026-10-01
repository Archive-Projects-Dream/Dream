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
	name = "tank hatch"
	icon = '_horizon/icons/vehicles/obj/interiors/tank.dmi'
	icon_state = "hatch"

// MARK: Van
/obj/structure/interior_exit/vehicle/van
	icon = '_horizon/icons/vehicles/obj/interiors/van.dmi'

/obj/structure/interior_exit/vehicle/van/left
	name = "Van left door"
	icon_state = "interior_door"

/obj/structure/interior_exit/vehicle/van/right
	name = "Van right door"
	icon_state = "exterior_door_unique"
	dir = SOUTH

/obj/structure/interior_exit/vehicle/van/backleft
	name = "Van back exit"
	icon_state = "back_2"
	dir = WEST

/obj/structure/interior_exit/vehicle/van/backright
	name = "Van back exit"
	icon_state = "back_1"
	dir = WEST

// MARK: Clf Van
/obj/structure/interior_exit/vehicle/clf_van
	icon = '_horizon/icons/vehicles/obj/interiors/clf_van.dmi'

/obj/structure/interior_exit/vehicle/clf_van/left
	name = "Technical left door"
	icon_state = "interior_door"

/obj/structure/interior_exit/vehicle/clf_van/right
	name = "Technical right door"
	icon_state = "exterior_door_unique"
	dir = SOUTH

/obj/structure/interior_exit/vehicle/clf_van/backleft
	name = "Technical back exit"
	icon_state = "back_2"
	dir = WEST

/obj/structure/interior_exit/vehicle/clf_van/backright
	name = "Technical back exit"
	icon_state = "back_1"
	dir = WEST

// MARK: Box Van
/obj/structure/interior_exit/vehicle/box_van
	icon = '_horizon/icons/vehicles/obj/interiors/box_van_interior.dmi'

/obj/structure/interior_exit/vehicle/box_van/left
	name = "Van left door"
	icon_state = "interior_door"

/obj/structure/interior_exit/vehicle/box_van/right
	name = "Van right door"
	icon_state = "exterior_door_unique"
	dir = SOUTH

/obj/structure/interior_exit/vehicle/box_van/backleft
	name = "Van back exit"
	icon_state = "back_2"
	dir = WEST

/obj/structure/interior_exit/vehicle/box_van/backright
	name = "Van back exit"
	icon_state = "back_1"
	dir = WEST

// MARK: Pizza Van
/obj/structure/interior_exit/vehicle/pizza_van
	icon = '_horizon/icons/vehicles/obj/interiors/pizza_van_interior.dmi'

/obj/structure/interior_exit/vehicle/pizza_van/left
	name = "Van left door"
	icon_state = "interior_door"

/obj/structure/interior_exit/vehicle/pizza_van/right
	name = "Van right door"
	icon_state = "exterior_door_unique"
	dir = SOUTH

/obj/structure/interior_exit/vehicle/pizza_van/backleft
	name = "Van back exit"
	icon_state = "back_2"
	dir = WEST

/obj/structure/interior_exit/vehicle/pizza_van/backright
	name = "Van back exit"
	icon_state = "back_1"
	dir = WEST

// MARK: APC interior
/obj/structure/interior_exit/vehicle/apc
	name = "APC side door"
	icon = '_horizon/icons/vehicles/obj/interiors/apc.dmi'
	icon_state = "exit_door"

/obj/structure/interior_exit/vehicle/apc/rear
	name = "APC rear hatch"
	icon_state = "door_rear_center"

/obj/structure/interior_exit/vehicle/apc/rear/left
	icon_state = "door_rear_left"

/obj/structure/interior_exit/vehicle/apc/rear/right
	icon_state = "door_rear_right"

// MARK: APC - PMC
/obj/structure/interior_exit/vehicle/apc_pmc
	name = "APC side door"
	icon = '_horizon/icons/vehicles/obj/interiors/apc_pmc.dmi'
	icon_state = "exit_door"

/obj/structure/interior_exit/vehicle/apc_pmc/rear
	name = "APC rear hatch"
	icon_state = "door_rear_center"

/obj/structure/interior_exit/vehicle/apc_pmc/rear/left
	icon_state = "door_rear_left"

/obj/structure/interior_exit/vehicle/apc_pmc/rear/right
	icon_state = "door_rear_right"

// MARK: ARC
/obj/structure/interior_exit/vehicle/arc
	name = "ARC side door"
	icon = '_horizon/icons/vehicles/obj/interiors/arc.dmi'
	icon_state = "exit_door"
