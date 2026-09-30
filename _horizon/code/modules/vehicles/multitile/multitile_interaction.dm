/*
 * Multitile vehicle interaction, ported from cmss13 code/modules/vehicles/multitile/multitile_interaction.dm
 *
 * Adapted for Horizon-Dream (TG):
 * - TG attack signatures: attackby(..., modifiers), attack_hand(..., modifiers)
 * - pulled atoms replace cmss13 /obj/item/grab
 * - powerloader clamps and skills are not ported
 * - crew aiming happens through COMSIG_CLIENT_MOUSEDOWN/UP/DRAG (see multitile.dm)
 */

// Special cases abound, handled below or in subclasses
/obj/vehicle/multitile/attackby(obj/item/attacked_with, mob/user, list/modifiers, list/attack_modifiers)
	// Are we trying to install stuff?
	if(istype(attacked_with, /obj/item/hardpoint))
		install_hardpoint(attacked_with, user)
		return
	// Are we trying to remove stuff?
	if(attacked_with.tool_behaviour == TOOL_CROWBAR)
		uninstall_hardpoint(attacked_with, user)
		return
	// Are we trying to repair the frame?
	if(attacked_with.tool_behaviour == TOOL_WELDER || attacked_with.tool_behaviour == TOOL_WRENCH)
		handle_repairs(attacked_with, user)
		return
	// Are we trying to immobilize the vehicle?
	if(istype(attacked_with, /obj/item/vehicle_clamp))
		if(clamped)
			to_chat(user, span_warning("[src] already has a [attacked_with.name] attached."))
			return
		for(var/obj/item/hardpoint/locomotion/locomotion_module in hardpoints)
			user.visible_message(span_warning("[user] attaches the vehicle clamp to \the [src]."), span_notice("You attach the vehicle clamp to \the [src] and lock the mechanism."))
			attach_clamp(attacked_with, user)
			return
		to_chat(user, span_warning("There are no treads or wheels to attach \the [attacked_with.name] to."))
		return
	// Are we trying to remove a vehicle clamp?
	if(attacked_with.tool_behaviour == TOOL_SCREWDRIVER)
		if(!clamped)
			return
		user.visible_message(span_warning("[user] starts removing the vehicle clamp from [src]."), span_notice("You start removing the vehicle clamp from [src]."))
		if(!do_after(user, 5 SECONDS, target = src))
			user.visible_message(span_warning("[user] stops removing the vehicle clamp from [src]."), span_warning("You stop removing the vehicle clamp from [src]."))
			return
		user.visible_message(span_warning("[user] removes the vehicle clamp from [src]."), span_notice("You manage to unlock vehicle clamp and take it off [src]."))
		detach_clamp(user)
		return
	// Try to fit something in the vehicle without getting in ourselves
	if(ishuman(user) && !user.combat_mode && user.pulling)
		var/mob_x = user.x - src.x
		var/mob_y = user.y - src.y
		for(var/entrance in entrances)
			var/entrance_coord = entrances[entrance]
			if(mob_x == entrance_coord[1] && mob_y == entrance_coord[2])
				var/atom/dragged_atom = user.pulling
				if(istype(dragged_atom, /obj/item/grenade))
					var/obj/item/grenade/thrown_grenade = dragged_atom
					if(!thrown_grenade.active) //very creative, but no.
						break
				handle_fitting_pulled_atom(user, dragged_atom)
				return
	if(istype(attacked_with, /obj/item/grenade))
		var/obj/item/grenade/thrown_grenade = attacked_with
		if(door_locked && atom_integrity > 0 && !allowed(user))
			to_chat(user, span_warning("\The [src] is locked!"))
			return
		var/mob_x = user.x - x
		var/mob_y = user.y - y
		var/entrance_used = null
		for(var/entrance in entrances)
			var/entrance_coord = entrances[entrance]
			if(mob_x == entrance_coord[1] && mob_y == entrance_coord[2])
				entrance_used = entrance
				break
		if(entrance_used) //if we are at a door, throw it in, else do nothing.
			user.visible_message(span_warning("[user] takes position to throw [thrown_grenade] through the door of [src]."),
			span_warning("You take position to throw [thrown_grenade] through the door of [src]."))
			if(!do_after(user, 1 SECONDS, target = src))
				return
			if(mob_x != user.x - x || mob_y != user.y - y)
				return
			user.visible_message(span_warning("[user] throws [thrown_grenade] through the door of [src]!"),
			span_warning("You throw [thrown_grenade] through the door of [src]."))
			user.temporarilyRemoveItemFromInventory(thrown_grenade)
			interior.enter(thrown_grenade, entrance_used)
			if(!thrown_grenade.active)
				thrown_grenade.arm_grenade(user)
		return
	if(!isliving(user) || !user.combat_mode)
		handle_player_entrance(user)
		return
	take_damage_type(attacked_with.force * 0.05, "blunt", user) //Melee weapons from people do very little damage
// Frame repairs on the vehicle itself
/obj/vehicle/multitile/proc/handle_repairs(obj/item/repair_tool, mob/user)
	var/max_hp = max_integrity
	if(atom_integrity > max_hp)
		atom_integrity = max_hp
	// If the frame itself is intact, repair the turret holder instead
	if(atom_integrity >= max_hp)
		for(var/obj/item/hardpoint/holder/holder_module in hardpoints)
			if(holder_module.atom_integrity > 0)
				if(repair_tool.tool_behaviour != TOOL_WELDER)
					to_chat(user, span_warning("You need welding tool to repair \the [holder_module.name]."))
					return
				if(!repair_tool.tool_start_check(user, amount = 1))
					to_chat(user, span_warning("\The [repair_tool] needs to be on!"))
					return
				holder_module.handle_repair(repair_tool, user)
				update_appearance()
				return
			else
				to_chat(user, span_warning("[holder_module] is beyond repairs!"))
				return
	var/repair_message = "welding structural struts back in place"
	var/sound_file = 'sound/items/tools/welder2.ogg'
	// For health < 75%, the frame needs welderwork, otherwise wrench
	if(atom_integrity < max_hp * 0.75)
		if(repair_tool.tool_behaviour != TOOL_WELDER)
			to_chat(user, span_notice("The frame is way too busted! Try using a [span_bold("welder")]."))
			return
		if(!repair_tool.tool_start_check(user, amount = 1))
			to_chat(user, span_warning("\The [repair_tool] needs to be on!"))
			return
	else
		if(repair_tool.tool_behaviour != TOOL_WRENCH)
			to_chat(user, span_notice("The frame is structurally sound, but there are a lot of loose nuts and bolts. Try using a [span_bold("wrench")]."))
			return
		repair_message = "tightening various nuts and bolts on"
		sound_file = 'sound/items/tools/ratchet.ogg'
	user.visible_message(span_warning("[user] [repair_message] on \the [src]."), span_notice("You begin [repair_message] on \the [src]."))
	playsound(get_turf(user), sound_file, 25)
	while(atom_integrity < max_hp)
		if(!(world.time % 3))
			playsound(get_turf(user), sound_file, 25)
		if(!do_after(user, 1 SECONDS, target = src))
			user.visible_message(span_warning("[user] stops [repair_message] on \the [src]."), span_notice("You stop [repair_message] on \the [src]. Hull integrity is at [span_bold("[100.0*atom_integrity/max_hp]%")]%."))
			return
		atom_integrity = min(atom_integrity + max_hp/100 * 5, max_hp)
		if(lighting_holder && !lighting_holder.light)
			lighting_holder.set_light_on(TRUE)
		if(repair_tool.tool_behaviour == TOOL_WELDER)
			var/obj/item/weldingtool/welder = repair_tool
			welder.use(1)
			if(!welder.get_fuel())
				user.visible_message(span_warning("[user] stops [repair_message] on \the [src]."), span_notice("You stop [repair_message] on \the [src]. Hull integrity is at [span_bold("[100.0*atom_integrity/max_hp]%")]%."))
				return
			if(atom_integrity >= max_hp * 0.75)
				user.visible_message(span_warning("[user] finishes [repair_message] on \the [src]."), span_notice("You finish [repair_message] on \the [src]. The frame is structurally sound now, but there are a lot of loose nuts and bolts. Try using a [span_bold("wrench")]."))
				return
		to_chat(user, span_notice("Hull integrity is at [span_bold("[100.0*atom_integrity/max_hp]%")]%."))
	atom_integrity = max_integrity
	lighting_holder?.set_light_range(vehicle_light_range)
	toggle_cameras_status(TRUE)
	update_appearance()
	user.visible_message(span_notice("[user] finishes [repair_message] on \the [src]."), span_notice("You finish [repair_message] on \the [src]. Hull integrity is at [span_bold("100%")]%."))
//Special case for entering the vehicle without using the verb
/obj/vehicle/multitile/attack_hand(mob/user, list/modifiers)
	var/mob_x = user.x - src.x
	var/mob_y = user.y - src.y
	for(var/entrance in entrances)
		var/entrance_coord = entrances[entrance]
		if(mob_x == entrance_coord[1] && mob_y == entrance_coord[2])
			handle_player_entrance(user)
			return
	. = ..()
/obj/vehicle/multitile/attack_ghost(mob/dead/observer/user)
	if(!interior)
		return ..()
	var/turf/middle = interior.get_middle_turf()
	if(!middle)
		return ..()
	user.forceMove(middle)
/// Aliens trying to get inside or claw at the hull
/obj/vehicle/multitile/attack_alien(mob/living/carbon/alien/user, list/modifiers)
	// If they're on help intent, attempt to enter the vehicle
	if(!user.combat_mode)
		handle_player_entrance(user)
		return
	// If the vehicle is completely broken, aliens can enter from anywhere
	if(atom_integrity <= 0)
		handle_player_entrance(user)
		return
	if(user.mob_size < mob_size_required_to_hit)
		to_chat(user, span_warning("We're too small to do any significant damage to this vehicle!"))
		return
	var/damage = (30 + rand(-5, 5))
	user.do_attack_animation(src, ATTACK_EFFECT_CLAW)
	if(!damage)
		playsound(user.loc, 'sound/items/weapons/slashmiss.ogg', 25, TRUE)
		user.visible_message(span_danger("\The [user] swipes at \the [src] to no effect!"),
		span_danger("We swipe at \the [src] to no effect!"))
		return
	user.visible_message(span_danger("\The [user] slashes \the [src]!"),
	span_danger("We slash \the [src]!"))
	playsound(user.loc, pick('_horizon/sounds/effects/metalhit.ogg', 'sound/items/weapons/slash.ogg', 'sound/items/weapons/punch1.ogg', 'sound/items/weapons/punch2.ogg'), 25, TRUE)
	take_damage_type(damage, "slash", user)
	healthcheck()
//Differentiates between damage types from different bullets
//Applies a linear transformation to bullet damage that will generally decrease damage done
/obj/vehicle/multitile/bullet_act(obj/projectile/hitting_projectile, def_zone, piercing_hit = FALSE, blocked = null)
	var/dam_type = "bullet"
	var/damage = hitting_projectile.damage
	var/penetration = hitting_projectile.armour_penetration
	var/mob/firer = hitting_projectile.firer
	// trust me bro
	take_damage_type(damage * (0.33 + penetration/100), dam_type, firer)
	healthcheck()
	return BULLET_ACT_HIT
/obj/vehicle/multitile/ex_act(severity, target)
	take_damage_type(severity * 0.5, "explosive")
	take_damage_type(severity * 0.1, "slash")
	healthcheck()
/// Relays crew mouse release to active hardpoint.
/obj/vehicle/multitile/proc/crew_mouseup(client/source, atom/object, turf/location, control, params)
	SIGNAL_HANDLER
	var/obj/item/hardpoint/hardpoint = get_mob_hp(source?.mob)
	if(!hardpoint)
		return
	hardpoint.stop_fire(source?.mob, object, location, control, params)
/// Relays crew mouse movement to active hardpoint.
/obj/vehicle/multitile/proc/crew_mousedrag(client/source, atom/src_object, atom/over_object, turf/src_location, turf/over_location, src_control, over_control, params)
	SIGNAL_HANDLER
	var/obj/item/hardpoint/hardpoint = get_mob_hp(source?.mob)
	if(!hardpoint)
		return
	hardpoint.change_target(source?.mob, src_object, over_object, src_location, over_location, src_control, over_control, params)
/// Checks for special control keybinds, else relays crew mouse press to active hardpoint.
/obj/vehicle/multitile/proc/crew_mousedown(client/source, atom/object, turf/location, control, params)
	SIGNAL_HANDLER
	if(!source?.mob)
		return
	var/list/modifiers = params2list(params)
	if(modifiers[SHIFT_CLICK] || modifiers[MIDDLE_CLICK] || modifiers[RIGHT_CLICK] || modifiers[BUTTON4] || modifiers[BUTTON5]) //don't step on examine, point, etc
		return
	var/seat = get_mob_seat(source.mob)
	switch(seat)
		if(VEHICLE_DRIVER)
			if(modifiers[LEFT_CLICK] && modifiers[CTRL_CLICK])
				activate_horn()
				return
		if(VEHICLE_GUNNER)
			if(modifiers[LEFT_CLICK] && modifiers[ALT_CLICK])
				toggle_gyrostabilizer()
				return
	var/obj/item/hardpoint/hardpoint = get_mob_hp(source.mob)
	if(!hardpoint)
		to_chat(source.mob, span_warning("Please select an active hardpoint first."))
		return
	hardpoint.start_fire(source.mob, object, location, control, params)
/obj/vehicle/multitile/proc/handle_player_entrance(mob/entering_mob)
	if(!entering_mob || !entering_mob.client)
		return
	var/mob_x = entering_mob.x - src.x
	var/mob_y = entering_mob.y - src.y
	var/entrance_used = null
	for(var/entrance in entrances)
		var/entrance_coord = entrances[entrance]
		if(mob_x == entrance_coord[1] && mob_y == entrance_coord[2])
			entrance_used = entrance
			break
	var/enter_time = 0
	// door locks break when hull is destroyed. Non-humans enter slower, but their speed is not affected by anything and they ignore locks
	if(!ishuman(entering_mob))
		enter_time = 3 SECONDS
	else
		if(door_locked && atom_integrity > 0) //check if lock on and actually works
			if(!allowed(entering_mob))
				to_chat(entering_mob, span_warning("\The [src] is locked!"))
				return
	// Only non-humans can force their way in without doors, and only when the frame is completely broken
	if(!entrance_used && atom_integrity > 0)
		return
	else if(!entrance_used && ishuman(entering_mob))
		return
	var/enter_msg = "You start climbing into \the [src]..."
	// Check if dragging anything
	var/atom/dragged_atom
	if(entering_mob.pulling)
		dragged_atom = entering_mob.pulling
	if(!enter_time)
		enter_time = entrance_speed
		if(dragged_atom)
			enter_time = 2 SECONDS
	to_chat(entering_mob, span_notice(enter_msg))
	if(!do_after(entering_mob, enter_time, target = src))
		return
	if(entrance_used)
		var/entrance_coord = entrances[entrance_used]
		mob_x = entering_mob.x - src.x
		mob_y = entering_mob.y - src.y
		if(mob_x != entrance_coord[1] || mob_y != entrance_coord[2])
			to_chat(entering_mob, span_warning("\The [src] moved!"))
			return
	//Dragged stuff comes with us only if properly waited 2 seconds. No cheating!
	if(dragged_atom)
		dragged_atom = null
		if(entering_mob.pulling)
			dragged_atom = entering_mob.pulling
	// Transfer them to the interior
	interior.enter(entering_mob, entrance_used)
	// We try to make the dragged thing enter last so that the mob who actually entered takes precedence
	if(dragged_atom)
		entering_mob.stop_pulling()
		var/success = interior.enter(dragged_atom, entrance_used)
		if(!success)
			to_chat(entering_mob, span_warning("You fail to fit [dragged_atom] inside \the [src] and leave [ismob(dragged_atom) ? "them" : "it"] outside."))
//try to fit something into the vehicle
/obj/vehicle/multitile/proc/handle_fitting_pulled_atom(mob/living/carbon/human/user, atom/dragged_atom)
	if(!ishuman(user))
		return
	if(door_locked && atom_integrity > 0 && !allowed(user))
		to_chat(user, span_warning("\The [src] is locked!"))
		return
	var/mob_x = user.x - x
	var/mob_y = user.y - y
	var/entrance_used = null
	for(var/entrance in entrances)
		var/entrance_coord = entrances[entrance]
		if(mob_x == entrance_coord[1] && mob_y == entrance_coord[2])
			entrance_used = entrance
			break
	to_chat(user, span_notice("You start trying to fit [dragged_atom] into \the [src]..."))
	if(!do_after(user, 1 SECONDS, target = src))
		return
	if(mob_x != user.x - x || mob_y != user.y - y)
		return
	var/atom/currently_dragged = user.pulling
	if(currently_dragged != dragged_atom)
		to_chat(user, span_warning("You stop fitting [dragged_atom] inside \the [src]!"))
		return
	var/success = interior.enter(dragged_atom, entrance_used)
	if(success)
		user.stop_pulling()
		to_chat(user, span_notice("You successfully fit [dragged_atom] inside \the [src]."))
	else
		to_chat(user, span_warning("You fail to fit [dragged_atom] inside \the [src]! It's either too big or vehicle is out of space!"))
//CLAMP procs, unsafe proc, checks are done before calling it
/obj/vehicle/multitile/proc/attach_clamp(obj/item/vehicle_clamp/clamp_item, mob/user)
	user.transferItemToLoc(clamp_item, src)
	clamped = TRUE
	move_delay = VEHICLE_SPEED_STATIC
	next_move = world.time + move_delay
	qdel(clamp_item)
	update_appearance()
	message_admins("[key_name(user)] attached vehicle clamp to [src]")
/obj/vehicle/multitile/proc/detach_clamp(mob/user)
	clamped = FALSE
	move_delay = initial(move_delay)
	var/obj/item/hardpoint/locomotion/locomotion_module
	for(locomotion_module in hardpoints)
		locomotion_module.on_install(src) //we restore speed respective to wheels/treads if any installed
	next_move = world.time + move_delay
	var/obj/item/vehicle_clamp/spawned_clamp = new(get_turf(src))
	if(user)
		spawned_clamp.forceMove(get_turf(user))
		message_admins("[key_name(user)] detached vehicle clamp from \the [src]")
	else
		message_admins("Vehicle clamp was detached from \the [src].")
	update_appearance()