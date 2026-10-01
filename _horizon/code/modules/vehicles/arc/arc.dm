/*
 * The ARC (Armored Recon Carrier), ported from cmss13
 * code/modules/vehicles/arc/arc.dm, verbs.dm and interior.dm
 *
 * The xeno-wallhack minimap sensor from cmss13 is not ported (no minimap);
 * the antenna still locks the vehicle in place and enables the automated
 * sentry turret, which is its core function.
 */

/obj/vehicle/multitile/arc
	name = "\improper M540-B Armored Recon Carrier"
	desc = "An M540-B Armored Recon Carrier. A lightly armored reconnaissance and intelligence vehicle. Entrances on the sides."
	icon = '_horizon/icons/vehicles/obj/arc.dmi'
	icon_state = "arc_base"
	pixel_x = -48
	pixel_y = -48
	bound_width = 96
	bound_height = 96
	bound_x = -32
	bound_y = -32
	max_integrity = 800
	interior_map = /datum/map_template/interior/arc
	passengers_slots = 2 // 5 total. Reserved slots are added to passenger slots.
	xenos_slots = 4
	entrances = list(
		"right" = list(-2, 0),
	)
	entrance_speed = 0.5 SECONDS
	movement_sound = '_horizon/sounds/vehicles/tank_driving.ogg'
	hardpoints_allowed = list(
		/obj/item/hardpoint/locomotion/arc_wheels,
		/obj/item/hardpoint/primary/arc_sentry,
		/obj/item/hardpoint/support/arc_antenna,
	)
	seats = list(
		VEHICLE_DRIVER = null,
	)
	active_hp = list(
		VEHICLE_DRIVER = null,
	)
	vehicle_flags = VEHICLE_CLASS_LIGHT
	mob_size_required_to_hit = MOB_SIZE_SMALL
	dmg_multipliers = list(
		"all" = 1,
		"acid" = 1.8,
		"slash" = 1.1,
		"bullet" = 0.6,
		"explosive" = 0.8,
		"blunt" = 0.8,
		"abstract" = 1,
	)
	move_max_momentum = 2.2
	move_momentum_build_factor = 1.5
	move_turn_momentum_loss_factor = 0.8
	vehicle_ram_multiplier = VEHICLE_TRAMPLE_DAMAGE_APC_REDUCTION
	/// If the ARC has its antenna up, making it unable to move but enabling the turret
	var/antenna_deployed = FALSE
	/// How long it takes to deploy or retract the antenna
	var/antenna_toggle_time = 10 SECONDS

/obj/vehicle/multitile/arc/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ARC_ANTENNA_TOGGLED, PROC_REF(on_antenna_toggle))

/// Keep the sentry's protected faction synced with the driver's faction
/obj/vehicle/multitile/arc/set_seated_mob(seat, mob/living/seated_mob)
	. = ..()
	if(!.)
		return
	if(seat == VEHICLE_DRIVER && istype(seated_mob))
		var/obj/item/hardpoint/primary/arc_sentry/sentry = locate() in hardpoints
		if(sentry)
			sentry.faction_to_protect = length(seated_mob.faction) ? seated_mob.faction[1] : null

/obj/vehicle/multitile/arc/proc/on_antenna_toggle(datum/source)
	SIGNAL_HANDLER

/obj/vehicle/multitile/arc/relaymove(mob/user, direction)
	if(antenna_deployed)
		return FALSE
	return ..()

/obj/vehicle/multitile/arc/load_role_reserved_slots()
	var/datum/role_reserved_slots/reserved_slots = new
	reserved_slots.category_name = "Command Staff"
	reserved_slots.roles = list("Commanding Officer", "Executive Officer", "Staff Officer", "Head of Personnel", "Captain", "Head of Security", "Chief Engineer", "Research Director", "Chief Medical Officer")
	reserved_slots.total = 2
	role_reserved_slots += reserved_slots

/obj/vehicle/multitile/arc/add_seated_verbs(mob/living/seated_mob, seat)
	if(!seated_mob.client)
		return
	add_verb(seated_mob, list(
		/obj/vehicle/multitile/proc/get_status_info,
		/obj/vehicle/multitile/arc/proc/open_arc_controls_guide,
		/obj/vehicle/multitile/proc/toggle_door_lock,
		/obj/vehicle/multitile/proc/activate_horn,
		/obj/vehicle/multitile/proc/name_vehicle,
		/obj/vehicle/multitile/arc/proc/toggle_antenna,
	))

/obj/vehicle/multitile/arc/remove_seated_verbs(mob/living/seated_mob, seat)
	if(!seated_mob.client)
		return
	remove_verb(seated_mob, list(
		/obj/vehicle/multitile/proc/get_status_info,
		/obj/vehicle/multitile/arc/proc/open_arc_controls_guide,
		/obj/vehicle/multitile/proc/toggle_door_lock,
		/obj/vehicle/multitile/proc/activate_horn,
		/obj/vehicle/multitile/proc/name_vehicle,
		/obj/vehicle/multitile/arc/proc/toggle_antenna,
	))
	SStgui.close_user_uis(seated_mob, src)

/obj/vehicle/multitile/arc/initialize_cameras(change_tag = FALSE)
	if(!camera)
		camera = new /obj/machinery/camera/vehicle(src)
	if(change_tag)
		camera.c_tag = "#[rand(1,100)] M540-B \"[nickname]\" ARC"
		if(camera_int)
			camera_int.c_tag = camera.c_tag + " interior"
	else
		camera.c_tag = "#[rand(1,100)] M540-B ARC"
		if(camera_int)
			camera_int.c_tag = camera.c_tag + " interior"
/*
** ARC VERBS
*/
/obj/vehicle/multitile/arc/proc/toggle_antenna(mob/toggler)
	set name = "Toggle Sensor Antenna"
	set desc = "Raises or lowers the external sensor antenna. While raised, the ARC cannot move."
	set category = "Vehicle"
	var/mob/seated_mob = toggler || usr
	if(!istype(seated_mob))
		return
	var/obj/vehicle/multitile/arc/vehicle = seated_mob.get_multitile_vehicle()
	if(!istype(vehicle))
		return
	var/seat = vehicle.get_mob_seat(seated_mob)
	if(!seat)
		return
	if(vehicle.atom_integrity < vehicle.max_integrity * 0.5)
		to_chat(seated_mob, span_warning("[vehicle]'s hull is too damaged to operate!"))
		return
	var/obj/item/hardpoint/support/arc_antenna/antenna = locate() in vehicle.hardpoints
	if(!antenna)
		to_chat(seated_mob, span_warning("[vehicle] has no antenna mounted!"))
		return
	if(antenna.deploying)
		return
	if(antenna.atom_integrity <= 0)
		to_chat(seated_mob, span_warning("[antenna] is broken!"))
		return
	if(vehicle.antenna_deployed)
		to_chat(seated_mob, span_notice("You begin to retract [antenna]..."))
		antenna.deploying = TRUE
		if(!do_after(seated_mob, max(vehicle.antenna_toggle_time - antenna.deploy_animation_time, 1 SECONDS), target = vehicle))
			to_chat(seated_mob, span_notice("You stop retracting [antenna]."))
			antenna.deploying = FALSE
			return
		antenna.retract_antenna()
		addtimer(CALLBACK(vehicle, PROC_REF(finish_antenna_retract), seated_mob), antenna.deploy_animation_time)
	else
		to_chat(seated_mob, span_notice("You begin to extend [antenna]..."))
		antenna.deploying = TRUE
		if(!do_after(seated_mob, max(vehicle.antenna_toggle_time - antenna.deploy_animation_time, 1 SECONDS), target = vehicle))
			to_chat(seated_mob, span_notice("You stop extending [antenna]."))
			antenna.deploying = FALSE
			return
		antenna.deploy_antenna()
		addtimer(CALLBACK(vehicle, PROC_REF(finish_antenna_deploy), seated_mob), antenna.deploy_animation_time)
/obj/vehicle/multitile/arc/proc/finish_antenna_retract(mob/user)

	var/obj/item/hardpoint/support/arc_antenna/antenna = locate() in hardpoints
	if(!antenna)
		return
	if(user)
		to_chat(user, span_notice("You retract [antenna], enabling the ARC to move again."))
		playsound(user, '_horizon/sounds/machines/hydraulics_2.ogg', 80, TRUE)
	antenna_deployed = !antenna_deployed
	antenna.deploying = FALSE
	update_appearance()
	SEND_SIGNAL(src, COMSIG_ARC_ANTENNA_TOGGLED)

/obj/vehicle/multitile/arc/proc/finish_antenna_deploy(mob/user)
	var/obj/item/hardpoint/support/arc_antenna/antenna = locate() in hardpoints
	if(!antenna)
		return
	if(user)
		to_chat(user, span_notice("You extend [antenna], locking the ARC in place."))
		playsound(user, '_horizon/sounds/machines/hydraulics_2.ogg', 80, TRUE)
	antenna_deployed = !antenna_deployed
	antenna.deploying = FALSE
	update_appearance()
	SEND_SIGNAL(src, COMSIG_ARC_ANTENNA_TOGGLED)

/obj/vehicle/multitile/arc/proc/open_arc_controls_guide()
	set name = "Vehicle Controls Guide"
	set desc = "MANDATORY FOR FIRST PLAY AS VEHICLE CREWMAN OR AFTER UPDATES."
	set category = "Vehicle"
	var/mob/seated_mob = usr
	if(!istype(seated_mob))
		return
	var/obj/vehicle/multitile/arc/vehicle = seated_mob.get_multitile_vehicle()
	if(!istype(vehicle))
		return
	var/seat = vehicle.get_mob_seat(seated_mob)
	if(!seat)
		return
	var/dat = "<b><i>Common verbs:</i></b><br>\
	1. <b>\"G: Name Vehicle\"</b> - used to add a custom name to the vehicle. Single use. 26 characters maximum.<br> \
	2. <b>\"I: Get Status Info\"</b> - brings up \"Vehicle Status Info\" window with all available information about your vehicle.<br> \
	3. <b>\"G: Toggle Sensor Antenna\"</b> - extend or retract the ARC's sensor antenna. While extended, the ARC cannot move, and the automated RE700 cannon engages nearby hostiles.<br> \
	<font color='#cd6500'><b><i>Driver verbs:</i></b></font><br> 1. <b>\"G: Activate Horn\"</b> - activates vehicle horn. Keep in mind, that vehicle horn is very loud and can be heard from afar by both allies and foes.<br> \
	2. <b>\"G: Toggle Door Locks\"</b> - toggles vehicle's access restrictions. Heads of staff and security accesses bypass these restrictions.<br> \
	<font color='#cd6500'><b><i>Driver shortcuts:</i></b></font><br> 1. <b>\"CTRL + Click\"</b> - activates vehicle horn.<br>"
	seated_mob << browse(dat, "window=vehicle_help;size=900x500")

/*
** ARC PRESETS SPAWNERS
*/
/obj/effect/vehicle_spawner/arc
	name = "ARC Transport Spawner"
	icon = '_horizon/icons/vehicles/obj/apc.dmi'
	icon_state = "apc_base"
	pixel_x = -48
	pixel_y = -48

/obj/effect/vehicle_spawner/arc/Initialize(mapload)
	. = ..()
	spawn_vehicle()
	return INITIALIZE_HINT_QDEL

/obj/effect/vehicle_spawner/arc/spawn_vehicle()
	var/obj/vehicle/multitile/arc/spawned_arc = new (loc)
	load_misc(spawned_arc)
	load_hardpoints(spawned_arc)
	handle_direction(spawned_arc)
	spawned_arc.update_appearance()

/obj/effect/vehicle_spawner/arc/load_hardpoints(obj/vehicle/multitile/arc/spawned_arc)
	spawned_arc.add_hardpoint(new /obj/item/hardpoint/locomotion/arc_wheels)
	spawned_arc.add_hardpoint(new /obj/item/hardpoint/primary/arc_sentry)
	spawned_arc.add_hardpoint(new /obj/item/hardpoint/support/arc_antenna)

/*
 * ARC interior structures, ported from cmss13 arc/interior.dm and
 * apc/interior.dm (the firing port weapon and sensor equipment props
 * originate from the APC and are reused inside the ARC).
 */

/obj/structure/interior_exit/vehicle/arc
	name = "ARC side door"
	icon = '_horizon/icons/vehicles/obj/interiors/arc.dmi'
	icon_state = "exit_door"

/obj/structure/prop/vehicle/arc
	name = "ARC chassis"
	desc = "The chassis of the ARC."
	icon = '_horizon/icons/vehicles/obj/interiors/arc_chassis.dmi'
	icon_state = "arc_chassis"
	layer = LOW_FLOOR_LAYER
	//mouse_opacity = FALSE

	//layer = ABOVE_NORMAL_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	density = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/structure/prop/vehicle/sensor_equipment
	name = "Data Analyzing Nexus"
	desc = "This machinery collects and analyzes data from the vehicle's sensors cluster. Better not touch it."
	icon = '_horizon/icons/vehicles/obj/interiors/apc.dmi'
	icon_state = "sensors_equipment"
	density = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/// A joystick styled like a smartgun handle; clicking it buckles you into the support gunner seat
/obj/structure/prop/vehicle/firing_port_weapon
	name = "M56 FPW handle"
	desc = "A control handle for a modified heavy machine gun installed on the sides of the vehicle as a Firing Port Weapon. Clicking on it while being adjacent to the support gunner seat will buckle you in and give you control of the weapon."
	icon = '_horizon/icons/vehicles/obj/interiors/apc.dmi'
	icon_state = "m56_FPW"
	density = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/obj/structure/chair/comfy/vehicle/support_gunner/SG_seat

/obj/structure/prop/vehicle/firing_port_weapon/examine(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	if(!SG_seat)
		SG_seat = locate() in get_turf(src)
		if(!SG_seat)
			. += span_warning("ERROR HAS OCCURRED! NO SEAT FOUND, TELL A DEV!")
			return
	for(var/obj/item/hardpoint/special/firing_port_weapon/port_weapon in SG_seat.vehicle?.hardpoints)
		if(port_weapon.allowed_seat == SG_seat.seat)
			if(port_weapon.ammo)
				. += span_notice("The [port_weapon.name]'s ammo count is: [span_bold("[port_weapon.ammo.current_rounds]")]/[span_bold("[port_weapon.ammo.max_rounds]")].")
				break
	. += span_notice("Clicking on the [name] while being adjacent to the support gunner seat will buckle you in and give you the control of the M56 FPW.")

/obj/structure/prop/vehicle/firing_port_weapon/attack_hand(mob/living/carbon/human/human_user, list/modifiers)
	if(!istype(human_user))
		return
	if(!SG_seat)
		SG_seat = locate() in get_turf(src)
		if(!SG_seat)
			to_chat(human_user, span_warning("ERROR HAS OCCURRED! NO SEAT FOUND, TELL A DEV!"))
			return
	if(!length(SG_seat.buckled_mobs) && !human_user.buckled)
		SG_seat.user_buckle_mob(human_user, human_user)
		for(var/obj/item/hardpoint/special/firing_port_weapon/port_weapon in SG_seat.vehicle?.hardpoints)
			if(port_weapon.allowed_seat == SG_seat.seat)
				if(port_weapon.ammo)
					to_chat(human_user, span_notice("The [port_weapon.name]'s ammo count is: [span_bold("[port_weapon.ammo.current_rounds]")]/[span_bold("[port_weapon.ammo.max_rounds]")]."))
					break
		return

// Comfy chairs used in the ARC interior (layer tweak, like cmss13)
/obj/structure/chair/comfy/arc
	name = "crew chair"
	layer = BELOW_MOB_LAYER
