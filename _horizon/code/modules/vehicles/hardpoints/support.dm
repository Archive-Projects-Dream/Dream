/*
 * Support hardpoints, ported from cmss13
 * code/modules/vehicles/hardpoints/support/.dm
 *
 * The cmss13 artillery module's turret-linked view shifting is kept; the ARC
 * antenna keeps its deploy/retract animation. The xeno wallhack sensor from
 * cmss13's minimap system is not ported (no minimap/tacmap in TG); the
 * antenna still gates the ARC sentry auto-targeting.
 */

/obj/item/hardpoint/support
	name = "support hardpoint"
	desc = "Support module, providing passive buffs and active abilities."

	slot = HDPT_SUPPORT
	hdpt_layer = HDPT_LAYER_SUPPORT

	damage_multiplier = 0.075

// M-87F Flare Launcher
/obj/item/hardpoint/support/flare_launcher
	name = "\improper M-87F Flare Launcher"
	desc = "A support module for APCs that shoots flares."
	icon = '_horizon/icons/vehicles/obj/hardpoints/apc.dmi'

	icon_state = "flare_launcher"
	disp_icon = '_horizon/icons/vehicles/obj/apc.dmi'
	disp_icon_state = "flare_launcher"
	activation_sounds = list('sound/items/weapons/gun/general/grenade_launch.ogg')

	damage_multiplier = 0.1

	activatable = TRUE

	max_integrity = 500
	firing_arc = 120

	projectile_type = /obj/projectile/bullet/vehicle/flare

	ammo = new /obj/item/ammo_magazine/hardpoint/flare_launcher
	max_clips = 3

	use_muzzle_flash = TRUE
	angle_muzzleflash = FALSE
	muzzleflash_icon_state = "muzzle_laser"

	muzzle_flash_pos = list(
		"1" = list(-4, -28),
		"2" = list(5, 8),
		"4" = list(-14, -6),
		"8" = list(14, -6)
	)

	scatter = 6
	fire_delay = 3.0 SECONDS

// Artillery Module: long-range view
/obj/item/hardpoint/support/artillery_module
	name = "\improper Artillery Module"
	desc = "Allows the user to look far into the distance."

	icon_state = "artillery"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "artillerymod"

	max_integrity = 250

	activatable = TRUE

	var/is_active = FALSE
	/// How many tiles over the server default view the optics zoom out to
	var/view_buff = 3
	var/view_tile_offset = 7

/// Helper: this server's default view size in tiles
/obj/item/hardpoint/support/artillery_module/proc/default_view_tiles()
	var/list/default_view = getviewsize(world.view)
	return max(default_view[1], default_view[2])

/obj/item/hardpoint/support/artillery_module/handle_fire(atom/target_atom, mob/living/user, params)
	if(!user.client)
		return

	if(is_active)
		// back to the regular crew view (default + 1)
		user.client.change_view(default_view_tiles() + 1)
		user.client.pixel_x = 0
		user.client.pixel_y = 0
		is_active = FALSE
		return

	var/atom/view_holder = owner
	for(var/obj/item/hardpoint/holder/tank_turret/turret in owner.hardpoints)
		view_holder = turret
		break

	user.client.change_view(default_view_tiles() + view_buff)
	is_active = TRUE

	switch(view_holder.dir)
		if(NORTH)
			user.client.pixel_x = 0
			user.client.pixel_y = view_tile_offset * 32
		if(SOUTH)
			user.client.pixel_x = 0
			user.client.pixel_y = -1 * view_tile_offset * 32
		if(EAST)
			user.client.pixel_x = view_tile_offset * 32
			user.client.pixel_y = 0
		if(WEST)
			user.client.pixel_x = -1 * view_tile_offset * 32
			user.client.pixel_y = 0

	return TRUE

/obj/item/hardpoint/support/artillery_module/deactivate()
	if(!is_active)
		return

	var/obj/vehicle/multitile/vehicle_owner = owner
	for(var/seat in vehicle_owner.seats)
		if(!ismob(vehicle_owner.seats[seat]))
			continue
		var/mob/seated_mob = vehicle_owner.seats[seat]
		if(!seated_mob.client)
			continue
		seated_mob.client.change_view(default_view_tiles() + 1)
		seated_mob.client.pixel_x = 0
		seated_mob.client.pixel_y = 0
	is_active = FALSE

/obj/item/hardpoint/support/artillery_module/try_fire(target, user, params)
	if(atom_integrity <= 0)
		to_chat(usr, span_warning("\The [src] is broken!"))
		return NONE

	return handle_fire(target, user, params)

// U-56 Radar Antenna for the ARC
/obj/item/hardpoint/support/arc_antenna
	name = "\improper U-56 Radar Antenna"
	desc = "A heavy-duty antenna built for the ARC."
	icon = '_horizon/icons/vehicles/obj/hardpoints/arc.dmi'

	icon_state = "antenna"
	disp_icon = '_horizon/icons/vehicles/obj/arc.dmi'
	disp_icon_state = "antenna"

	damage_multiplier = 0.1

	max_integrity = 500

	/// How long the antenna deploy/retract animation is, keep accurate to the sprite in the dmi
	var/deploy_animation_time = 1.2 SECONDS
	/// If the antenna is already deploying
	var/deploying = FALSE

/obj/item/hardpoint/support/arc_antenna/proc/deploy_antenna()
	set waitfor = FALSE

	disp_icon_state = ""
	if(owner)
		owner.update_appearance()
		var/obj/dummy_obj = new()
		dummy_obj.icon = '_horizon/icons/vehicles/obj/arc.dmi'
		dummy_obj.icon_state = "antenna_cover_0"
		dummy_obj.dir = owner.dir
		dummy_obj.vis_flags = VIS_INHERIT_ID | VIS_INHERIT_LAYER | VIS_INHERIT_PLANE
		owner.vis_contents += dummy_obj
		flick("antenna_extending", dummy_obj)
		sleep(deploy_animation_time)
		qdel(dummy_obj)
	disp_icon_state = initial(disp_icon_state)

/obj/item/hardpoint/support/arc_antenna/proc/retract_antenna()
	set waitfor = FALSE

	disp_icon_state = ""
	if(owner)
		owner.update_appearance()
		var/obj/dummy_obj = new()
		dummy_obj.icon = '_horizon/icons/vehicles/obj/arc.dmi'
		dummy_obj.icon_state = "antenna_cover_0"
		dummy_obj.dir = owner.dir
		dummy_obj.vis_flags = VIS_INHERIT_ID | VIS_INHERIT_LAYER | VIS_INHERIT_PLANE
		owner.vis_contents += dummy_obj
		flick("antenna_retracting", dummy_obj)
		sleep(deploy_animation_time)
		qdel(dummy_obj)
	disp_icon_state = initial(disp_icon_state)

/obj/item/hardpoint/support/arc_antenna/get_icon_image(x_offset, y_offset, new_dir)
	var/is_broken = atom_integrity <= 0
	var/antenna_extended = FALSE
	if(istype(owner, /obj/vehicle/multitile/arc))
		var/obj/vehicle/multitile/arc/arc_owner = owner
		antenna_extended = arc_owner.antenna_deployed

	var/image/antenna_img = image(icon = disp_icon, icon_state = "[disp_icon_state]_[antenna_extended ? "extended" : "cover"]_[is_broken ? "1" : "0"]", pixel_x = x_offset, pixel_y = y_offset, dir = new_dir)
	switch(floor((atom_integrity / max_integrity) * 100))
		if(0)
			antenna_img.color = "#888888"
		if(1 to 20)
			antenna_img.color = "#4e4e4e"
		if(21 to 40)
			antenna_img.color = "#6e6e6e"
		if(41 to 60)
			antenna_img.color = "#8b8b8b"
		if(61 to 80)
			antenna_img.color = "#bebebe"
		else
			antenna_img.color = null
	return antenna_img

/obj/item/hardpoint/support/arc_antenna/can_be_removed(mob/remover)
	var/obj/vehicle/multitile/arc/arc_owner = owner
	if(!istype(arc_owner))
		return TRUE

	if(arc_owner.antenna_deployed)
		to_chat(remover, span_warning("[src] cannot be removed from [owner] while it is deployed."))
		return FALSE

	return ..()

/obj/item/hardpoint/support/arc_antenna/on_destroy()
	var/obj/vehicle/multitile/arc/arc_owner = owner
	if(!istype(arc_owner))
		return

	if(arc_owner.antenna_deployed)
		retract_antenna()
		addtimer(CALLBACK(arc_owner, TYPE_PROC_REF(/obj/vehicle/multitile/arc, finish_antenna_retract)), deploy_animation_time)

// Overdrive Enhancer
/obj/item/hardpoint/support/overdrive_enhancer
	name = "\improper Overdrive Enhancer"
	desc = "Increases the movement speed of the vehicle it's attached to."

	icon_state = "odrive_enhancer"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "odrive_enhancer"

	max_integrity = 250

	// 20% movespeed increase. Remember that movespeed is given in delay
	buff_multipliers = list(
		"move" = 0.8
	)

	px_offsets = list(
		"1" = list(0, 0),
		"2" = list(0, 0),
		"4" = list(0, 32),
		"8" = list(0, 0)
	)

/obj/item/hardpoint/support/overdrive_enhancer/apply_buff(obj/vehicle/multitile/vehicle)
	if(buff_applied)
		return
	for(var/obj/item/hardpoint/locomotion/locomotion_module in vehicle.hardpoints)
		if(locomotion_module.atom_integrity > 0)
			vehicle.misc_multipliers["move"] *= LAZYACCESS(buff_multipliers, "move")
			buff_applied = TRUE
			break

/obj/item/hardpoint/support/overdrive_enhancer/remove_buff(obj/vehicle/multitile/vehicle)
	if(!buff_applied)
		return
	vehicle.misc_multipliers["move"] /= LAZYACCESS(buff_multipliers, "move")
	buff_applied = FALSE

// Integrated Weapons Sensor Array
/obj/item/hardpoint/support/weapons_sensor
	name = "\improper Integrated Weapons Sensor Array"
	desc = "Improves the accuracy and fire rate of all onboard weapons."

	icon_state = "warray"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "warray"

	max_integrity = 250

	buff_multipliers = list(
		"cooldown" = 0.67,
		"accuracy" = 1.67
	)
