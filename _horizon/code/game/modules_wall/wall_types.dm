/turf/closed
	/// when walls smooth with one another, the type of junction each wall is.
	var/list/wall_connections = list("0", "0", "0", "0")
	var/special_icon

	/*
	 * blend_turfs - Turfs to blending with
	 * noblend_turfs - Turfs to avoid blending with
	 * blend_objects - Objects which to blend with
	 * noblend_objects - Objects to avoid blending with (such as children of listed blend objects).
	 */
	var/list/blend_turfs = list()
	var/list/noblend_turfs = list()
	var/list/blend_objects = list()
	var/list/noblend_objects = list()

//----- Modulus Walls ---//

/turf/closed/wall/Initialize(mapload, ...)
	. = ..()
	if(!special_icon)
		return
	// Defer updating based on neighbors while we're still loading map
	if(mapload && . != INITIALIZE_HINT_QDEL)
		return INITIALIZE_HINT_LATELOAD
	// Otherwise do it now, but defer icon update to late if it's going to happen
	update_connections(TRUE)
	if(. != INITIALIZE_HINT_LATELOAD)
		update_icon()

/turf/closed/wall/LateInitialize()
	if(!special_icon)
		return
	// By default this assumes being used for map late init
	// We update without cascading changes as each wall will be updated individually
	update_connections(FALSE)
	update_icon()

/turf/closed/wall/setDir(newDir)
	..()
	if(!special_icon)
		return
	update_connections(FALSE)
	update_icon()

/turf/closed/wall/ChangeTurf(newtype, flags, ...)
	. = ..()
	if(.) //successful turf change
		var/turf/T
		for(var/i in GLOB.alldirs)
			T = get_step(src, i)

			if(istype(T, /turf/closed/wall))
				var/turf/closed/wall/neighbour_wall = T
				neighbour_wall.update_connections()
				neighbour_wall.update_icon()

// MARK: Types Wall
/*
/turf/closed/wall/horizon
	name = "debug wall"
	desc = "A debug wall."
	icon = '_horizon/icons/debug_wall.dmi'
	icon_state = "wall"
	special_icon = TRUE
	// F4CK SMOTHING-SYSTEM
	smoothing_flags = NONE
	smoothing_groups = NONE
	canSmoothWith = NONE

	blend_turfs = list(/turf/closed/wall/horizon)
	noblend_turfs = list(/turf/closed/wall/horizon/titan)
*/

/turf/closed/wall/mineral/plastitanium/survival
	icon = '_horizon/icons/turf/walls/modules_wall/survival_pod_walls.dmi'
	icon_state = "wall"
	special_icon = TRUE

/turf/closed/wall/concrete
	icon = '_horizon/icons/turf/walls/modules_wall/concentrate.dmi'
	icon_state = "wall"
	special_icon = TRUE
	// F4CK SMOTHING-SYSTEM
	smoothing_flags = NONE
	smoothing_groups = NONE
	canSmoothWith = NONE

/turf/closed/mineral
	icon_state = "wall"
	special_icon = TRUE
	// F4CK SMOTHING-SYSTEM
	smoothing_flags = NONE
	smoothing_groups = NONE
	canSmoothWith = NONE
	blend_turfs = list(/turf/closed/mineral)

/turf/closed/mineral/Initialize(mapload, ...)
	. = ..()
	if(!special_icon)
		return
	// Defer updating based on neighbors while we're still loading map
	if(mapload && . != INITIALIZE_HINT_QDEL)
		return INITIALIZE_HINT_LATELOAD
	// Otherwise do it now, but defer icon update to late if it's going to happen
	update_connections(TRUE)
	if(. != INITIALIZE_HINT_LATELOAD)
		update_icon()

/turf/closed/mineral/LateInitialize()
	if(!special_icon)
		return
	// By default this assumes being used for map late init
	// We update without cascading changes as each wall will be updated individually
	update_connections(FALSE)
	update_icon()

/turf/closed/mineral/setDir(newDir)
	..()
	if(!special_icon)
		return
	update_connections(FALSE)
	update_icon()

/turf/closed/mineral/ChangeTurf(newtype, flags, ...)
	. = ..()
	if(.) //successful turf change
		var/turf/T
		for(var/i in GLOB.alldirs)
			T = get_step(src, i)

			if(istype(T, /turf/closed/mineral))
				var/turf/closed/mineral/neighbour_wall = T
				neighbour_wall.update_connections()
				neighbour_wall.update_icon()

/turf/closed/mineral/random/desert
	icon = '_horizon/icons/turf/walls/modules_wall/stone.dmi'
