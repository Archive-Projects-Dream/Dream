/turf/closed/wall/simple
	icon = '_horizon/icons/turf/walls/simple_wall/wall.dmi'
	icon_state = "wall0"
	// F4CK SMOTHING-SYSTEM
	smoothing_flags = NONE
	smoothing_groups = NONE
	canSmoothWith = NONE
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
