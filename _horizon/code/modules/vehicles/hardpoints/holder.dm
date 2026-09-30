/*
 * Holder hardpoints (the tank turret), ported from cmss13
 * code/modules/vehicles/hardpoints/holder/.dm
 *
 * The turret's built-in smoke screen launcher is kept; the cmss13
 * powerloader interaction is not ported (no powerloaders in TG).
 */

/obj/item/hardpoint/holder
	name = "holder hardpoint"
	desc = "Holder for other hardpoints."

	// List of types of hardpoints that this hardpoint can hold
	var/list/accepted_hardpoints

	// List of held hardpoints
	var/list/hardpoints

/obj/item/hardpoint/holder/Destroy()
	QDEL_LAZYLIST(hardpoints)

	. = ..()

/obj/item/hardpoint/holder/update_appearance(updates)
	. = ..()
	cut_overlays()
	for(var/obj/item/hardpoint/held_hardpoint in hardpoints)
		var/image/held_image = held_hardpoint.get_hardpoint_image()
		add_overlay(held_image)

/obj/item/hardpoint/holder/examine(mob/user)
	. = ..()
	if(atom_integrity <= 0)
		. += "It's busted!"
	else
		. += "It's at [round(get_integrity_percent(), 1)]% integrity!"
	for(var/obj/item/hardpoint/held_hardpoint in hardpoints)
		. += "There is \a [held_hardpoint] module installed on [src]."
		. += held_hardpoint.examine(user)

/obj/item/hardpoint/holder/get_tgui_info()
	var/list/data = list()

	for(var/obj/item/hardpoint/held_hardpoint in hardpoints)
		data += list(held_hardpoint.get_tgui_info())

	return data

/obj/item/hardpoint/holder/take_damage(damage)
	..()

	for(var/obj/item/hardpoint/held_hardpoint in hardpoints)
		held_hardpoint.take_damage(damage)

/obj/item/hardpoint/holder/on_install(obj/vehicle/multitile/vehicle)
	..()
	if(!vehicle) //in loose holder
		return
	for(var/obj/item/hardpoint/held_hardpoint in hardpoints)
		held_hardpoint.owner = vehicle
		held_hardpoint.on_install(vehicle)

/obj/item/hardpoint/holder/on_uninstall(obj/vehicle/multitile/vehicle)
	if(!vehicle) //in loose holder
		return
	for(var/obj/item/hardpoint/held_hardpoint in hardpoints)
		held_hardpoint.on_uninstall(vehicle)
		held_hardpoint.owner = null
	..()

/obj/item/hardpoint/holder/proc/can_install(obj/item/hardpoint/new_hardpoint)
	// Can only have 1 hardpoint of each slot type
	if(LAZYLEN(hardpoints))
		for(var/obj/item/hardpoint/held_hardpoint in hardpoints)
			if(held_hardpoint.slot == new_hardpoint.slot)
				return FALSE
	// Must be accepted by the holder
	return (new_hardpoint.type in accepted_hardpoints)

/obj/item/hardpoint/holder/proc/install(obj/item/hardpoint/new_hardpoint, mob/user)
	if(atom_integrity <= 0)
		to_chat(user, span_warning("All the mounting points on \the [src] are broken!"))
		return

	user.visible_message(span_notice("[user] begins installing \the [new_hardpoint] on the [new_hardpoint.slot] hardpoint slot of \the [src]."),
		span_notice("You begin installing \the [new_hardpoint] on the [new_hardpoint.slot] hardpoint slot of \the [src]."))
	if(!do_after(user, 12 SECONDS, target = src))
		user.visible_message(span_warning("[user] stops installing \the [new_hardpoint] on \the [src]."), span_warning("You stop installing \the [new_hardpoint] on \the [src]."))
		return

	user.transferItemToLoc(new_hardpoint, src)
	add_hardpoint(new_hardpoint)

	update_appearance()

/obj/item/hardpoint/holder/proc/uninstall(obj/item/hardpoint/old_hardpoint, mob/user)
	if(!(old_hardpoint in hardpoints))
		return

	user.visible_message(span_notice("[user] begins removing \the [old_hardpoint] from the [old_hardpoint.slot] hardpoint slot of \the [src]."),
		span_notice("You begin removing \the [old_hardpoint] from the [old_hardpoint.slot] hardpoint slot of \the [src]."))
	if(!do_after(user, 12 SECONDS, target = src))
		user.visible_message(span_warning("[user] stops removing \the [old_hardpoint] from \the [src]."), span_warning("You stop removing \the [old_hardpoint] from \the [src]."))
		return

	remove_hardpoint(old_hardpoint, get_turf(user))

	update_appearance()

/obj/item/hardpoint/holder/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	if(attacking_item.tool_behaviour == TOOL_CROWBAR)
		var/chosen_hp = tgui_input_list(user, "Select a hardpoint to remove", "Vehicle Hardpoint Removal", (hardpoints + "Cancel"))
		if(chosen_hp == "Cancel")
			return

		var/obj/item/hardpoint/old_hardpoint = chosen_hp

		uninstall(old_hardpoint, user)
		return

	if(istype(attacking_item, /obj/item/hardpoint))
		var/obj/item/hardpoint/new_hardpoint = attacking_item
		if(!(new_hardpoint.type in accepted_hardpoints))
			to_chat(user, span_warning("You don't know what to do with \the [attacking_item] on \the [src]."))
			return

		install(new_hardpoint, user)
		return

	return ..()

/obj/item/hardpoint/holder/proc/add_hardpoint(obj/item/hardpoint/new_hardpoint)
	new_hardpoint.owner = owner
	new_hardpoint.forceMove(src)
	LAZYADD(hardpoints, new_hardpoint)

	new_hardpoint.on_install(owner)
	new_hardpoint.rotate(turning_angle(new_hardpoint.dir, dir))

/obj/item/hardpoint/holder/proc/remove_hardpoint(obj/item/hardpoint/old_hardpoint, turf/uninstall_to)
	if(!hardpoints)
		return
	old_hardpoint.forceMove(uninstall_to ? uninstall_to : get_turf(src))

	old_hardpoint.on_uninstall(owner)
	old_hardpoint.reset_rotation()
	hardpoints -= old_hardpoint
	old_hardpoint.owner = null

	if(old_hardpoint.atom_integrity <= 0)
		qdel(old_hardpoint)

//Returns all activatable hardpoints
/obj/item/hardpoint/holder/proc/get_activatable_hardpoints(seat)
	var/list/hps = list()
	for(var/obj/item/hardpoint/held_hardpoint in hardpoints)
		if(!held_hardpoint.is_activatable() || seat && seat != held_hardpoint.allowed_seat)
			continue
		hps += held_hardpoint
	return hps

//Returns hardpoints that use ammunition
/obj/item/hardpoint/holder/proc/get_hardpoints_with_ammo(seat)
	var/list/hps = list()
	for(var/obj/item/hardpoint/held_hardpoint in hardpoints)
		if(!held_hardpoint.ammo || seat && seat != held_hardpoint.allowed_seat)
			continue
		hps += held_hardpoint
	return hps

/obj/item/hardpoint/holder/proc/find_hardpoint(hardpoint_name)
	for(var/obj/item/hardpoint/held_hardpoint in hardpoints)
		if(held_hardpoint.name == hardpoint_name)
			return held_hardpoint
	return null

// Modified to return a list of all images tied to the holder
/obj/item/hardpoint/holder/get_hardpoint_image()
	var/image/root_image = ..()
	var/list/images = list(root_image)
	for(var/obj/item/hardpoint/held_hardpoint in hardpoints)
		var/image/held_image = held_hardpoint.get_hardpoint_image()
		if(LAZYLEN(px_offsets) && loc && held_image)
			held_image.pixel_x += px_offsets["[loc.dir]"][1]
			held_image.pixel_y += px_offsets["[loc.dir]"][2]
		images += held_image
	return images

/obj/item/hardpoint/holder/rotate(deg)
	for(var/obj/item/hardpoint/held_hardpoint in hardpoints)
		held_hardpoint.rotate(deg)

	..()

/*
 * The tank turret itself
 */
/obj/item/hardpoint/holder/tank_turret
	name = "\improper M34A2-A Multipurpose Turret"
	desc = "The centerpiece of the tank. Designed to support quick installation and deinstallation of various tank weapon modules. Has inbuilt smoke screen deployment system."

	icon = '_horizon/icons/vehicles/obj/tank.dmi'
	icon_state = "tank_turret_0"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "tank_turret"
	activation_sounds = list('_horizon/sounds/vehicles/weapons/smokelauncher_fire.ogg')
	pixel_x = -48
	pixel_y = -48

	density = TRUE //come on, it's huge

	activatable = TRUE

	projectile_type = /obj/projectile/bullet/vehicle/smoke

	ammo = new /obj/item/ammo_magazine/hardpoint/turret_smoke
	max_clips = 2
	use_muzzle_flash = FALSE

	w_class = WEIGHT_CLASS_GIGANTIC
	anchored = TRUE

	allowed_seat = VEHICLE_DRIVER

	slot = HDPT_TURRET

	// big beefy chonk of metal
	max_integrity = 450
	damage_multiplier = 0.05

	accepted_hardpoints = list(
		// primaries
		/obj/item/hardpoint/primary/flamer,
		/obj/item/hardpoint/primary/cannon,
		/obj/item/hardpoint/primary/minigun,
		/obj/item/hardpoint/primary/autocannon,
		// secondaries
		/obj/item/hardpoint/secondary/small_flamer,
		/obj/item/hardpoint/secondary/towlauncher,
		/obj/item/hardpoint/secondary/m56cupola,
		/obj/item/hardpoint/secondary/grenade_launcher
	)

	hdpt_layer = HDPT_LAYER_TURRET
	px_offsets = list(
		"1" = list(0, -10),
		"2" = list(0, 10),
		"4" = list(-10, 0),
		"8" = list(10, 0)
	)

	var/gyro = FALSE

	// How long the windup is before the turret rotates
	var/rotation_windup = 15
	// Used during the windup
	var/rotating = FALSE

	scatter = 4
	gun_firemode = HARDPOINT_FIREMODE_BURSTFIRE
	gun_firemode_list = list(
		HARDPOINT_FIREMODE_BURSTFIRE,
	)
	burst_amount = 2
	burst_delay = 1.0 SECONDS
	extra_delay = 13.0 SECONDS

// no picking this big beast up
/obj/item/hardpoint/holder/tank_turret/attack_hand(mob/user, list/modifiers)
	return

/obj/item/hardpoint/holder/tank_turret/get_tgui_info()
	var/list/data = list()

	data += list(list( // turret smokescreen data
		"name" = "M34A2-A Turret Smoke Screen",
		"health" = atom_integrity <= 0 ? null : floor(get_integrity_percent()),
		"uses_ammo" = TRUE,
		"current_rounds" = ammo.current_rounds / 2,
		"max_rounds"= ammo.max_rounds / 2,
		"mags" = LAZYLEN(backup_clips),
		"max_mags" = max_clips,
	))

	for(var/obj/item/hardpoint/held_hardpoint in hardpoints)
		data += list(held_hardpoint.get_tgui_info())

	return data

//gyro ON locks the turret in one direction, OFF will make turret turning when tank turns
/obj/item/hardpoint/holder/tank_turret/proc/toggle_gyro(mob/user)
	if(atom_integrity <= 0)
		to_chat(user, span_warning("\The [src]'s stabilization systems are busted!"))
		return

	gyro = !gyro
	to_chat(user, span_notice("You toggle \the [src]'s gyroscopic stabilizer [gyro ? "ON" :"OFF"]."))

/obj/item/hardpoint/holder/tank_turret/proc/user_rotation(mob/user, deg)
	// no rotating a broken turret
	if(atom_integrity <= 0)
		return

	if(rotating)
		return

	rotating = TRUE
	to_chat(user, span_notice("You begin rotating the turret towards the [dir2text(turn(dir,deg))]."))

	if(!do_after(user, rotation_windup, target = src))
		rotating = FALSE
		return
	rotating = FALSE

	rotate(deg, TRUE)

/obj/item/hardpoint/holder/tank_turret/rotate(deg, override_gyro = FALSE)
	if(gyro && !override_gyro)
		return

	..(deg)

	var/obj/vehicle/multitile/tank/tank_owner = owner
	var/obj/item/hardpoint/support/artillery_module/artillery_module
	for(var/obj/item/hardpoint/support/artillery_module/installed_artillery in tank_owner.hardpoints)
		artillery_module = installed_artillery
	if(artillery_module && artillery_module.is_active)
		var/mob/seated_gunner = tank_owner.seats[VEHICLE_GUNNER]
		if(seated_gunner && seated_gunner.client)
			seated_gunner.client.change_view(artillery_module.view_buff)

			switch(dir)
				if(NORTH)
					seated_gunner.client.pixel_x = 0
					seated_gunner.client.pixel_y = artillery_module.view_tile_offset * 32
				if(SOUTH)
					seated_gunner.client.pixel_x = 0
					seated_gunner.client.pixel_y = -1 * artillery_module.view_tile_offset * 32
				if(EAST)
					seated_gunner.client.pixel_x = artillery_module.view_tile_offset * 32
					seated_gunner.client.pixel_y = 0
				if(WEST)
					seated_gunner.client.pixel_x = -1 * artillery_module.view_tile_offset * 32
					seated_gunner.client.pixel_y = 0

// The turret smoke launchers alternate between the left and right launch tube
/obj/item/hardpoint/holder/tank_turret/try_fire(atom/target_atom, mob/living/user, params)
	var/turf/left_turf
	var/turf/right_turf
	switch(owner.dir)
		if(NORTH)
			left_turf = locate(owner.x - 2, owner.y + 4, owner.z)
			right_turf = locate(owner.x + 2, owner.y + 4, owner.z)
		if(SOUTH)
			left_turf = locate(owner.x + 2, owner.y - 4, owner.z)
			right_turf = locate(owner.x - 2, owner.y - 4, owner.z)
		if(EAST)
			left_turf = locate(owner.x + 4, owner.y + 2, owner.z)
			right_turf = locate(owner.x + 4, owner.y - 2, owner.z)
		else
			left_turf = locate(owner.x - 4, owner.y + 2, owner.z)
			right_turf = locate(owner.x - 4, owner.y - 2, owner.z)

	if(shots_fired)
		target_atom = right_turf
	else
		target_atom = left_turf

	return ..()
