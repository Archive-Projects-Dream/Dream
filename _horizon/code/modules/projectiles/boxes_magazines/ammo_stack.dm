//The ammo stack object itself
/obj/item/ammo_box/magazine/ammo_stack
	name = "ammo stack"
	desc = "A stack of ammo."
	icon = '_horizon/icons/obj/items/ammo/ammo_stacks.dmi'
	icon_state = "c9mm"
	base_icon_state = "c9mm"
	item_flags = NO_PIXEL_RANDOM_DROP | NO_ANGLE_RANDOM_DROP
	multiple_sprites = AMMO_BOX_ONE_SPRITE
	multiload = FALSE
	// Upstream renamed multiload to ammo_box_multiload. Set it to NONE
	// so clicking an ammo_stack with another ammo_stack/box only loads
	// ONE bullet at a time, matching the legacy modular_septic behaviour.
	ammo_box_multiload = AMMO_BOX_MULTILOAD_NONE
	start_empty = TRUE
	max_ammo = 12
	carry_weight = 0
	/// World icon for this stack
	var/world_icon = '_horizon/icons/obj/items/ammo/casings_world.dmi'
	/// World icon state
	var/world_icon_state = "s-casing"

/obj/item/ammo_box/magazine/ammo_stack/Initialize(mapload)
	. = ..()
	if(world_icon)
		AddElement(/datum/element/world_icon, PROC_REF(update_icon_world))

/obj/item/ammo_box/magazine/ammo_stack/update_icon(updates)
	icon = initial(icon)
	cut_overlays()
	return ..()

/obj/item/ammo_box/magazine/ammo_stack/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]-[ammo_count(TRUE)]"

/obj/item/ammo_box/magazine/ammo_stack/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	var/loc_before_del = loc
	while(LAZYLEN(stored_ammo))
		var/obj/item/ammo = get_round(FALSE)
		ammo.forceMove(loc_before_del)
		ammo.undo_messy()
		ammo.do_messy(duration = 2)
	check_for_del()

/obj/item/ammo_box/magazine/ammo_stack/empty_magazine()
	. = ..()
	check_for_del()

// EFN parity: upstream's attack_self() ended with update_ammo_count(),
// whose check_for_del() chain deletes the husk once you pull the last
// round out of a stack (right in your hand). Dream has no
// update_ammo_count - run the check synchronously right after the
// parent proc for the same instant feedback.
/obj/item/ammo_box/magazine/ammo_stack/attack_self(mob/user)
	. = ..()
	check_for_del()

// EFN parity (deferred): EFN's core chained every casing exit into
// update_ammo_count() -> check_for_del(), so a stack drained dry by
// ANY route (try_load transfer into another box/mag, revolver speed
// loading...) self-deleted. Dream routes those transfers through
// item_interaction()/try_load(), and its Exited() ->
// remove_from_stored_ammo() hook fires synchronously *inside*
// give_round()/forceMove() - a qdel there would null stored_ammo
// mid-iteration and runtime the transfer loop. So we keep the EFN
// invariant but defer the check to the end of the tick. The QDELETED
// guard inside check_for_del() makes the timer safe if the stack is
// already gone (or got refilled) by the time it fires.
/obj/item/ammo_box/magazine/ammo_stack/remove_from_stored_ammo(atom/movable/gone)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(check_for_del)), 0)

// Dream adaptation: Dream's core /obj/item/ammo_box/Destroy() qdels every
// casing still in stored_ammo, and anything loose in contents would be
// stranded in nullspace inside the deleted stack. Nevado's core has no
// such Destroy. Dump everything we still hold onto the floor first so
// casings can never vanish without a trace.
/obj/item/ammo_box/magazine/ammo_stack/Destroy(force)
	var/atom/dump_loc = drop_location()
	if(dump_loc)
		for(var/atom/movable/stray as anything in contents.Copy())
			stray.forceMove(dump_loc)
	return ..()

/obj/item/ammo_box/magazine/ammo_stack/proc/check_for_del()
	. = FALSE
	if((ammo_count(TRUE) <= 0) && !QDELETED(src))
		qdel(src)
		return TRUE

/obj/item/ammo_box/magazine/ammo_stack/proc/update_icon_world()
	cut_overlays()
	icon_state = ""
	for(var/casing in stored_ammo)
		var/obj/item/ammo_casing/casing_ref = casing
		// maploaded /loaded stacks store typepaths (lazyload) - those are
		// live by definition; runtime-picked casings show a spent sprite
		// when their projectile is gone so players can tell brass from ammo.
		var/state = "[world_icon_state][(ispath(casing) || casing_ref.loaded_projectile) ? "-live" : ""]"
		var/image/bullet = image(world_icon, src, state)
		bullet.pixel_x = rand(-12, 12)
		bullet.pixel_y = rand(-12, 12)
		bullet.transform = bullet.transform.Turn(rand(0, 360))
		add_overlay(bullet)
	return UPDATE_ICON_STATE | UPDATE_OVERLAYS

// ammo casing attackby code here - faithful EFN (modular_septic) port:
// pick a floor casing up with another casing of the same type, they form
// a stack right in your hand. Spent casings are NOT stackable this way
// (grab them with a box/stack instead).
/obj/item/ammo_casing
	/// What this casing can be stacked into
	var/obj/item/ammo_box/magazine/stack_type

/obj/item/ammo_casing/attackby(obj/item/attacking_item, mob/user, params)
	. = ..()
	if(!istype(attacking_item, /obj/item/ammo_casing))
		return
	var/obj/item/ammo_casing/ammo_casing = attacking_item
	if(!ammo_casing.stack_type)
		to_chat(user, span_warning("[ammo_casing] can't be stacked."))
		return
	if(!stack_type)
		to_chat(user, span_warning("[src] can't be stacked."))
		return
	if(caliber != ammo_casing.caliber)
		to_chat(user, span_warning("I can't stack different calibers."))
		return
	if(stack_type != ammo_casing.stack_type)
		to_chat(user, span_warning("I can't stack [ammo_casing] with [src]."))
		return
	if(!loaded_projectile || !ammo_casing.loaded_projectile)
		to_chat(user, span_warning("I can't stack empty casings."))
		return
	var/obj/item/ammo_box/magazine/ammo_stack = new stack_type(drop_location())
	user.transferItemToLoc(src, ammo_stack, silent = TRUE)
	ammo_stack.give_round(src)
	user.transferItemToLoc(ammo_casing, ammo_stack, silent = TRUE)
	ammo_stack.give_round(ammo_casing)
	user.put_in_hands(ammo_stack)
	ammo_stack.update_appearance()
	to_chat(user, span_notice("[src] has been stacked with [ammo_casing]."))
