/*
 * Hardpoint base class, ported from cmss13 code/modules/vehicles/hardpoints/hardpoint.dm
 * Hardpoints are any items that attach to a base vehicle, such as wheels/treads,
 * support systems and guns.
 *
 * Major adaptations for Horizon-Dream (TG codebase):
 * - integrity uses the TG atom_integrity/max_integrity system instead of CM's health var
 * - firing uses TG projectiles directly (aim_projectile + fire) instead of the CM
 *   ammo/autofire component stack
 * - fire cooldowns and burst/automatic logic are implemented locally
 */

/obj/item/hardpoint
	//------MAIN VARS----------
	/// Which slot is this hardpoint in. Purely to check for conflicting hardpoints.
	var/slot
	/// The vehicle this hardpoint is installed on.
	var/obj/vehicle/multitile/owner
	max_integrity = 100
	w_class = WEIGHT_CLASS_BULKY
	/// Determines how much of any incoming damage is actually taken.
	var/damage_multiplier = 1
	/// Origin coords of the hardpoint relative to the vehicle.
	var/list/origins = list(0, 0)
	var/list/buff_multipliers
	var/list/type_multipliers
	var/buff_applied = FALSE
	//------ICON VARS----------
	icon = '_horizon/icons/vehicles/obj/hardpoints/tank.dmi'
	icon_state = "tires" //Placeholder
	/// The vehicle body dmi that holds the on-vehicle overlay states for this hardpoint.
	var/disp_icon
	/// Base icon state of the overlay; the on-vehicle overlay uses "[disp_icon_state]_[0|1]".
	var/disp_icon_state
	/// List of pixel offsets for each direction.
	var/list/px_offsets
	/// Visual layer of hardpoint when on vehicle.
	var/hdpt_layer = HDPT_LAYER_WHEELS
	/// List of offsets for where to place the muzzle flash for each direction.
	var/list/muzzle_flash_pos = list(
		"1" = list(0, 0),
		"2" = list(0, 0),
		"4" = list(0, 0),
		"8" = list(0, 0)
	)
	// debug vars
	var/use_mz_px_offsets = FALSE
	var/use_mz_trt_offsets = FALSE
	var/const_mz_offset_x = 0
	var/const_mz_offset_y = 0
	//------SOUNDS VARS----------
	/// Sounds to play when the module activated/fired.
	var/list/activation_sounds
	//------INTERACTION VARS----------
	/// Which seat can use this module.
	var/allowed_seat = VEHICLE_GUNNER
	/// Whether hardpoint has activatable ability like shooting or zooming.
	var/activatable = 0
	/// Used to prevent welder click spam.
	var/being_repaired = FALSE
	/// The firing arc of this hardpoint.
	var/firing_arc = 0 //in degrees. 0 skips whole arc of fire check
	// Muzzleflash
	var/use_muzzle_flash = FALSE
	var/muzzleflash_icon_state = "muzzle_flash"
	var/underlayer_north_muzzleflash = FALSE
	var/angle_muzzleflash = TRUE
	//------AMMUNITION VARS----------
	/// Currently loaded ammo that we shoot from.
	var/obj/item/ammo_magazine/hardpoint/ammo
	/// Spare magazines that we can reload from.
	var/list/backup_clips
	/// Maximum amount of spare mags.
	var/max_clips = 0
	/// How much the bullets scatter when fired, in degrees.
	var/scatter = 0
	/// How many bullets the gun has fired in the current burst/auto sequence.
	var/shots_fired = 0
	/// Delay before a new firing sequence can start.
	COOLDOWN_DECLARE(fire_cooldown)
	// Firemodes.
	/// Current selected firemode of the gun.
	var/gun_firemode = HARDPOINT_FIREMODE_SEMIAUTO
	/// List of allowed firemodes.
	var/list/gun_firemode_list = list(
		HARDPOINT_FIREMODE_SEMIAUTO,
	)
	// Semi-auto and full-auto.
	/// For regular shots, how long to wait before firing again, in deciseconds.
	var/fire_delay = 0
	/// If the gun is currently auto firing.
	var/auto_firing = FALSE
	// Burst fire.
	/// How many shots can the weapon shoot in burst?
	var/burst_amount = 1
	/// The delay in between shots, in deciseconds.
	var/burst_delay = 1
	/// When burst-firing, this number is extra time before the weapon can fire again.
	var/extra_delay = 0
	/// If the gun is currently burst firing.
	var/burst_firing = FALSE
	/// Currently selected target to fire at. Set with set_target().
	var/atom/target
	/// The type of projectile to fire.
	var/projectile_type = /obj/projectile
//-----------------------------
//------GENERAL PROCS----------
//-----------------------------

/obj/item/hardpoint/p_s(temp_gender)
	if(!temp_gender)
		temp_gender = gender
	if(temp_gender == PLURAL)
		. = "s"
/obj/item/hardpoint/p_are(temp_gender)
	if(!temp_gender)
		temp_gender = gender
	if(temp_gender == PLURAL)
		. = "are"
	else
		. = "is"
/obj/item/hardpoint/Destroy()
	if(owner)
		owner.remove_hardpoint(src)
		owner.update_appearance()
		owner = null
	QDEL_LAZYLIST(backup_clips)
	QDEL_NULL(ammo)
	set_target(null)
	return ..()
/obj/item/hardpoint/ex_act(severity)
	if(owner || (resistance_flags & INDESTRUCTIBLE))
		return
	take_damage(severity / 2)
	if(atom_integrity <= 0)
		visible_message(span_warning("[src] disintegrates into a useless pile of scrap under the damage it suffered."))
		deconstruct(TRUE)
/obj/item/hardpoint/proc/can_take_damage()
	if(!damage_multiplier)
		return FALSE
	if(atom_integrity > 0)
		return TRUE
// Override of /atom/proc/take_damage (no /proc/ here: the parent proc exists).
// Drops TG's armor/flag pipeline and applies damage_multiplier instead,
// like cmss13's hardpoint damage handling.
/obj/item/hardpoint/take_damage(damage)
	if(atom_integrity <= 0)
		return
	atom_integrity = max(0, atom_integrity - damage * damage_multiplier)
	if(!atom_integrity)
		on_destroy()
/obj/item/hardpoint/proc/on_destroy()
	return
/obj/item/hardpoint/proc/is_activatable()
	if(atom_integrity <= 0)
		return FALSE
	return activatable
/// Returns the integrity of the hardpoint module in percent
/obj/item/hardpoint/proc/get_integrity_percent()
	return 100.0*atom_integrity/max_integrity
/// Apply hardpoint effects to vehicle and self.
/obj/item/hardpoint/proc/on_install(obj/vehicle/multitile/vehicle)
	if(!vehicle) //in loose holder
		return
	apply_buff(vehicle)
/// Remove hardpoint effects from vehicle and self.
/obj/item/hardpoint/proc/on_uninstall(obj/vehicle/multitile/vehicle)
	if(!vehicle) //in loose holder
		return
	remove_buff(vehicle)
/// Applying passive buffs like damage type resistance, speed, accuracy, cooldowns.
/obj/item/hardpoint/proc/apply_buff(obj/vehicle/multitile/vehicle)
	if(buff_applied)
		return
	if(LAZYLEN(type_multipliers))
		for(var/type in type_multipliers)
			vehicle.dmg_multipliers[type] *= LAZYACCESS(type_multipliers, type)
	if(LAZYLEN(buff_multipliers))
		for(var/type in buff_multipliers)
			vehicle.misc_multipliers[type] *= LAZYACCESS(buff_multipliers, type)
	buff_applied = TRUE
/// Removing passive buffs like damage type resistance, speed, accuracy, cooldowns.
/obj/item/hardpoint/proc/remove_buff(obj/vehicle/multitile/vehicle)
	if(!buff_applied)
		return
	if(LAZYLEN(type_multipliers))
		for(var/type in type_multipliers)
			vehicle.dmg_multipliers[type] *= 1 / LAZYACCESS(type_multipliers, type)
	if(LAZYLEN(buff_multipliers))
		for(var/type in buff_multipliers)
			vehicle.misc_multipliers[type] *= 1 / LAZYACCESS(buff_multipliers, type)
	buff_applied = FALSE
//this proc is called on each move of the vehicle
/obj/item/hardpoint/proc/on_move(turf/old, turf/new_turf, move_dir)
	return
/obj/item/hardpoint/proc/get_root_origins()
	return list(-owner.bound_x / world.icon_size, -owner.bound_y / world.icon_size)
// Resets the hardpoint rotation to south
/obj/item/hardpoint/proc/reset_rotation()
	rotate(turning_angle(dir, SOUTH))
/obj/item/hardpoint/proc/rotate(deg)
	if(!deg)
		return
	// Update origins
	var/list/root_coords = get_root_origins()
	var/list/center_coords = list(owner.bound_width / (2*world.icon_size), owner.bound_height / (2*world.icon_size))
	var/list/origin_coords_abs = list(origins[1] + root_coords[1], origins[2] + root_coords[2])
	origin_coords_abs[1] = origin_coords_abs[1] + 0.5
	origin_coords_abs[2] = origin_coords_abs[2] + 0.5
	var/list/new_origin = RotateAroundAxis(origin_coords_abs, center_coords, deg)
	new_origin[1] = round(new_origin[1] - root_coords[1] - 0.5, 1)
	new_origin[2] = round(new_origin[2] - root_coords[2] - 0.5, 1)
	origins = new_origin
	// Update dir
	setDir(turn(dir, deg))
//for the tgui
/obj/item/hardpoint/proc/get_tgui_info()
	var/list/data = list()
	data["name"] = name
	if(atom_integrity <= 0)
		data["health"] = null
	else
		data["health"] = floor(get_integrity_percent())
	if(ammo)
		data["uses_ammo"] = TRUE
		data["current_rounds"] = ammo.current_rounds
		data["max_rounds"] = ammo.max_rounds
		data["mags"] = LAZYLEN(backup_clips)
		data["max_mags"] = max_clips
	else
		data["uses_ammo"] = FALSE
	return data
//-----------------------------
//------INTERACTION PROCS----------
//-----------------------------

/obj/item/hardpoint/proc/deactivate()
	return
/// Called for every mob we bump while driving. Modules can apply effects to them.
/obj/item/hardpoint/proc/livingmob_interact(mob/living/M)
	return
//examining a hardpoint
/obj/item/hardpoint/examine(mob/user)
	. = ..()
	if(atom_integrity <= 0)
		. += "It's busted!"
	else
		. += "It's at [round(get_integrity_percent(), 1)]% integrity!"
//reloading hardpoint - take mag from backup clips and replace current ammo with it. Called via weapons loader
/obj/item/hardpoint/proc/handle_repair(obj/item/tool, mob/user)
	return welder_act(user, tool)
/obj/item/hardpoint/proc/reload(mob/user)
	if(!LAZYLEN(backup_clips))
		to_chat(usr, span_warning("[name] has no remaining backup clips."))
		return
	var/obj/item/ammo_magazine/A = LAZYACCESS(backup_clips, 1)
	if(!A)
		to_chat(user, span_danger("Something went wrong! Ahelp and ask for a developer! Code: HP_RLDHP"))
		return
	to_chat(user, span_notice("You begin reloading [name]."))
	if(!do_after(user, 2 SECONDS, target = src))
		return
	ammo.forceMove(get_turf(src))
	ammo.update_appearance()
	ammo = A
	LAZYREMOVE(backup_clips, A)
	to_chat(user, span_notice("You reload [name]."))
//try adding magazine to hardpoint's backup clips. Called via weapons loader
/obj/item/hardpoint/proc/try_add_clip(obj/item/ammo_magazine/A, mob/user)
	if(!ammo)
		to_chat(user, span_warning("[name] doesn't use ammunition."))
		return FALSE
	if(max_clips == 0)
		to_chat(user, span_warning("[name] does not have room for additional ammo."))
		return FALSE
	else if(LAZYLEN(backup_clips) >= max_clips)
		to_chat(user, span_warning("[name]'s reloader is full."))
		return FALSE
	to_chat(user, span_notice("You begin loading [A] into [name]."))
	if(!do_after(user, 1 SECONDS, target = src))
		to_chat(user, span_warning("Something interrupted you while reloading [name]."))
		return FALSE
	if(LAZYLEN(backup_clips) >= max_clips)
		to_chat(user, span_warning("[name]'s reloader is full."))
		return FALSE
	user.transferItemToLoc(A, src)
	playsound(loc, '_horizon/sounds/machines/hydraulics_2.ogg', 50)
	LAZYADD(backup_clips, A)
	to_chat(user, span_notice("You load [A] into [name]. Ammo: <b>[ammo.current_rounds]/[ammo.max_rounds]</b> | Mags: <b>[LAZYLEN(backup_clips)]/[max_clips]</b>"))
	return TRUE
//repair procs
/obj/item/hardpoint/welder_act(mob/living/user, obj/item/tool)
	if(owner && !Adjacent(user))
		return ITEM_INTERACT_SKIP_TO_ATTACK
	if(atom_integrity <= 0)
		to_chat(user, span_warning("[src] crumbles in your hands to an unsalvageable mess."))
		qdel(src)
		return ITEM_INTERACT_BLOCKING
	if(atom_integrity >= max_integrity)
		to_chat(user, span_warning("[src]'s structural integrity is at 100%."))
		return ITEM_INTERACT_BLOCKING
	if(being_repaired)
		to_chat(user, span_warning("[src] is already being repaired."))
		return ITEM_INTERACT_BLOCKING
	//instead of making the timer for repairing longer, we adjust how much % of max HP we fix per second.
	//Using the original 10% per welding pass as reference
	var/amount_fixed = 5 //in %
	switch(slot)
		if(HDPT_ARMOR)
			amount_fixed = 1.4
		if(HDPT_TURRET)
			amount_fixed = 1.6
		if(HDPT_PRIMARY)
			amount_fixed = 2
		if(HDPT_SECONDARY)
			amount_fixed = 2.5
		if(HDPT_SUPPORT)
			amount_fixed = 2.5
		if(HDPT_TREADS)
			amount_fixed = 3.3
	being_repaired = TRUE
	user.visible_message(span_notice("[user] starts repairing [src]."), span_notice("You start repairing [name]."))
	while(tool.tool_start_check(user, amount=1))
		if(!tool.use_tool(src, user, 1 SECONDS, volume=40))
			break
		//we check for adjacency only if we are not installed. This is for turret for now
		if(!owner && !Adjacent(user))
			break
		atom_integrity += max_integrity/100 * amount_fixed
		if(atom_integrity >= max_integrity)
			atom_integrity = max_integrity
			user.visible_message(span_notice("[user] finishes repairing [src]."), span_notice("You finish repairing [name]. The integrity of the module is at [floor(get_integrity_percent())]%."))
			being_repaired = FALSE
			return ITEM_INTERACT_SUCCESS
		to_chat(user, span_notice("The integrity of [src] is now at [floor(get_integrity_percent())]%."))
	being_repaired = FALSE
	user.visible_message(span_notice("[user] stops repairing [src]."), span_notice("You stop repairing [name]. The integrity of the module is at [floor(get_integrity_percent())]%."))
	return ITEM_INTERACT_SUCCESS
/// Setter proc for the automatic firing flag.
/obj/item/hardpoint/proc/set_auto_firing(auto = FALSE)
	if(auto_firing != auto)
		auto_firing = auto
		if(!auto_firing) //end-of-fire, show changed ammo
			display_ammo()
/// Setter proc for the burst firing flag.
/obj/item/hardpoint/proc/set_burst_firing(burst = FALSE)
	if(burst_firing != burst)
		burst_firing = burst
		if(!burst_firing) //end-of-fire, show changed ammo
			display_ammo()
/// Clean all firing references.
/obj/item/hardpoint/proc/reset_fire()
	shots_fired = 0
	set_target(null)
	set_auto_firing(FALSE)
/obj/item/hardpoint/proc/set_target(atom/object)
	if(object == target || object == loc)
		return
	if(target)
		UnregisterSignal(target, COMSIG_QDELETING)
	target = object
	if(target)
		RegisterSignal(target, COMSIG_QDELETING, PROC_REF(clean_target))
/// Set the target to its turf, so we keep shooting even when it was qdeled.
/obj/item/hardpoint/proc/clean_target()
	SIGNAL_HANDLER
	target = get_turf(target)
/// Print how much ammo is left to chat.
/obj/item/hardpoint/proc/display_ammo(mob/user)
	if(!user)
		if(owner)
			user = owner.get_seat_mob(allowed_seat)
	if(!user)
		return
	if(ammo)
		to_chat(user, span_warning("[name] Ammo: <b>[ammo ? ammo.current_rounds : 0]/[ammo ? ammo.max_rounds : 0]</b> | Mags: <b>[LAZYLEN(backup_clips)]/[max_clips]</b>"))
/// The crew stopped clicking; stop firing.
/obj/item/hardpoint/proc/stop_fire(datum/source, atom/object, turf/location, control, params)
	if(auto_firing)
		reset_fire()
/// The crew dragged the mouse; update the target.
/obj/item/hardpoint/proc/change_target(datum/source, atom/src_object, atom/over_object, turf/src_location, turf/over_location, src_control, over_control, params)
	set_target(get_turf(over_object))
/// The crew clicked; fire or start firing.
/obj/item/hardpoint/proc/start_fire(datum/source, atom/object, turf/location, control, params)
	if(istype(object, /atom/movable/screen))
		return
	if(QDELETED(object))
		return
	if(!COOLDOWN_FINISHED(src, fire_cooldown))
		if(max(fire_delay, burst_delay + extra_delay) >= 2.0 SECONDS) //filter out guns with high firerate to prevent message spam.
			to_chat(source, span_warning("You need to wait [COOLDOWN_TIMELEFT(src, fire_cooldown) / 10] seconds before [name] can be used again."))
		return
	set_target(get_turf(object))
	switch(gun_firemode)
		if(HARDPOINT_FIREMODE_SEMIAUTO)
			var/fire_return = try_fire(object, source, params)
			//end-of-fire, show ammo (if changed)
			if(fire_return)
				reset_fire()
				display_ammo(source)
		if(HARDPOINT_FIREMODE_BURSTFIRE)
			if(burst_firing)
				return
			set_burst_firing(TRUE)
			burst_fire(object, source)
		if(HARDPOINT_FIREMODE_AUTOMATIC)
			if(auto_firing)
				return
			set_auto_firing(TRUE)
			auto_fire(object, source)
/// Fires a burst of burst_amount shots with burst_delay in between.
/obj/item/hardpoint/proc/burst_fire(atom/target_atom, mob/living/user)
	for(var/i in 1 to burst_amount)
		if(!auto_firing && !burst_firing)
			break
		try_fire(target_atom, user)
		if(i < burst_amount)
			sleep(burst_delay)
	set_burst_firing(FALSE)
	COOLDOWN_START(src, fire_cooldown, burst_delay + extra_delay)
	display_ammo(user)
/// Keeps firing while the crew holds the button.
/obj/item/hardpoint/proc/auto_fire(atom/target_atom, mob/living/user)
	while(auto_firing)
		if(!COOLDOWN_FINISHED(src, fire_cooldown))
			sleep(max(1, fire_delay - (world.time - fire_cooldown)))
			continue
		if(!try_fire(target_atom, user))
			break
		COOLDOWN_START(src, fire_cooldown, fire_delay)
		sleep(fire_delay)
	set_auto_firing(FALSE)
/// Tests if firing should be interrupted, otherwise fires.
/obj/item/hardpoint/proc/try_fire(atom/target_atom, mob/living/user, params)
	if(atom_integrity <= 0)
		to_chat(user, span_warning("<b>[name] is broken!</b>"))
		return NONE
	if(ammo && ammo.current_rounds <= 0)
		click_empty(user)
		return NONE
	if(!in_firing_arc(target_atom))
		to_chat(user, span_warning("<b>The target is not within your firing arc!</b>"))
		return NONE
	return handle_fire(target_atom, user, params)
/// Actually fires the gun, sets up the projectile and fires it.
/obj/item/hardpoint/proc/handle_fire(atom/target_atom, mob/living/user, params)
	var/turf/origin_turf = get_origin_turf()
	var/obj/projectile/projectile_to_fire = new projectile_type(origin_turf)
	projectile_to_fire.firer = user
	projectile_to_fire.name = "[initial(name)] projectile"
	projectile_to_fire.aim_projectile(target_atom, origin_turf, params ? params2list(params) : null, scatter)
	ammo.current_rounds--
	INVOKE_ASYNC(projectile_to_fire, TYPE_PROC_REF(/obj/projectile, fire))
	shots_fired++
	play_firing_sounds()
	if(use_muzzle_flash)
		muzzle_flash(get_angle(origin_turf, target_atom))
	return TRUE
/// Start cooldown to respect delay of firemode.
/obj/item/hardpoint/proc/set_fire_cooldown()
	var/cooldown_time = fire_delay
	switch(gun_firemode)
		if(HARDPOINT_FIREMODE_BURSTFIRE)
			cooldown_time = burst_delay * burst_amount + extra_delay
	COOLDOWN_START(src, fire_cooldown, cooldown_time)
/// Get turf at hardpoint origin offset, used as the muzzle.
/obj/item/hardpoint/proc/get_origin_turf()
	return get_offset_target_turf(get_turf(src), origins[1], origins[2])
/// Plays 'click' noise and announces to chat. Usually called when weapon empty.
/obj/item/hardpoint/proc/click_empty(mob/user)
	playsound(src, 'sound/items/weapons/gun/general/dry_fire.ogg', 25, TRUE, 5)
	if(user)
		to_chat(user, span_warning("<b>*click*</b>"))
/// Selects and plays a firing sound from the list.
/obj/item/hardpoint/proc/play_firing_sounds()
	if(LAZYLEN(activation_sounds))
		playsound(get_turf(src), pick(activation_sounds), 60, TRUE)
/// Determines whether something is in firing arc of a hardpoint.
/obj/item/hardpoint/proc/in_firing_arc(atom/target_atom)
	if(!firing_arc || firing_arc >= 360)
		return TRUE
	var/turf/muzzle_turf = get_origin_turf()
	var/turf/target_turf = get_turf(target_atom)
	//same tile angle returns EAST, returning FALSE to ensure consistency
	if(muzzle_turf == target_turf)
		return FALSE
	var/angle_diff = (dir2angle(dir) - get_angle(muzzle_turf, target_turf)) %% 360
	if(angle_diff < -180)
		angle_diff += 360
	else if(angle_diff > 180)
		angle_diff -= 360
	return abs(angle_diff) <= (firing_arc * 0.5)
//-----------------------------
//------ICON PROCS----------
//-----------------------------

/// Returns an image for the hardpoint
/obj/item/hardpoint/proc/get_hardpoint_image()
	var/offset_x = 0
	var/offset_y = 0
	if(LAZYLEN(px_offsets) && loc)
		offset_x = px_offsets["[LocDir()]"][1]
		offset_y = px_offsets["[LocDir()]"][2]
	var/image/img = get_icon_image(offset_x, offset_y, dir)
	return img
/// Helper to get the direction of whatever we're mounted on (vehicle or holder)
/obj/item/hardpoint/proc/LocDir()
	if(loc)
		return "[loc.dir]"
	return "2"
/// Returns the image object to overlay onto the root object
/obj/item/hardpoint/proc/get_icon_image(x_offset, y_offset, new_dir)
	var/is_broken = atom_integrity <= 0
	var/image/img = image(icon = disp_icon, icon_state = "[disp_icon_state]_[is_broken ? "1" : "0"]", pixel_x = x_offset, pixel_y = y_offset, dir = new_dir)
	switch(floor((atom_integrity / max_integrity) * 100))
		if(0)
			img.color = "#888888"
		if(1 to 20)
			img.color = "#4e4e4e"
		if(21 to 40)
			img.color = "#6e6e6e"
		if(41 to 60)
			img.color = "#8b8b8b"
		if(61 to 80)
			img.color = "#bebebe"
		else
			img.color = null
	return img
/// debug proc
/obj/item/hardpoint/proc/set_offsets(dir, x, y)
	if(isnull(px_offsets))
		px_offsets = list(
			"1" = list(0, 0),
			"2" = list(0, 0),
			"4" = list(0, 0),
			"8" = list(0, 0)
		)
	px_offsets["[dir]"] = list(x, y)
	if(owner)
		owner.update_appearance()
/obj/item/hardpoint/proc/muzzle_flash(angle)
	if(isnull(angle))
		return
	// The +48 and +64 centers the muzzle flash
	var/muzzle_flash_x = muzzle_flash_pos["[dir]"][1] + 48
	var/muzzle_flash_y = muzzle_flash_pos["[dir]"][2] + 64
	// Account for turret rotation
	if(istype(loc, /obj/item/hardpoint/holder))
		var/obj/item/hardpoint/holder/H = loc
		if(LAZYLEN(H.px_offsets) && H.loc)
			muzzle_flash_x += H.px_offsets["[H.loc.dir]"][1]
			muzzle_flash_y += H.px_offsets["[H.loc.dir]"][2]
	var/image_layer = owner.layer + 0.1
	if(underlayer_north_muzzleflash && dir == NORTH)
		image_layer = owner.layer - 0.1
	if(!angle_muzzleflash)
		angle = dir2angle(dir)
	var/image/img = image('_horizon/icons/effects/muzzle_flashes.dmi', src, muzzleflash_icon_state, image_layer)
	var/matrix/rotate = matrix() //Change the flash angle.
	rotate.Turn(angle)
	rotate.Translate(muzzle_flash_x, muzzle_flash_y)
	img.transform = rotate
	owner.add_overlay(img)
	addtimer(CALLBACK(owner, TYPE_PROC_REF(/atom, cut_overlay), img), 3)
/// debug proc
/obj/item/hardpoint/proc/set_mf_offset(dir, x, y)
	if(!muzzle_flash_pos)
		muzzle_flash_pos = list(
			"1" = list(0, 0),
			"2" = list(0, 0),
			"4" = list(0, 0),
			"8" = list(0, 0)
		)
	muzzle_flash_pos["[dir]"] = list(x, y)
/// debug proc
/obj/item/hardpoint/proc/set_mf_use_px(use)
	use_mz_px_offsets = use
/// debug proc
/obj/item/hardpoint/proc/set_mf_use_trt(use)
	use_mz_trt_offsets = use
/// Proc to be overridden if you want to have special conditions preventing the removal of the hardpoint.
/// Add chat messages in this proc if you want to tell the player why.
/obj/item/hardpoint/proc/can_be_removed(mob/remover)
	if(remover.stat > STABLE)
		return FALSE
	return TRUE
/*
 * Math helpers ported from cmss13, missing in Horizon-Dream.
 */

/// Returns the angle to feed turn()/RotateAroundAxis() to rotate from
/// from_dir to to_dir, in degrees, or 0.
/// Port note: cmss13 defines this as a NEGATED macro,
/// #define turning_angle(a, b) -(dir2angle(b) - dir2angle(a)).
/// dir2angle grows clockwise while turn()/RotateAroundAxis() rotate
/// counterclockwise for positive angles, so the minus is mandatory.
/// Dropping it mirrored vehicle entrances onto the wrong sides and
/// inverted steering for anything not facing south.
/proc/turning_angle(from_dir, to_dir)
	return -(dir2angle(to_dir) - dir2angle(from_dir))
/// Rotates a coordinate pair around a center point by deg degrees.
/proc/RotateAroundAxis(list/coords, list/center, deg)
	var/s = sin(deg)
	var/c = cos(deg)
	var/x = coords[1] - center[1]
	var/y = coords[2] - center[2]
	var/new_x = x * c - y * s + center[1]
	var/new_y = x * s + y * c + center[2]
	return list(new_x, new_y)