/turf/closed/wall/simple
	icon = '_horizon/icons/turf/walls/simple_wall/wall.dmi'
	icon_state = "wall0"
	// F4CK SMOTHING-SYSTEM
	smoothing_flags = NONE
	smoothing_groups = null
	canSmoothWith = null
	tiles_with = list(/turf/closed/wall/simple)

/turf/closed/wall/simple/Initialize(mapload)
	. = ..()
	relativewall()
	relativewall_neighbours()

/turf/closed/wall/simple/handle_icon_junction(junction)
	icon_state = "wall[junction]"

/turf/closed/wall/simple/wood
	name = "wood"
	icon = '_horizon/icons/turf/walls/simple_wall/wood.dmi'

// MARK: Shadow-atom

/atom/movable/atom_shadow
	name = "shadow"
	icon = '_horizon/icons/obj/solid_wall_mask.dmi'
	icon_state = "wall-0"
	anchored = TRUE
	plane = ATOMS_FOV_SHADOWS_PLANE
	//mouse_opacity = MOUSE_OPACITY_TRANSPARENT // Debug - Вернуть после тестов
	tiles_with = BASED_TILES

/atom/movable/atom_shadow/Initialize(mapload)
	. = ..()
	relativewall()
	relativewall_neighbours()

/atom/movable/atom_shadow/handle_icon_junction(junction)
	icon_state = "wall-[junction]"

/atom/movable/atom_shadow/door
	icon = '_horizon/icons/obj/airlock_mask.dmi'

/atom/movable/atom_shadow/door/handle_icon_junction(junction)
	return

// MARK: WALL
/turf/closed/wall
	plane = WALL_PLANE
	var/atom/movable/atom_shadow/shadow

/turf/closed/wall/Initialize(mapload)
	. = ..()
	shadow = new /atom/movable/atom_shadow(src, src)

/*
/turf/closed/wall/smooth_icon()
	. = ..()
	var/atom/movable/atom_shadow/shadow = locate(/atom/movable/atom_shadow) in src
	shadow?.icon_state = "wall-[smoothing_junction]"
*/

/turf/closed/wall/Destroy()
	shadow?.Destroy()
	return ..()

// MARK: Door Airlock
/obj/machinery/door
	var/atom/movable/atom_shadow/door/shadow

/obj/machinery/door/Initialize(mapload)
	. = ..()
	if(!glass)
		shadow = new(loc)
		shadow.icon_state = icon_state
		shadow.dir = dir

/obj/machinery/door/setDir(newdir)
    . = ..()
    shadow?.dir = newdir

/obj/machinery/door/airlock/update_icon(updates = ALL)
	. = ..()
	if(shadow)
		switch(airlock_state)
			if(AIRLOCK_OPENING)
				shadow.icon_state = "opening"
			if(AIRLOCK_OPEN)
				shadow.icon_state = "open"
			if(AIRLOCK_CLOSING)
				shadow.icon_state = "closing"
			if(AIRLOCK_CLOSED)
				shadow.icon_state = "closed"

/obj/machinery/door/Destroy()
	shadow?.Destroy()
	return ..()

/obj/machinery/door/poddoor/update_icon(updates = ALL)
	. = ..()
	if(shadow)
		shadow.icon_state = density ? "closed" : "open"
