// open_turf.dm
//turfs with density = FALSE

/turf/open
	plane = FLOOR_PLANE
	var/is_groundmap_turf = FALSE //whether this a turf used as main turf type for the 'outside' of a map.
	var/allow_construction = TRUE //whether you can build things like barricades on this turf.
	var/wet = 0 //whether the turf is wet (only used by floors).
	var/supports_surgery = TRUE
	var/scorchable = FALSE //if TRUE set to be an icon_state which is the full sprite version of whatever gets scorched --> for border turfs like grass edges and shorelines
	var/scorchedness = 0 //how scorched is this turf 0 to 3
	var/icon_state_before_scorching //this is really dumb, blame the mappers...

/turf/open/Initialize(mapload, ...)
	. = ..()
	update_icon()

/turf/open/update_icon()
	. = ..()
	var/list/new_overlays = list()
	var/alist/auto_turf_dirs = alist()
	for(var/turf/open/auto_turf/auto_neighbor in orange(1, src))
		if(!auto_neighbor.layers_over(src))
			continue
		auto_turf_dirs[get_dir(src, auto_neighbor)] = auto_neighbor

	if(length(auto_turf_dirs))
		var/list/handled_dirs = list()
		var/list/unhandled_dirs = list()
		for(var/direction in GLOB.diagonals)
			var/x_dir = direction & (direction-1)
			var/y_dir = direction - x_dir

			if(!(direction in auto_turf_dirs))
				unhandled_dirs |= x_dir
				unhandled_dirs |= y_dir
				continue

			var/turf/open/auto_turf/xy_turf = auto_turf_dirs[direction]
			if((x_dir in auto_turf_dirs) && (y_dir in auto_turf_dirs))
				var/turf/open/auto_turf/x_turf = auto_turf_dirs[x_dir]
				var/turf/open/auto_turf/y_turf = auto_turf_dirs[y_dir]

				if(x_turf.icon_prefix == y_turf.icon_prefix && x_turf.icon_prefix == xy_turf.icon_prefix)
					var/special_icon_state = "[xy_turf.icon_prefix]_innercorner"
					new_overlays += get_wall_object(xy_turf.icon, special_icon_state, dir = REVERSE_DIR(direction), plane = plane, layer = layer + 0.001 + xy_turf.bleed_layer * 0.001)
					handled_dirs += x_dir
					handled_dirs += y_dir
					continue

			var/special_icon_state = "[xy_turf.icon_prefix]_outercorner"
			new_overlays += get_wall_object(xy_turf.icon, special_icon_state, dir = REVERSE_DIR(direction), plane = plane, layer = layer + 0.001 + xy_turf.bleed_layer * 0.001)
			unhandled_dirs |= x_dir
			unhandled_dirs |= y_dir

		for(var/direction in unhandled_dirs)
			if((direction in auto_turf_dirs) && !(direction in handled_dirs))
				var/turf/open/auto_turf/turf = auto_turf_dirs[direction]
				var/special_icon_state = "[turf.icon_prefix]_[pick("innercorner", "outercorner")]"
				new_overlays += get_wall_object(turf.icon, special_icon_state, dir = REVERSE_DIR(direction), plane = plane, layer = layer + 0.001 + turf.bleed_layer * 0.001)

	cut_overlays()
	add_overlay(new_overlays)

// Auto-turf

/turf/open/auto_turf
	name = "auto-sand"
	icon = '_horizon/icons/turf/open/auto_sand.dmi'
	icon_state = "sand_1"//editor icon
	is_groundmap_turf = TRUE
	var/icon_prefix = "sand"
	var/layer_name = list("layer 1", "layer2", "layer 3", "layer 4", "layer 5")
	var/variant = 0
	var/variant_prefix_name = ""
	var/bleed_layer = 0 //snow layer

/turf/open/auto_turf/Initialize(mapload, ...)
	. = ..()
	update_neighbors()

/turf/open/auto_turf/setDir()
	SHOULD_CALL_PARENT(FALSE)
	dir = pick(NORTH,SOUTH,EAST,WEST,NORTHEAST,NORTHWEST,SOUTHEAST,SOUTHWEST)

/turf/proc/insert_self_into_baseturfs()
	baseturfs += type

/turf/open/auto_turf/insert_self_into_baseturfs()
	baseturfs += type

/turf/open/auto_turf/proc/layers_over(turf/open/other_turf)
	if(istype(other_turf, /turf/open/auto_turf))
		var/turf/open/auto_turf/other_auto_turf = other_turf
		return bleed_layer > other_auto_turf.bleed_layer
	return (bleed_layer > 0) // assume all non auto turfs have a bleed layer of 0

//Update icon
/turf/open/auto_turf/update_icon()
	if(variant && (bleed_layer == initial(bleed_layer)))
		icon_state = "[icon_prefix]_[bleed_layer]_[variant]"
	else
		icon_state = "[icon_prefix]_[bleed_layer]"

	var/name_to_set
	switch(bleed_layer)
		if(0)
			name_to_set = layer_name[1]
		if(1)
			name_to_set = layer_name[2]
		if(2)
			name_to_set = layer_name[3]
		if(3)
			name_to_set = layer_name[4]
		if(4)
			name_to_set= layer_name[5]

	if(bleed_layer == initial(bleed_layer))
		name = variant_prefix_name + " " + name_to_set
	else
		name = name_to_set

	..()

/turf/open/auto_turf/proc/changing_layer(new_layer)
	if(isnull(new_layer) || new_layer == bleed_layer)
		return

	bleed_layer = max(0, new_layer)

	update_icon()
	update_neighbors()

/turf/open/auto_turf/proc/update_neighbors()
	for(var/direction in GLOB.alldirs)
		var/turf/open/T = get_step(src, direction)
		if(istype(T))
			T.update_icon()

/turf/open/auto_turf/ChangeTurf(newtype, flags, ...)
	. = ..()
	if(.)
		for(var/direction in GLOB.alldirs)
			var/turf/T = get_step(src, direction)
			if(istype(T, /turf/open))
				T.update_icon()
