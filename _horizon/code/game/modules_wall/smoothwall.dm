//Separate dm because it relates to two types of atoms + ease of removal in case it's needed.
//Also assemblies.dm for falsewall checking for this when used.
//I should really make the shuttle wall check run every time it's moved, but centcom uses unsimulated floors so !effort

/atom
	//A list of paths only that each turf should tile with
	var/list/tiles_with

/atom/proc/relativewall() //atom because it should be useable both for walls, false walls, doors, windows, etc
	var/junction = 0 //flag used for icon_state
	var/turf/turf_check //The turf we are checking
	var/first_iterator //iterator
	var/second_iterator //second iterator
	var/third_iterator //third iterator (I know, that's a lot, but I'm trying to make this modular, so bear with me)

	for(first_iterator in GLOB.cardinals) //For all cardinal dir turfs
		turf_check = get_step(src, first_iterator)
		if(!istype(turf_check))
			continue
		for(second_iterator in tiles_with) //And for all types that we tile with
			if(istype(turf_check, second_iterator))
				junction |= first_iterator
				break

			for(third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					junction |= first_iterator
					break

	handle_icon_junction(junction)

/atom/proc/relativewall_neighbours()
	var/turf/turf_check //The turf we are checking
	var/first_iterator //iterator
	var/second_iterator //second iterator
	var/atom/third_iterator //third iterator (I know, that's a lot, but I'm trying to make this modular, so bear with me)

	for(first_iterator in GLOB.cardinals) //For all cardinal dir turfs
		turf_check = get_step(src, first_iterator)
		if(!istype(turf_check))
			continue
		for(second_iterator in tiles_with) //And for all types that we tile with
			if(istype(turf_check, second_iterator))
				turf_check.relativewall() //If we tile this type, junction it
				break

			for(third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					third_iterator.relativewall() //get_dir to first_iterator, since third_iterator is something inside the turf turf_check
					break

/atom/proc/handle_icon_junction(junction)
	return

/*
// Special case for smoothing walls around multi-tile doors.
/obj/structure/machinery/door/airlock/multi_tile/relativewall_neighbours()
	var/turf/turf_check //The turf we are checking
	var/atom/third_iterator
	var/second_iterator

	if (dir == SOUTH)
		turf_check = locate(x, y+2, z)
		for(second_iterator in tiles_with)
			if(istype(turf_check, second_iterator))
				turf_check.relativewall()
				break
			for(third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					third_iterator.relativewall()
					break

		turf_check = get_step(src, SOUTH)
		for(second_iterator in tiles_with)
			if(istype(turf_check, second_iterator))
				turf_check.relativewall()
				break
			for(third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					third_iterator.relativewall()
					break

	else if (dir == EAST)
		turf_check = locate(x+2, y, z)
		for(second_iterator in tiles_with)
			if(istype(turf_check, second_iterator))
				turf_check.relativewall()
				break
			for(third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					third_iterator.relativewall()
					break

		turf_check = get_step(src, WEST)
		for(second_iterator in tiles_with)
			if(istype(turf_check, second_iterator))
				turf_check.relativewall()
				break
			for(third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					third_iterator.relativewall()
					break
*/
/*
// Not proud of this.
/obj/structure/mineral_door/resin/handle_icon_junction(junction)
	if(junction & (SOUTH|NORTH))
		setDir(WEST)
	else if(junction & (EAST|WEST))
		setDir(NORTH)
*/
/*
/turf/open/asphalt/cement/relativewall()
	var/junction = 0 //flag used for icon_state
	var/turf/turf_check //The turf we are checking
	var/first_iterator //iterator
	var/second_iterator //second iterator
	var/third_iterator //third iterator (I know, that's a lot, but I'm trying to make this modular, so bear with me)

	for(first_iterator in GLOB.alldirs) //For all cardinal dir turfs
		turf_check = get_step(src, first_iterator)
		if(!istype(turf_check))
			continue
		for(second_iterator in tiles_with) //And for all types that we tile with
			if(istype(turf_check, second_iterator))
				junction |= first_iterator
				break

			for(third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					junction |= first_iterator
					break

	handle_icon_junction(junction)

/turf/open/asphalt/cement_sunbleached/relativewall()
	var/junction = 0 //flag used for icon_state
	var/turf/turf_check //The turf we are checking
	var/first_iterator //iterator
	var/second_iterator //second iterator
	var/third_iterator //third iterator (I know, that's a lot, but I'm trying to make this modular, so bear with me)

	for(first_iterator in GLOB.alldirs) //For all cardinal dir turfs
		turf_check = get_step(src, first_iterator)
		if(!istype(turf_check))
			continue
		for(second_iterator in tiles_with) //And for all types that we tile with
			if(istype(turf_check, second_iterator))
				junction |= first_iterator
				break

			for(third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					junction |= first_iterator
					break

	handle_icon_junction(junction)
*/
