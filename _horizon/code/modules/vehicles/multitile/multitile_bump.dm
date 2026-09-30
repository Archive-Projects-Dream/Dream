/*
 * Multitile vehicle collision handling, ported from cmss13 code/modules/vehicles/multitile/multitile_bump.dm
 *
 * Adapted for Horizon-Dream: cmss13-specific structures (mortars, sentries, CM
 * barricades, dropship equipment) do not exist here, so their handlers were
 * dropped; everything else maps onto the nearest TG type. Damage numbers and
 * the vehicle-class gating are kept identical.
 */

/*
 * cmss13 used a custom /atom/movable/Collide() hook fired from its turf/Enter
 * loop. Horizon-Dream has no such hook, so the vehicle drives all ram
 * handling itself from can_move() (multitile_movement.dm), calling
 * ram_obstacle() on itself, which dispatches handle_vehicle_bump() on the
 * obstacle. Vehicles can override ram_obstacle() to filter what they are
 * able to ram (see the van).
 */
//-----------------MAIN BUMP HANDLING PROC-------------------

/// Ported entry point of cmss13's /obj/vehicle/multitile/Collide(atom/A).
/// Returns TRUE if the obstacle was cleared out of the way, FALSE if it
/// blocks the vehicle.
/obj/vehicle/multitile/proc/ram_obstacle(atom/obstacle)
	return obstacle.handle_vehicle_bump(src)

/atom/proc/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	return FALSE
//-----------------------------------------------------------
//-------------------------TURFS-----------------------------
//-----------------------------------------------------------

// TG walls have no health pool like cmss13's (its hull walls sat at 3000
// with 30 damage per ram, reinforced at 9000), so ramming chips away at
// these vars instead; dents show the wear and the wall finally collapses
// into a girder once the breakpoint is reached.
/turf/closed/wall
	/// Ram damage this wall has accumulated from multitile vehicles
	var/vehicle_ram_damage_taken = 0
	/// How much ramming the wall survives before collapsing (cmss13: HEALTH_WALL 3000 / HEALTH_WALL_REINFORCED 9000)
	var/vehicle_ram_breakpoint = 3000

/turf/closed/wall/r_wall
	vehicle_ram_breakpoint = 9000

/turf/closed/wall/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	if(!(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_WEAK))
		bumping_vehicle.take_damage_type(10, "blunt", src)
		playsound(src, '_horizon/sounds/effects/metal_crash.ogg', 35)
		visible_message(span_danger("\The [bumping_vehicle] rams \the [src]!"))
		vehicle_ram_damage_taken += bumping_vehicle.wall_ram_damage
		add_dent(WALL_DENT_HIT)
		if(vehicle_ram_damage_taken >= vehicle_ram_breakpoint)
			vehicle_ram_damage_taken = 0
			dismantle_wall(FALSE, TRUE)
	return FALSE
//-----------------------------------------------------------
//-------------------------OBJECTS---------------------------
//-----------------------------------------------------------

/obj/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	if(!(resistance_flags & UNACIDABLE))
		bumping_vehicle.take_damage_type(5, "blunt", src)
		visible_message(span_danger("\The [bumping_vehicle] crushes [src]!"))
		playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 20)
		qdel(src)
	return FALSE
//-----------------------------------------------------------
//-------------------------STRUCTURES------------------------
//-----------------------------------------------------------

/obj/structure/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	if(!(resistance_flags & INDESTRUCTIBLE) && !(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_WEAK))
		visible_message(span_danger("\The [bumping_vehicle] crushes [src]!"))
		playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 20)
		take_damage(500)
	if(bumping_vehicle.vehicle_flags & (VEHICLE_CLASS_MEDIUM | VEHICLE_CLASS_HEAVY))
		return TRUE
	return FALSE
/obj/structure/table/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 20)
	visible_message(span_danger("\The [bumping_vehicle] crushes \the [src]!"))
	deconstruct(TRUE)
	return TRUE
/obj/structure/rack/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 20)
	visible_message(span_danger("\The [bumping_vehicle] crushes \the [src]!"))
	deconstruct(TRUE)
	return TRUE
/obj/structure/reagent_dispensers/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 20)
	visible_message(span_danger("\The [bumping_vehicle] crushes \the [src]!"))
	qdel(src)
	return TRUE
/// Fuel tanks are the one thing you really don't want to ram
/obj/structure/reagent_dispensers/fueltank/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	visible_message(span_danger("\The [bumping_vehicle] crushes \the [src], causing an explosion!"))
	playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 20)
	var/mob/living/driver = bumping_vehicle.get_seat_mob(VEHICLE_DRIVER)
	log_combat(driver, src, "exploded by ramming with", bumping_vehicle)
	atmos_spawn_air("[GAS_O2]=[round(reagents.total_volume, 1)];[GAS_PLASMA]=[round(reagents.total_volume, 1)]")
	explosion(src, devastation_range = 0, heavy_impact_range = 2, light_impact_range = 4, flame_range = 5)
	qdel(src)
	return FALSE
/obj/structure/grille/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	if(!(bumping_vehicle.vehicle_flags & (VEHICLE_CLASS_MEDIUM | VEHICLE_CLASS_HEAVY)))
		bumping_vehicle.move_momentum -= bumping_vehicle.move_momentum * 0.5
	visible_message(span_danger("\The [bumping_vehicle] crushes \the [src]!"))
	playsound(src, 'sound/effects/grillehit.ogg', 20)
	take_damage(60)
	return TRUE
/obj/structure/window/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	if(!atom_integrity)
		return FALSE
	take_damage(200)
	return TRUE
/obj/structure/chair/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	visible_message(span_danger("\The [bumping_vehicle] rams \the [src]!"))
	deconstruct(TRUE)
	return TRUE
/obj/structure/flora/tree/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	if(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_WEAK)
		return FALSE
	else if(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_LIGHT)
		bumping_vehicle.move_momentum -= bumping_vehicle.move_momentum * 0.5
	visible_message(span_danger("\The [bumping_vehicle] crushes \the [src]!"))
	playsound(src, '_horizon/sounds/effects/metal_crash.ogg', 20)
	playsound(src, 'sound/effects/woodhit.ogg', 20)
	qdel(src)
	return TRUE
/obj/structure/closet/crate/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	open(null, TRUE)
	visible_message(span_danger("\The [bumping_vehicle] crushes \the [src]!"))
	playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 20)
	qdel(src)
	return FALSE
/obj/structure/closet/crate/large/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	visible_message(span_danger("\The [bumping_vehicle] crushes \the [src]!"))
	playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 20)
	deconstruct(TRUE)
	return TRUE
//-----------------------------------------------------------
//-------------------------MACHINERY------------------------
//-----------------------------------------------------------

/// We attempt to open doors before crushing them; check if we can even fit through first
/obj/machinery/door/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	var/list/vehicle_dimensions = bumping_vehicle.get_dimensions()
	// The door should be facing east/west when the vehicle is facing north/south, and north/south when the vehicle is facing east/west
	// cmss13 doors carried a width var for multi-tile doors; TG doors are all
	// one tile wide, so only single-tile-wide vehicles can slip through
	if(((bumping_vehicle.dir & (NORTH|SOUTH) && dir & (EAST|WEST)) || (bumping_vehicle.dir & (EAST|WEST) && dir & (NORTH|SOUTH))) && vehicle_dimensions["width"] <= 1)
		// Driver needs access
		var/mob/living/driver = bumping_vehicle.get_seat_mob(VEHICLE_DRIVER)
		if(!requiresID() || (driver && allowed(driver)))
			if(density)
				open(TRUE)
			return FALSE
	if(!(resistance_flags & INDESTRUCTIBLE))
		visible_message(span_danger("\The [bumping_vehicle] pushes [src] over!"))
		playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 20)
		qdel(src)
	return FALSE
/obj/machinery/door/poddoor/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	if(!(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_WEAK))
		if(!(resistance_flags & INDESTRUCTIBLE))
			visible_message(span_danger("\The [bumping_vehicle] pushes [src] over!"))
			playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 35)
			bumping_vehicle.take_damage_type(10, "blunt", src)
			qdel(src)
	return FALSE
/obj/machinery/door/poddoor/shutters/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	if(!(resistance_flags & INDESTRUCTIBLE))
		visible_message(span_danger("\The [bumping_vehicle] pushes [src] over!"))
		playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 35)
		qdel(src)
	return FALSE
/obj/machinery/recharger/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 20)
	visible_message(span_danger("\The [bumping_vehicle] drives over \the [src]!"))
	qdel(src)
	return TRUE
/obj/machinery/disposal/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	qdel(src)
	return TRUE
/obj/machinery/hydroponics/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	if(!(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_WEAK))
		playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 20)
		visible_message(span_danger("\The [bumping_vehicle] crushes \the [src]!"))
		qdel(src)
		return TRUE
	return FALSE
//-----------------------------------------------------------
//-------------------------VEHICLES------------------------
//-----------------------------------------------------------

/obj/vehicle/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	bumping_vehicle.take_damage_type(5, "blunt", src)
	take_damage(ceil(max_integrity/2.8)) //we destroy any simple vehicle in 3 crushes
	visible_message(span_danger("\The [bumping_vehicle] crushes into \the [src]!"))
	playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 35)
	return FALSE
/obj/vehicle/multitile/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	var/damage
	if(last_move_dir == REVERSE_DIR(bumping_vehicle.last_move_dir)) //crashing into each other
		damage = move_momentum + bumping_vehicle.move_momentum
	else if(last_move_dir == bumping_vehicle.last_move_dir) //crashing into something from behind
		damage = max(bumping_vehicle.move_momentum - move_momentum, 0)
	else
		damage = bumping_vehicle.move_momentum
	damage = 5 * (damage + 1) //5 is minimal damage of bumping which is multiplied on vehicles' current momentum.
	if(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_WEAK)
		bumping_vehicle.take_damage_type(TIER_3_RAM_DAMAGE_TAKEN, "blunt", src)
	else
		bumping_vehicle.take_damage_type(damage, "blunt", src)
	if(vehicle_flags & VEHICLE_CLASS_WEAK)
		take_damage_type(TIER_3_RAM_DAMAGE_TAKEN, "blunt", bumping_vehicle)
	else
		take_damage_type(damage, "blunt", bumping_vehicle)
	visible_message(span_danger("\The [bumping_vehicle] crushes into \the [src]!"))
	playsound(bumping_vehicle, '_horizon/sounds/effects/metal_crash.ogg', 35)
	return FALSE
//-----------------------------------------------------------
//-------------------------MOBS------------------------------
//-----------------------------------------------------------

/mob/living/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	if(stat == DEAD || IsKnockdown() || IsParalyzed())
		apply_damage(7 + rand(0, 5), BRUTE)
		return TRUE
	var/dmg = FALSE
	if(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_WEAK)
		Knockdown(1 SECONDS)
	else if(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_LIGHT)
		Knockdown(2 SECONDS)
		apply_damage(5 + rand(0, 10), BRUTE)
		dmg = TRUE
	else if(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_MEDIUM)
		Knockdown(3 SECONDS)
		apply_damage(10 + rand(0, 10), BRUTE)
		dmg = TRUE
	else if(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_HEAVY)
		Knockdown(5 SECONDS)
		apply_damage(15 + rand(0, 10), BRUTE)
		dmg = TRUE
	var/list/slots = bumping_vehicle.get_activatable_hardpoints()
	for(var/slot in slots)
		var/obj/item/hardpoint/held_hardpoint = bumping_vehicle.hardpoints[slot]
		if(!held_hardpoint)
			continue
		held_hardpoint.livingmob_interact(src)
	Knockdown(3 SECONDS)
	apply_damage(7 + rand(0, 5), BRUTE)
	var/mob_moved = step(src, bumping_vehicle.last_move_dir)
	visible_message(span_danger("\The [bumping_vehicle] rams \the [src]!"), span_userdanger("\The [bumping_vehicle] rams you! Get out of the way!"))
	if(dmg)
		playsound(loc, 'sound/items/weapons/punch1.ogg', 25, TRUE)
		var/mob/living/driver = bumping_vehicle.get_seat_mob(VEHICLE_DRIVER)
		log_combat(driver, src, "rammed", bumping_vehicle)
	else
		var/mob/living/driver = bumping_vehicle.get_seat_mob(VEHICLE_DRIVER)
		log_combat(driver, src, "friendly pushed", bumping_vehicle)
	return mob_moved
//-------------------------HUMANS------------------------

/mob/living/carbon/human/handle_vehicle_bump(obj/vehicle/multitile/bumping_vehicle)
	var/dmg = FALSE
	var/mob_moved = FALSE
	var/mob_knocked_down = stat == DEAD || IsKnockdown() || IsParalyzed()
	if(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_WEAK)
		if(!mob_knocked_down)
			var/direction_taken = pick(45, 0, -45)
			mob_moved = step(src, turn(bumping_vehicle.last_move_dir, direction_taken))
			if(!mob_moved)
				mob_moved = step(src, turn(bumping_vehicle.last_move_dir, -direction_taken))
	else if(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_LIGHT)
		dmg = TRUE
		Knockdown(2 SECONDS)
		apply_damage(10 + rand(0, 10), BRUTE)
	else if(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_MEDIUM)
		Knockdown(3 SECONDS)
		apply_damage(10 + rand(0, 10), BRUTE)
		dmg = TRUE
	else if(bumping_vehicle.vehicle_flags & VEHICLE_CLASS_HEAVY)
		Knockdown(5 SECONDS)
		apply_damage(15 + rand(0, 10), BRUTE)
		dmg = TRUE
	visible_message(span_danger("\The [bumping_vehicle] rams \the [src]!"), span_userdanger("\The [bumping_vehicle] rams you! Get out of the way!"))
	if(dmg)
		playsound(loc, 'sound/items/weapons/punch1.ogg', 25, TRUE)
		var/mob/living/driver = bumping_vehicle.get_seat_mob(VEHICLE_DRIVER)
		log_combat(driver, src, "rammed", bumping_vehicle)
	if(mob_knocked_down)
		return TRUE
	else if(mob_moved)
		playsound(loc, 'sound/items/weapons/punch1.ogg', 25, TRUE)
	return TRUE