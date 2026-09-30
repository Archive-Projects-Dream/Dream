/*
 * Multitile vehicle hardpoint management, ported from cmss13 code/modules/vehicles/multitile/multitile_hardpoints.dm
 *
 * Adapted for Horizon-Dream: powerloader clamps and skill checks are not ported;
 * heavy modules (turrets) are simply carried by hand like the rest.
 */

// Returns all hardpoints that are attached to the vehicle, including ones held by holder hardpoints (e.g. turrets)
/obj/vehicle/multitile/proc/get_hardpoints_copy()
	var/list/all_hardpoints = hardpoints.Copy()
	for(var/obj/item/hardpoint/holder/holder_module in all_hardpoints)
		if(!holder_module.hardpoints)
			continue
		all_hardpoints += holder_module.hardpoints.Copy()

	return all_hardpoints

//Returns all activatable hardpoints
/obj/vehicle/multitile/proc/get_activatable_hardpoints(seat)
	var/list/hps = list()
	for(var/obj/item/hardpoint/installed_hardpoint in hardpoints)
		if(istype(installed_hardpoint, /obj/item/hardpoint/holder))
			var/obj/item/hardpoint/holder/holder_module = installed_hardpoint
			if(holder_module.hardpoints)
				hps += holder_module.get_activatable_hardpoints(seat)
		if(!installed_hardpoint.is_activatable() || seat && seat != installed_hardpoint.allowed_seat)
			continue
		hps += installed_hardpoint
	return hps

//Returns hardpoints that use ammunition
/obj/vehicle/multitile/proc/get_hardpoints_with_ammo(seat)
	var/list/hps = list()
	for(var/obj/item/hardpoint/installed_hardpoint in hardpoints)
		if(istype(installed_hardpoint, /obj/item/hardpoint/holder))
			var/obj/item/hardpoint/holder/holder_module = installed_hardpoint
			if(holder_module.hardpoints)
				hps += holder_module.get_hardpoints_with_ammo(seat)
		if(!installed_hardpoint.ammo || seat && seat != installed_hardpoint.allowed_seat)
			continue
		hps += installed_hardpoint
	return hps

// Returns a hardpoint by its name
/obj/vehicle/multitile/proc/find_hardpoint(hardpoint_name)
	for(var/obj/item/hardpoint/installed_hardpoint in hardpoints)
		if(istype(installed_hardpoint, /obj/item/hardpoint/holder))
			var/obj/item/hardpoint/holder/holder_module = installed_hardpoint

			var/obj/item/hardpoint/nested_hp = holder_module.find_hardpoint(hardpoint_name)
			if(nested_hp)
				return nested_hp

		if(installed_hardpoint.name == hardpoint_name)
			return installed_hardpoint
	return null

//What to do if all of the installed modules have been broken
/obj/vehicle/multitile/proc/handle_all_modules_broken()
	return

/obj/vehicle/multitile/proc/deactivate_all_hardpoints()
	var/list/hps = get_activatable_hardpoints()
	for(var/obj/item/hardpoint/installed_hardpoint in hps)
		installed_hardpoint.deactivate()

/obj/vehicle/multitile/proc/remove_all_players()
	return

//Putting on hardpoints
//Similar to repairing stuff, down to the time delay
/obj/vehicle/multitile/proc/install_hardpoint(obj/item/new_hardpoint_item, mob/user)
	var/obj/item/hardpoint/new_hardpoint = new_hardpoint_item

	for(var/obj/item/hardpoint/holder/holder_module in hardpoints)
		// Attempt to install on holder hardpoints first
		if(holder_module.can_install(new_hardpoint))
			holder_module.install(new_hardpoint, user)
			update_appearance()
			return

	if(atom_integrity < max_integrity * 0.75)
		to_chat(user, span_warning("All the mounting points on \the [src] are broken!"))
		return

	if(LAZYLEN(hardpoints))
		for(var/obj/item/hardpoint/installed_hardpoint in hardpoints)
			if(new_hardpoint.slot == installed_hardpoint.slot)
				to_chat(user, span_warning("There is already something installed there!"))
				return

	if(!(new_hardpoint.type in hardpoints_allowed))
		to_chat(user, span_warning("You don't know what to do with [new_hardpoint] on \the [src]."))
		return

	user.visible_message(span_notice("[user] begins installing \the [new_hardpoint] on the [new_hardpoint.slot] hardpoint slot of \the [src]."),
		span_notice("You begin installing \the [new_hardpoint] on the [new_hardpoint.slot] hardpoint slot of \the [src]."))

	var/num_delays = 1

	switch(new_hardpoint.slot)
		if(HDPT_PRIMARY)
			num_delays = 5
		if(HDPT_SECONDARY)
			num_delays = 3
		if(HDPT_SUPPORT)
			num_delays = 2
		if(HDPT_ARMOR)
			num_delays = 10
		if(HDPT_TREADS, HDPT_WHEELS)
			num_delays = 7

	if(!do_after(user, 3 SECONDS * num_delays, target = src, show_progress = TRUE))
		user.visible_message(span_warning("[user] stops installing \the [new_hardpoint] on \the [src]."), span_warning("You stop installing \the [new_hardpoint] on \the [src]."))
		return

	//check to prevent putting two modules on same slot
	for(var/obj/item/hardpoint/installed_hardpoint in hardpoints)
		if(new_hardpoint.slot == installed_hardpoint.slot)
			to_chat(user, span_warning("There is already something installed there!"))
			return

	user.visible_message(span_notice("[user] installs \the [new_hardpoint] on \the [src]."), span_notice("You install \the [new_hardpoint] on \the [src]."))

	user.transferItemToLoc(new_hardpoint, src)

	add_hardpoint(new_hardpoint, user)

//User-orientated proc for taking of hardpoints
//Again, similar to the above ones
/obj/vehicle/multitile/proc/uninstall_hardpoint(obj/item/tool_item, mob/user)
	var/list/hps = list()
	for(var/obj/item/hardpoint/installed_hardpoint in get_hardpoints_copy())
		// Special pre-installed hardpoints (firing port weapons) can't be removed
		if(istype(installed_hardpoint, /obj/item/hardpoint/special))
			continue
		hps += installed_hardpoint

	var/chosen_hp = tgui_input_list(user, "Select a hardpoint to remove", "Hardpoint Removal", (hps + "Cancel"))
	if(chosen_hp == "Cancel" || !chosen_hp || (get_dist(src, user) > 2)) //get_dist uses 2 because the vehicle is 3x3
		return

	var/obj/item/hardpoint/old_hardpoint = chosen_hp

	if(!old_hardpoint)
		to_chat(user, span_warning("There is nothing installed there."))
		return

	if(!old_hardpoint.can_be_removed(user))
		return
	// It's in a holder
	if(!(old_hardpoint in hardpoints))
		for(var/obj/item/hardpoint/holder/holder_module in hardpoints)
			if(old_hardpoint in holder_module.hardpoints)
				holder_module.uninstall(old_hardpoint, user)
				update_appearance()
				return

	user.visible_message(span_notice("[user] begins removing [old_hardpoint] on the [old_hardpoint.slot] hardpoint slot on \the [src]."),
		span_notice("You begin removing [old_hardpoint] on the [old_hardpoint.slot] hardpoint slot on \the [src]."))

	var/num_delays = 1

	switch(old_hardpoint.slot)
		if(HDPT_PRIMARY)
			num_delays = 5
		if(HDPT_SECONDARY)
			num_delays = 3
		if(HDPT_SUPPORT)
			num_delays = 2
		if(HDPT_ARMOR)
			num_delays = 10
		if(HDPT_TREADS)
			num_delays = 7

	if(!do_after(user, 3 SECONDS * num_delays, target = old_hardpoint, show_progress = TRUE))
		user.visible_message(span_warning("[user] stops removing \the [old_hardpoint] on \the [src]."), span_warning("You stop removing \the [old_hardpoint] on \the [src]."))
		return

	user.visible_message(span_notice("[user] removes \the [old_hardpoint] on \the [src]."), span_notice("You remove \the [old_hardpoint] on \the [src]."))

	remove_hardpoint(old_hardpoint, user)

	if(QDELETED(old_hardpoint))
		return

	if(old_hardpoint.slot == HDPT_TREADS && clamped)
		detach_clamp(user)

//General proc for putting on hardpoints
//ALWAYS CALL THIS WHEN ATTACHING HARDPOINTS
/obj/vehicle/multitile/proc/add_hardpoint(obj/item/hardpoint/new_hardpoint, mob/user)
	new_hardpoint.owner = src
	new_hardpoint.forceMove(src)
	hardpoints += new_hardpoint

	new_hardpoint.on_install(src)
	new_hardpoint.rotate(turning_angle(new_hardpoint.dir, dir))

	update_appearance()

//General proc for taking off hardpoints
//ALWAYS CALL THIS WHEN REMOVING HARDPOINTS
/obj/vehicle/multitile/proc/remove_hardpoint(obj/item/hardpoint/old_hardpoint, mob/user)
	if(!(old_hardpoint in hardpoints))
		return

	if(user)
		old_hardpoint.forceMove(get_turf(user))
	else
		old_hardpoint.forceMove(get_turf(src))

	old_hardpoint.on_uninstall(src)
	old_hardpoint.reset_rotation()
	hardpoints -= old_hardpoint
	old_hardpoint.owner = null

	if(old_hardpoint.atom_integrity <= 0 && !old_hardpoint.gc_destroyed) // Make sure it's not already being deleted.
		visible_message(span_warning("\The [src] disintegrates into useless pile of scrap under the damage it suffered."))
		qdel(old_hardpoint)

	update_appearance()
