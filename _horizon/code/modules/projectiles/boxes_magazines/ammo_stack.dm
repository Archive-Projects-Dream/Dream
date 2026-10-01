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

/// Override of upstream's /obj/item/ammo_box/update_appearance() to call
/// check_for_del() so empty ammo stacks are auto-deleted.
/obj/item/ammo_box/magazine/ammo_stack/update_appearance()
	. = ..()
	check_for_del()

/obj/item/ammo_box/magazine/ammo_stack/proc/check_for_del()
	. = FALSE
	if((ammo_count(TRUE) <= 0) && !QDELETED(src))
		// [HORIZON-FIX] Never delete casings stranded in our contents (they
		// should always live in stored_ammo, but any bug that leaves one
		// inside a self-deleting stack would silently eat it) - dump
		// everything out before we go.
		var/atom/drop_loc = drop_location()
		for(var/atom/movable/stray as anything in contents.Copy())
			if(drop_loc)
				stray.forceMove(drop_loc)
		qdel(src)
		return TRUE

/obj/item/ammo_box/magazine/ammo_stack/proc/update_icon_world()
	cut_overlays()
	icon_state = ""
	for(var/casing in stored_ammo)
		// [HORIZON-FIX] spent casings use the non-live sprite so players can
		// tell live and empty rounds apart in a stack (typepaths read as
		// initial var values = null projectile = spent).
		var/obj/item/ammo_casing/casing_ref = casing
		var/state = "[world_icon_state][casing_ref.loaded_projectile ? "-live" : ""]"
		var/image/bullet = image(world_icon, src, state)
		bullet.pixel_x = rand(-12, 12)
		bullet.pixel_y = rand(-12, 12)
		bullet.transform = bullet.transform.Turn(rand(0, 360))
		add_overlay(bullet)
	return UPDATE_ICON_STATE | UPDATE_OVERLAYS

// ammo casing attackby code here
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
	// [HORIZON-FIX] Spent casings of the same type stack together now (and
	// mix with live ones) - the stack's world sprite shows which is which.
	// (The old check rejected anything involving an empty casing, so
	// shot-up brass could never be picked back up.)
	var/obj/item/ammo_box/magazine/ammo_stack = new stack_type(drop_location())
	if(!ammo_stack.stored_ammo)
		ammo_stack.stored_ammo = list()
	// [HORIZON-FIX] give_round() FIRST, transferItemToLoc() only after it
	// accepted the casing. The old order moved casings into the stack's
	// contents BEFORE give_round() ran; when give_round() rejected one
	// (e.g. a null-caliber casing like the old a357) it sat in the stack's
	// contents but not in stored_ammo, the stack counted as empty and
	// check_for_del() qdel'd it - deleting the casings with it ("bullets
	// disappear when you stack them").
	if(!ammo_stack.give_round(src))
		qdel(ammo_stack)
		to_chat(user, span_warning("[src] doesn't fit into [stack_type]!"))
		return
	if(!user.transferItemToLoc(ammo_casing, ammo_stack, silent = TRUE))
		// couldn't unequip the held casing (nodrop etc) - put the floor
		// casing back down. forceMove() out of the stack fires Exited ->
		// remove_from_stored_ammo() -> update_appearance() -> check_for_del()
		// which cleanly self-deletes the now-empty stack.
		src.forceMove(ammo_stack.drop_location())
		return
	if(!ammo_stack.give_round(ammo_casing))
		ammo_casing.forceMove(ammo_stack.drop_location())
	if(QDELETED(ammo_stack))
		return
	user.put_in_hands(ammo_stack)
	ammo_stack.update_appearance()
	to_chat(user, span_notice("[src] has been stacked with [ammo_casing]."))
