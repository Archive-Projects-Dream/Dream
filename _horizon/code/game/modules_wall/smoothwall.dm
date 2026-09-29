//Separate dm because it relates to two types of atoms + ease of removal in case it's needed.
//Also assemblies.dm for falsewall checking for this when used.
//I should really make the shuttle wall check run every time it's moved, but centcom uses unsimulated floors so !effort

//Junction bits for diagonal (corner-cut) links. Cardinal bits keep the BYOND
//dir values (NORTH=1, SOUTH=2, EAST=4, WEST=8), diagonals take the high nibble,
//so handle_icon_junction() can keep using one plain number for icon_state.
#define SMOOTH_JUNCTION_NE (1<<4)
#define SMOOTH_JUNCTION_SE (1<<5)
#define SMOOTH_JUNCTION_SW (1<<6)
#define SMOOTH_JUNCTION_NW (1<<7)

/atom
	//A list of paths only that each turf should tile with
	var/list/tiles_with
	/// When TRUE, relativewall() also computes diagonal (corner-cut) links:
	/// a diagonal bit is set only when both cardinals touching that corner
	/// are open and something we tile with sits diagonally across it.
	var/smooth_diagonals = FALSE

/atom/proc/relativewall() //atom because it should be useable both for walls, false walls, doors, windows, etc
	var/junction = 0 //flag used for icon_state
	var/turf/turf_check //The turf we are checking

	for(var/first_iterator in GLOB.cardinals) //For all cardinal dir turfs
		turf_check = get_step(src, first_iterator)
		if(!istype(turf_check))
			continue
		for(var/second_iterator in tiles_with) //And for all types that we tile with
			if(istype(turf_check, second_iterator))
				junction |= first_iterator
				break

			for(var/atom/third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					junction |= first_iterator
					break

	if(smooth_diagonals)
		junction |= relativewall_diagonals(junction)

	handle_icon_junction(junction)

/*
 * Diagonal (corner-cut) junction bits, for masks that must stay connected when
 * two runs meet without a corner tile:
 *
 *      ..#..             ..#..
 *      --...     ->      --%.. (% = diagonal link, drawn by BOTH shadows)
 *
 * A diagonal bit is only set when both cardinals touching that corner are open:
 * if either one is connected, the corner is already sealed by the regular
 * cardinal mask. NORTHEAST is literally NORTH|EAST, so a single `&` against
 * the cardinal junction covers both checks.
 */
/atom/proc/relativewall_diagonals(cardinal_junction)
	var/diagonal_junction = 0
	var/turf/turf_check //The turf we are checking

	for(var/first_iterator in GLOB.diagonals)
		if(cardinal_junction & first_iterator)
			continue
		turf_check = get_step(src, first_iterator)
		if(!istype(turf_check))
			continue
		for(var/second_iterator in tiles_with) //And for all types that we tile with
			if(istype(turf_check, second_iterator))
				diagonal_junction |= diagonal_junction_bit(first_iterator)
				break

			for(var/atom/third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					diagonal_junction |= diagonal_junction_bit(first_iterator)
					break

	return diagonal_junction

/proc/diagonal_junction_bit(diagonal_dir)
	switch(diagonal_dir)
		if(NORTHEAST)
			return SMOOTH_JUNCTION_NE
		if(SOUTHEAST)
			return SMOOTH_JUNCTION_SE
		if(SOUTHWEST)
			return SMOOTH_JUNCTION_SW
		if(NORTHWEST)
			return SMOOTH_JUNCTION_NW
	return 0

/// Collects every adjacent smoother whose junction can depend on src, i.e.
/// things we tile with in all 8 directions. Diagonal neighbours only care
/// when they render diagonal links themselves.
/atom/proc/get_adjacent_smoothers()
	var/list/smoothers = list()
	var/turf/turf_check //The turf we are checking

	for(var/first_iterator in GLOB.alldirs)
		var/diagonal_link = (first_iterator in GLOB.diagonals)
		turf_check = get_step(src, first_iterator)
		if(!istype(turf_check))
			continue
		for(var/second_iterator in tiles_with) //And for all types that we tile with
			if(istype(turf_check, second_iterator))
				if(!diagonal_link || turf_check.smooth_diagonals)
					smoothers |= turf_check
				break

			for(var/atom/third_iterator in turf_check)
				if(istype(third_iterator, second_iterator))
					if(!diagonal_link || third_iterator.smooth_diagonals)
						smoothers |= third_iterator
					break

	return smoothers

/atom/proc/relativewall_neighbours()
	for(var/atom/smoothing_neighbour in get_adjacent_smoothers())
		smoothing_neighbour.relativewall()

/atom/proc/handle_icon_junction(junction)
	return

#undef SMOOTH_JUNCTION_NE
#undef SMOOTH_JUNCTION_SE
#undef SMOOTH_JUNCTION_SW
#undef SMOOTH_JUNCTION_NW

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
