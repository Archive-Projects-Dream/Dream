/mutable_appearance/frill
	appearance_flags = TILE_BOUND | RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM

/proc/get_wall_object(icon, icon_state, dir = 2, pixel_x = 0, pixel_y = 0, plane = GAME_PLANE, layer = ABOVE_MOB_LAYER, atom/offset_spokesman)
	var/mutable_appearance/frill/vis = new()
	vis.icon = icon
	vis.icon_state = icon_state
	vis.pixel_x = pixel_x
	vis.pixel_y = pixel_y
	vis.layer = layer
	if(isatom(offset_spokesman))
		SET_PLANE_EXPLICIT(vis, plane, offset_spokesman)
	else
		vis.plane = plane
	return make_mutable_appearance_directional(vis, dir)

/turf/closed/wall/update_icon()
	. = ..()
	if(!special_icon)
		return

	overlays.Cut()
	icon_state = "blank"

	for(var/i in 1 to 4)
		overlays += get_wall_object(icon, "wall[wall_connections[i]]", 1<<(i-1), plane = WALL_PLANE, offset_spokesman = src)

/turf/closed/proc/update_connections(propagate = 0)
	var/list/wall_dirs = list()
	for(var/turf/closed/W in orange(src, 1))
		switch(can_join_with(W))
			if(FALSE)
				continue
			if(TRUE)
				wall_dirs += get_dir(src, W)
		if(propagate)
			W.update_connections()
			W.update_icon()

	for(var/turf/T in orange(src, 1))
		var/success = 0
		for(var/obj/O in T)
			for(var/b_type in blend_objects)
				if(istype(O, b_type))
					success = TRUE
				for(var/nb_type in noblend_objects)
					if(istype(O, nb_type))
						success = FALSE
				if(success)
					break
			if(success)
				break

		if(success)
			if(get_dir(src, T) in GLOB.cardinals)
				wall_dirs += get_dir(src, T)

	wall_connections = dirs_to_corner_states(wall_dirs)

/turf/closed/proc/can_join_with(turf/closed/wall/W)
	if(W.type == src.type)
		return 1
	for(var/wb_type in blend_turfs)
		for(var/nb_type in noblend_turfs)
			if(istype(W, nb_type))
				return FALSE
		if(istype(W, wb_type))
			return TRUE
	return FALSE

#define CORNER_NONE 0
#define CORNER_COUNTERCLOCKWISE 1
#define CORNER_DIAGONAL 2
#define CORNER_CLOCKWISE 4

/proc/dirs_to_corner_states(list/dirs)
	if(!istype(dirs))
		return

	var/list/ret = list(NORTHWEST, SOUTHEAST, NORTHEAST, SOUTHWEST)

	for(var/i = 1 to length(ret))
		var/dir = ret[i]
		. = CORNER_NONE
		if(dir in dirs)
			. |= CORNER_DIAGONAL
		if(turn(dir,45) in dirs)
			. |= CORNER_COUNTERCLOCKWISE
		if(turn(dir,-45) in dirs)
			. |= CORNER_CLOCKWISE
		ret[i] = "[.]"

	return ret

#undef CORNER_NONE
#undef CORNER_COUNTERCLOCKWISE
#undef CORNER_DIAGONAL
#undef CORNER_CLOCKWISE

/turf/closed/mineral

/turf/closed/mineral/update_icon()
	. = ..()
	if(!special_icon)
		return

	overlays.Cut()
	icon_state = "blank"
	var/image/I
	for(var/i in 1 to 4)
		I = image(icon, "wall[wall_connections[i]]", dir = 1<<(i-1))
		I.plane = GAME_PLANE
		overlays += I
