/*
 * Multitile vehicle verbs and TGUI status window, ported from cmss13
 * code/modules/vehicles/multitile/multitile_verbs.dm
 *
 * Adapted for Horizon-Dream:
 * - verbs resolve their vehicle through the crew seat the invoking mob is
 *   buckled to (cmss13 used mob.interactee, which doesn't exist in TG)
 * - verbs are handed out with add_verb()/remove_verb() when a mob takes a seat
 */

//------------------------------------------------------
//------------------------VERBS-------------------------
//This file contains all basic verbs that vehicles contain

//Used to swap which module a position is using
//e.g. swapping primary gunner from the minigun to the smoke launcher
/obj/vehicle/multitile/proc/switch_hardpoint()
	set name = "Change Active Hardpoint"
	set category = "Vehicle"

	var/mob/seated_mob = usr
	if(!istype(seated_mob))
		return

	var/obj/vehicle/multitile/vehicle = seated_mob.get_multitile_vehicle()
	if(!istype(vehicle))
		return

	var/seat = vehicle.get_mob_seat(seated_mob)
	if(!seat)
		return

	var/list/usable_hps = vehicle.get_activatable_hardpoints(seat)
	if(!LAZYLEN(usable_hps))
		to_chat(seated_mob, span_warning("None of the hardpoints can be activated or they are all broken."))
		return

	var/obj/item/hardpoint/chosen_hardpoint = tgui_input_list(seated_mob, "Select a hardpoint.", "Switch Hardpoint", usable_hps)
	if(!chosen_hardpoint)
		return

	var/obj/item/hardpoint/old_hardpoint = vehicle.active_hp[seat]
	if(old_hardpoint)
		old_hardpoint.reset_fire() //stop fire when switching away from HP

	vehicle.active_hp[seat] = chosen_hardpoint
	var/msg = "You select \the [chosen_hardpoint]."
	if(chosen_hardpoint.ammo)
		msg += " Ammo: <b>[chosen_hardpoint.ammo.current_rounds]/[chosen_hardpoint.ammo.max_rounds]</b> | Mags: <b>[LAZYLEN(chosen_hardpoint.backup_clips)]/[chosen_hardpoint.max_clips]</b>"
	to_chat(seated_mob, span_warning(msg))

//cycles through hardpoints in a activatable hardpoints list without asking anything
/obj/vehicle/multitile/proc/cycle_hardpoint()
	set name = "Cycle Active Hardpoint"
	set category = "Vehicle"

	var/mob/seated_mob = usr
	if(!istype(seated_mob))
		return

	var/obj/vehicle/multitile/vehicle = seated_mob.get_multitile_vehicle()
	if(!istype(vehicle))
		return

	var/seat = vehicle.get_mob_seat(seated_mob)
	if(!seat)
		return

	var/list/usable_hps = vehicle.get_activatable_hardpoints(seat)
	if(!LAZYLEN(usable_hps))
		to_chat(seated_mob, span_warning("None of the hardpoints can be activated or they are all broken."))
		return
	var/new_hp = usable_hps.Find(vehicle.active_hp[seat])
	if(!new_hp)
		new_hp = 0

	new_hp = (new_hp % length(usable_hps)) + 1
	var/obj/item/hardpoint/chosen_hardpoint = usable_hps[new_hp]
	if(!chosen_hardpoint)
		return

	var/obj/item/hardpoint/old_hardpoint = vehicle.active_hp[seat]
	if(old_hardpoint)
		old_hardpoint.reset_fire() //stop fire when switching away from HP

	vehicle.active_hp[seat] = chosen_hardpoint
	var/msg = "You select \the [chosen_hardpoint]."
	if(chosen_hardpoint.ammo)
		msg += " Ammo: <b>[chosen_hardpoint.ammo.current_rounds]/[chosen_hardpoint.ammo.max_rounds]</b> | Mags: <b>[LAZYLEN(chosen_hardpoint.backup_clips)]/[chosen_hardpoint.max_clips]</b>"
	to_chat(seated_mob, span_warning(msg))

// Used to lock/unlock the vehicle doors to anyone without proper access
/obj/vehicle/multitile/proc/toggle_door_lock()
	set name = "Toggle Door Locks"
	set category = "Vehicle"

	var/mob/seated_mob = usr
	if(!istype(seated_mob))
		return

	var/obj/vehicle/multitile/vehicle = seated_mob.get_multitile_vehicle()
	if(!istype(vehicle))
		return

	var/seat = vehicle.get_mob_seat(seated_mob)
	if(!seat)
		return
	if(seat != VEHICLE_DRIVER)
		return

	vehicle.door_locked = !vehicle.door_locked
	to_chat(seated_mob, span_notice("You [vehicle.door_locked ? "lock" : "unlock"] the vehicle doors."))

//opens vehicle status window with HP and ammo of hardpoints
/obj/vehicle/multitile/proc/get_status_info()
	set name = "Get Status Info"
	set desc = "Displays all available information about your vehicle in a small window."
	set category = "Vehicle"

	var/mob/seated_mob = usr
	if(!istype(seated_mob))
		return

	var/obj/vehicle/multitile/vehicle = seated_mob.get_multitile_vehicle()
	if(!istype(vehicle))
		return

	var/seat = vehicle.get_mob_seat(seated_mob)
	if(!seat)
		return

	vehicle.ui_interact(seated_mob)

// BEGIN TGUI \\

/obj/vehicle/multitile/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "VehicleStatus", "[capitalize(name)]")
		ui.open()

/obj/vehicle/multitile/ui_data(mob/user)
	var/list/data = list()

	var/list/resist_name = list("Bio" = "acid", "Slash" = "slash", "Bullet" = "bullet", "Expl" = "explosive", "Blunt" = "blunt")
	var/list/resist_data_list = list()

	for(var/resist_label in resist_name)
		var/resist = 1 - LAZYACCESS(dmg_multipliers, LAZYACCESS(resist_name, resist_label))
		resist_data_list += list(list(
			"name" = resist_label,
			"pct" = resist
		))

	data["resistance_data"] = resist_data_list
	data["integrity"] = floor(100 * atom_integrity / max_integrity)
	data["door_locked"] = door_locked
	data["total_passenger_slots"] = interior ? interior.passengers_slots : 0
	data["total_taken_slots"] = interior ? interior.passengers_taken_slots : 0

	var/list/passenger_category_data_list = list()

	if(interior)
		for(var/datum/role_reserved_slots/reserved_slot_category in interior.role_reserved_slots)
			passenger_category_data_list += list(list(
				"name" = reserved_slot_category.category_name,
				"taken" = reserved_slot_category.taken,
				"total" = reserved_slot_category.total
			))

	data["passenger_categories_data"] = passenger_category_data_list

	var/list/hps = hardpoints.Copy()
	var/list/hardpoint_data_list = list()

	for(var/obj/item/hardpoint/holder/holder_module in hps)
		hardpoint_data_list += holder_module.get_tgui_info()
		LAZYREMOVE(hps, holder_module)
	for(var/obj/item/hardpoint/installed_hardpoint in hps)
		hardpoint_data_list += list(installed_hardpoint.get_tgui_info())

	data["hardpoint_data"] = hardpoint_data_list

	return data

/obj/vehicle/multitile/ui_state(mob/user)
	return GLOB.not_incapacitated_state

// END TGUI \\

//opens vehicle controls guide, that contains description of all verbs and shortcuts in it
/obj/vehicle/multitile/proc/open_controls_guide()
	set name = "Vehicle Controls Guide"
	set desc = "MANDATORY FOR FIRST PLAY AS VEHICLE CREWMAN OR AFTER UPDATES."
	set category = "Vehicle"

	var/mob/seated_mob = usr
	if(!istype(seated_mob))
		return

	var/obj/vehicle/multitile/vehicle = seated_mob.get_multitile_vehicle()
	if(!istype(vehicle))
		return

	var/seat = vehicle.get_mob_seat(seated_mob)
	if(!seat)
		return

	var/dat = "<b><i>Common verbs:</i></b><br>1. <b>\"A: Change Active Hardpoint\"</b> - brings up a list of all not destroyed activatable hardpoints you have access to and allows you to switch your current active hardpoint to one from the list. To activate currently selected hardpoint, click on your target. <font color='#cd6500'><b>MAKE SURE NOT TO HIT YOUR ALLIES.</b></font><br>\
	2. <b>\"G: Name Vehicle\"</b> - used to add a custom name to the vehicle. Single use. 26 characters maximum.<br> \
	3. <b>\"I: Get Status Info\"</b> - brings up \"Vehicle Status Info\" window with all available information about your vehicle.<br> \
	<font color='#cd6500'><b><i>Driver verbs:</i></b></font><br> 1. <b>\"G: Activate Horn\"</b> - activates vehicle horn. Keep in mind, that vehicle horn is very loud and can be heard from afar by both allies and foes.<br> \
	2. <b>\"G: Toggle Door Locks\"</b> - toggles vehicle's access restrictions. Heads of staff and security accesses bypass these restrictions.<br> \
	<font color=\"red\"><b><i>Gunner verbs:</i></b></font><br> 1. <b>\"A: Cycle Active Hardpoint\"</b> - works similarly to one above, except it automatically switches to next hardpoint in a list allowing you to switch faster.<br> \
	2. <b>\"G: Toggle Turret Gyrostabilizer\"</b> - toggles Turret Gyrostabilizer allowing it to keep current direction ignoring hull turning. <i>(Exists only on vehicles with rotating turret, e.g. M34A2 Longstreet Light Tank)</i><br> \
	<font color='#003300'><b><i>Support Gunner verbs:</i></b></font><br> 1. <b>\"Reload Firing Port Weapon\"</b> - initiates automated reloading process for M56 FPW. Requires a confirmation.<br> \
	<font color='#cd6500'><b><i>Driver shortcuts:</i></b></font><br> 1. <b>\"CTRL + Click\"</b> - activates vehicle horn.<br> \
	<font color=\"red\"><b><i>Gunner shortcuts:</i></b></font><br> 1. <b>\"ALT + Click\"</b> - toggles Turret Gyrostabilizer. <i>(Exists only on vehicles with rotating turret, e.g. M34A2 Longstreet Light Tank)</i><br>"

	seated_mob << browse(dat, "window=vehicle_help;size=900x500")

//toggles gyrostabilizer for vehicles that have turret, allowing it to keep direction regardless hull rotations
/obj/vehicle/multitile/proc/toggle_gyrostabilizer(mob/toggling_mob)
	set name = "Toggle Turret Gyrostabilizer"
	set desc = "Toggles Turret Gyrostabilizer allowing it independent movement regardless of hull direction."
	set category = "Vehicle"

	var/mob/seated_mob = toggling_mob || usr
	if(!istype(seated_mob))
		return

	var/obj/vehicle/multitile/vehicle = seated_mob.get_multitile_vehicle()
	if(!istype(vehicle))
		return

	var/obj/item/hardpoint/holder/tank_turret/turret = null
	for(var/obj/item/hardpoint/holder/tank_turret/installed_turret in vehicle.hardpoints)
		turret = installed_turret
		break
	if(!turret)
		return
	turret.toggle_gyro(seated_mob)

//single use verb that allows VCs to add a nickname in "" at the end of their vehicle name
/obj/vehicle/multitile/proc/name_vehicle()
	set name = "Name Vehicle"
	set desc = "Allows you to add a custom name to your vehicle. Single use. 26 characters maximum."
	set category = "Vehicle"

	var/mob/seated_mob = usr
	if(!istype(seated_mob))
		return

	var/obj/vehicle/multitile/vehicle = seated_mob.get_multitile_vehicle()
	if(!istype(vehicle))
		return

	var/seat = vehicle.get_mob_seat(seated_mob)
	if(!seat)
		return

	if(vehicle.nickname)
		to_chat(seated_mob, span_warning("Vehicle already has a \"[vehicle.nickname]\" nickname."))
		return

	var/new_nickname = stripped_input(seated_mob, "Enter a unique IC name or a callsign to add to your vehicle's name. [MAX_NAME_LEN] characters maximum. \n\nIMPORTANT! This is an IC nickname/callsign for your vehicle and you will be punished for putting in meme names.\nSINGLE USE ONLY.", "Name your vehicle", null, MAX_NAME_LEN)
	if(!new_nickname)
		return
	if(length(new_nickname) > MAX_NAME_LEN)
		alert(seated_mob, "Name [new_nickname] is over [MAX_NAME_LEN] characters limit. Try again.", "Naming vehicle failed", "Ok")
		return
	var/vehicle_new_name = vehicle.name + "\"[new_nickname]\""
	if(tgui_alert(seated_mob, "Vehicle's name will be [vehicle_new_name]. Confirm?", "Confirmation?", list("Yes", "No")) != "Yes")
		return

	//post-checks
	if(vehicle.get_seat_mob(seat) != seated_mob) //check that we are still in seat
		to_chat(seated_mob, span_warning("You need to be buckled to vehicle seat to do this."))
		return

	if(vehicle.nickname) //check again if second VC was faster.
		to_chat(seated_mob, span_warning("The other crewman beat you to it!"))
		return

	vehicle.nickname = new_nickname
	vehicle.name = initial(vehicle.name) + " \"[vehicle.nickname]\""
	to_chat(seated_mob, span_notice("You've added \"[vehicle.nickname]\" nickname to your vehicle."))

	message_admins("[key_name(seated_mob)] added \"[vehicle.nickname]\" nickname to their [initial(vehicle.name)]. ([vehicle.x],[vehicle.y],[vehicle.z])")

	vehicle.initialize_cameras(TRUE)

//Activates vehicle horn. Yes, it is annoying.
/obj/vehicle/multitile/proc/activate_horn(mob/honking_mob)
	set name = "Activate Horn"
	set desc = "Activates vehicle signal. Beep-beep."
	set category = "Vehicle"

	var/mob/seated_mob = honking_mob || usr
	if(!istype(seated_mob))
		return

	var/obj/vehicle/multitile/vehicle = seated_mob.get_multitile_vehicle()
	if(!istype(vehicle))
		return

	var/seat = vehicle.get_mob_seat(seated_mob)
	if(!seat)
		return

	if(world.time < vehicle.next_honk)
		to_chat(seated_mob, span_warning("You need to wait [(vehicle.next_honk - world.time) / 10] seconds."))
		return

	vehicle.next_honk = world.time + 10 SECONDS
	to_chat(seated_mob, span_notice("You activate vehicle's horn."))
	vehicle.perform_honk()

/obj/vehicle/multitile/proc/perform_honk()
	if(honk_sound)
		playsound(loc, honk_sound, 75, TRUE, 15) //heard within ~15 tiles

//Support gunner verbs

/obj/vehicle/multitile/proc/reload_firing_port_weapon()
	set name = "Reload Firing Port Weapon"
	set desc = "Initiates firing port weapon automated reload process."
	set category = "Vehicle"

	var/mob/seated_mob = usr
	if(!istype(seated_mob))
		return

	var/obj/vehicle/multitile/vehicle = seated_mob.get_multitile_vehicle()
	if(!istype(vehicle))
		return

	var/seat = vehicle.get_mob_seat(seated_mob)

	if(!seat)
		return

	if(vehicle.atom_integrity < vehicle.max_integrity * 0.5)
		to_chat(seated_mob, span_warning("\The [vehicle]'s hull is too damaged to operate!"))

	for(var/obj/item/hardpoint/special/firing_port_weapon/port_weapon in vehicle.hardpoints)
		if(port_weapon.allowed_seat == seat)
			if(tgui_alert(seated_mob, "Initiate M56 FPW reload process? It will take [port_weapon.reload_time / 10] seconds.", "Initiate reload", list("Yes", "No")) == "Yes")
				port_weapon.start_auto_reload(seated_mob)
			return

	to_chat(seated_mob, span_warning("Warning. No FPW for [seat] found, tell a dev!"))
