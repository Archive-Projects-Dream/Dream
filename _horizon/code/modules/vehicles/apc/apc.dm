/*
 * APCs, ported from cmss13 code/modules/vehicles/apc/apc.dm,
 * apc_command.dm, apc_medical.dm, apc_pmc.dm and interior.dm
 *
 * The command APC's xeno-minimap sensor is not ported (no minimap in TG);
 * the command station computer inside still works as a security console.
 */

GLOBAL_LIST_EMPTY(command_apc_list)

/obj/vehicle/multitile/apc
	name = "M577 Armored Personnel Carrier"
	desc = "An M577 Armored Personnel Carrier. An armored transport with four big wheels. Entrances on the sides and back."

	icon = '_horizon/icons/vehicles/obj/apc.dmi'
	icon_state = "apc_base"
	pixel_x = -48
	pixel_y = -48

	bound_width = 96
	bound_height = 96

	bound_x = -32
	bound_y = -32

	interior_map = /datum/map_template/interior/apc

	passengers_slots = 15
	xenos_slots = 8

	entrances = list(
		"left" = list(2, 0),
		"right" = list(-2, 0),
		"rear left" = list(1, 2),
		"rear center" = list(0, 2),
		"rear right" = list(-1, 2)
	)

	entrance_speed = 0.5 SECONDS

	movement_sound = '_horizon/sounds/vehicles/tank_driving.ogg'

	var/gunner_view_buff = 10

	hardpoints_allowed = list(
		/obj/item/hardpoint/primary/dualcannon,
		/obj/item/hardpoint/secondary/frontalcannon,
		/obj/item/hardpoint/support/flare_launcher,
		/obj/item/hardpoint/locomotion/apc_wheels,
	)

	seats = list(
		VEHICLE_DRIVER = null,
		VEHICLE_GUNNER = null,
		VEHICLE_SUPPORT_GUNNER_ONE = null,
		VEHICLE_SUPPORT_GUNNER_TWO = null,
	)

	active_hp = list(
		VEHICLE_DRIVER = null,
		VEHICLE_GUNNER = null,
		VEHICLE_SUPPORT_GUNNER_ONE = null,
		VEHICLE_SUPPORT_GUNNER_TWO = null,
	)

	vehicle_flags = VEHICLE_CLASS_LIGHT

	mob_size_required_to_hit = MOB_SIZE_SMALL

	dmg_multipliers = list(
		"all" = 1,
		"acid" = 1.6,
		"slash" = 0.8,
		"bullet" = 0.6,
		"explosive" = 0.7,
		"blunt" = 0.7,
		"abstract" = 1
	)

	move_max_momentum = 2
	move_momentum_build_factor = 1.5
	move_turn_momentum_loss_factor = 0.8

	vehicle_ram_multiplier = VEHICLE_TRAMPLE_DAMAGE_APC_REDUCTION

/obj/vehicle/multitile/apc/load_role_reserved_slots()
	var/datum/role_reserved_slots/reserved_slots = new
	reserved_slots.category_name = "Crewmen"
	reserved_slots.roles = list("Vehicle Crewman", "Tank Crewman", "Crewman")
	reserved_slots.total = 2
	role_reserved_slots += reserved_slots

/// cmss13 gave the APC gunner an absolute 10-tile view on a 7-tile world
/// (a +3 bump); translate that bump onto this server's default view so the
/// gunner sees further out without binocular-zooming everyone else in
/obj/vehicle/multitile/apc/get_crew_view(seat)
	if(seat == VEHICLE_GUNNER)
		var/list/default_view = getviewsize(world.view)
		return max(default_view[1], default_view[2]) + 3
	return ..()

/obj/vehicle/multitile/apc/add_seated_verbs(mob/living/seated_mob, seat)
	if(!seated_mob.client)
		return
	add_verb(seated_mob, list(
		/obj/vehicle/multitile/proc/get_status_info,
		/obj/vehicle/multitile/proc/open_controls_guide
	))
	if(seat == VEHICLE_DRIVER)
		add_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/toggle_door_lock,
			/obj/vehicle/multitile/proc/activate_horn,
			/obj/vehicle/multitile/proc/name_vehicle
		))
	else if(seat == VEHICLE_GUNNER)
		add_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/switch_hardpoint,
			/obj/vehicle/multitile/proc/cycle_hardpoint,
			/obj/vehicle/multitile/proc/name_vehicle
		))

	else if(seat == VEHICLE_SUPPORT_GUNNER_ONE || seat == VEHICLE_SUPPORT_GUNNER_TWO)
		add_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/reload_firing_port_weapon
		))

/obj/vehicle/multitile/apc/remove_seated_verbs(mob/living/seated_mob, seat)
	if(!seated_mob.client)
		return
	remove_verb(seated_mob, list(
		/obj/vehicle/multitile/proc/get_status_info,
		/obj/vehicle/multitile/proc/open_controls_guide,
	))
	SStgui.close_user_uis(seated_mob, src)
	if(seat == VEHICLE_DRIVER)
		remove_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/toggle_door_lock,
			/obj/vehicle/multitile/proc/activate_horn,
			/obj/vehicle/multitile/proc/name_vehicle,
		))
	else if(seat == VEHICLE_GUNNER)
		remove_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/switch_hardpoint,
			/obj/vehicle/multitile/proc/cycle_hardpoint,
			/obj/vehicle/multitile/proc/name_vehicle,
		))
	else if(seat == VEHICLE_SUPPORT_GUNNER_ONE || seat == VEHICLE_SUPPORT_GUNNER_TWO)
		remove_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/reload_firing_port_weapon
		))

/obj/vehicle/multitile/apc/initialize_cameras(change_tag = FALSE)
	if(!camera)
		camera = new /obj/machinery/camera/vehicle(src)
	if(change_tag)
		camera.c_tag = "#[rand(1,100)] M777 \"[nickname]\" APC"
		if(camera_int)
			camera_int.c_tag = camera.c_tag + " interior"
	else
		camera.c_tag = "#[rand(1,100)] M777 APC"
		if(camera_int)
			camera_int.c_tag = camera.c_tag + " interior"

/*
** PRESETS SPAWNERS
*/
/obj/effect/vehicle_spawner/apc
	name = "APC Transport Spawner"
	icon = '_horizon/icons/vehicles/obj/apc.dmi'
	icon_state = "apc_base"
	pixel_x = -48
	pixel_y = -48

//Installation of transport APC Firing Ports Weapons
/obj/effect/vehicle_spawner/apc/proc/load_fpw(obj/vehicle/multitile/apc/spawned_apc)
	var/obj/item/hardpoint/special/firing_port_weapon/left_fpw = new
	left_fpw.allowed_seat = VEHICLE_SUPPORT_GUNNER_ONE
	spawned_apc.add_hardpoint(left_fpw)
	left_fpw.dir = turn(spawned_apc.dir, 90)
	left_fpw.name = "Left "+ initial(left_fpw.name)
	left_fpw.origins = list(1, 0)
	left_fpw.muzzle_flash_pos = list(
		"1" = list(-18, 14),
		"2" = list(18, -42),
		"4" = list(34, 3),
		"8" = list(-32, -34)
	)

	var/obj/item/hardpoint/special/firing_port_weapon/right_fpw = new
	right_fpw.allowed_seat = VEHICLE_SUPPORT_GUNNER_TWO
	spawned_apc.add_hardpoint(right_fpw)
	right_fpw.dir = turn(spawned_apc.dir, -90)
	right_fpw.name = "Right "+ initial(right_fpw.name)
	right_fpw.origins = list(-1, 0)
	right_fpw.muzzle_flash_pos = list(
		"1" = list(16, 14),
		"2" = list(-18, -42),
		"4" = list(34, -34),
		"8" = list(-32, 2)
	)

/obj/effect/vehicle_spawner/apc/Initialize(mapload)
	. = ..()
	spawn_vehicle()
	qdel(src)

//PRESET: FPWs, no hardpoints
/obj/effect/vehicle_spawner/apc/spawn_vehicle()
	var/obj/vehicle/multitile/apc/spawned_apc = new (loc)

	load_misc(spawned_apc)
	load_fpw(spawned_apc)
	load_hardpoints(spawned_apc)
	handle_direction(spawned_apc)
	spawned_apc.update_appearance()

//PRESET: FPWs, wheels installed
/obj/effect/vehicle_spawner/apc/plain/load_hardpoints(obj/vehicle/multitile/apc/spawned_apc)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/locomotion/apc_wheels)

//PRESET: default hardpoints, destroyed (this one spawns on the elevator for VCs)
/obj/effect/vehicle_spawner/apc/decrepit/spawn_vehicle()
	var/obj/vehicle/multitile/apc/spawned_apc = new (loc)

	load_misc(spawned_apc)
	load_fpw(spawned_apc)
	load_hardpoints(spawned_apc)
	handle_direction(spawned_apc)
	load_damage(spawned_apc)
	spawned_apc.update_appearance()

/obj/effect/vehicle_spawner/apc/decrepit/load_hardpoints(obj/vehicle/multitile/apc/spawned_apc)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/primary/dualcannon)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/secondary/frontalcannon)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/support/flare_launcher)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/locomotion/apc_wheels)

//PRESET: FPWs, default hardpoints
/obj/effect/vehicle_spawner/apc/fixed/load_hardpoints(obj/vehicle/multitile/apc/spawned_apc)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/primary/dualcannon)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/secondary/frontalcannon)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/support/flare_launcher)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/locomotion/apc_wheels)

//Transport version without FPWs

/obj/vehicle/multitile/apc/unarmed
	interior_map = /datum/map_template/interior/apc_no_fpw

//PRESET: no hardpoints
/obj/effect/vehicle_spawner/apc/unarmed/spawn_vehicle()
	var/obj/vehicle/multitile/apc/unarmed/spawned_apc = new (loc)

	load_misc(spawned_apc)
	load_hardpoints(spawned_apc)
	handle_direction(spawned_apc)
	spawned_apc.update_appearance()

/obj/effect/vehicle_spawner/apc/unarmed/plain/load_hardpoints(obj/vehicle/multitile/apc/unarmed/spawned_apc)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/locomotion/apc_wheels)

//PRESET: default hardpoints, destroyed
/obj/effect/vehicle_spawner/apc/unarmed/decrepit/spawn_vehicle()
	var/obj/vehicle/multitile/apc/unarmed/spawned_apc = new (loc)

	load_misc(spawned_apc)
	load_hardpoints(spawned_apc)
	handle_direction(spawned_apc)
	load_damage(spawned_apc)
	spawned_apc.update_appearance()

/obj/effect/vehicle_spawner/apc/unarmed/decrepit/load_hardpoints(obj/vehicle/multitile/apc/unarmed/spawned_apc)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/primary/dualcannon)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/secondary/frontalcannon)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/support/flare_launcher)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/locomotion/apc_wheels)

//PRESET: default hardpoints
/obj/effect/vehicle_spawner/apc/unarmed/fixed/load_hardpoints(obj/vehicle/multitile/apc/unarmed/spawned_apc)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/primary/dualcannon)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/secondary/frontalcannon)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/support/flare_launcher)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/locomotion/apc_wheels)

/*
 * The command APC
 */
/obj/vehicle/multitile/apc/command
	name = "M577-CMD Armored Personnel Carrier"
	desc = "A modification of the M577 Armored Personnel Carrier designed to act as a field commander vehicle. An armored transport with four big wheels. Has inbuilt sensor tower and a field command station installed inside. Entrances on the sides."

	icon_state = "apc_base_com"

	interior_map = /datum/map_template/interior/apc_command

	passengers_slots = 8

	entrances = list(
		"left" = list(2, 0),
		"right" = list(-2, 0)
	)

	seats = list(
		VEHICLE_DRIVER = null,
		VEHICLE_GUNNER = null,
	)

	active_hp = list(
		VEHICLE_DRIVER = null,
		VEHICLE_GUNNER = null,
	)

/obj/vehicle/multitile/apc/command/Initialize(mapload)
	. = ..()
	GLOB.command_apc_list += src

/obj/vehicle/multitile/apc/command/Destroy()
	GLOB.command_apc_list -= src
	return ..()

/obj/vehicle/multitile/apc/command/load_role_reserved_slots()
	var/datum/role_reserved_slots/reserved_slots = new
	reserved_slots.category_name = "Crewmen"
	reserved_slots.roles = list("Vehicle Crewman", "Tank Crewman", "Crewman")
	reserved_slots.total = 2
	role_reserved_slots += reserved_slots

	reserved_slots = new
	reserved_slots.category_name = "Command Staff"
	reserved_slots.roles = list("Commanding Officer", "Executive Officer", "Staff Officer", "Head of Personnel", "Captain", "Head of Security", "Chief Engineer", "Research Director", "Chief Medical Officer")
	reserved_slots.total = 1
	role_reserved_slots += reserved_slots

/obj/vehicle/multitile/apc/command/add_seated_verbs(mob/living/seated_mob, seat)
	if(!seated_mob.client)
		return
	add_verb(seated_mob, list(
		/obj/vehicle/multitile/proc/get_status_info,
		/obj/vehicle/multitile/proc/open_controls_guide,
		/obj/vehicle/multitile/proc/name_vehicle,
	))
	if(seat == VEHICLE_DRIVER)
		add_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/toggle_door_lock,
			/obj/vehicle/multitile/proc/activate_horn,
		))
	else if(seat == VEHICLE_GUNNER)
		add_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/switch_hardpoint,
			/obj/vehicle/multitile/proc/cycle_hardpoint,
		))

/obj/vehicle/multitile/apc/command/remove_seated_verbs(mob/living/seated_mob, seat)
	if(!seated_mob.client)
		return
	remove_verb(seated_mob, list(
		/obj/vehicle/multitile/proc/get_status_info,
		/obj/vehicle/multitile/proc/open_controls_guide,
		/obj/vehicle/multitile/proc/name_vehicle,
	))
	SStgui.close_user_uis(seated_mob, src)
	if(seat == VEHICLE_DRIVER)
		remove_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/toggle_door_lock,
			/obj/vehicle/multitile/proc/activate_horn,
		))
	else if(seat == VEHICLE_GUNNER)
		remove_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/switch_hardpoint,
			/obj/vehicle/multitile/proc/cycle_hardpoint,
		))

/*
** COMMAND APC PRESETS SPAWNERS
*/
/obj/effect/vehicle_spawner/apc/command
	name = "Command APC Spawner"
	icon_state = "apc_base_com"

/obj/effect/vehicle_spawner/apc/command/spawn_vehicle()
	var/obj/vehicle/multitile/apc/command/spawned_apc = new (loc)

	load_misc(spawned_apc)
	load_hardpoints(spawned_apc)
	handle_direction(spawned_apc)
	spawned_apc.update_appearance()

/obj/effect/vehicle_spawner/apc/command/load_hardpoints(obj/vehicle/multitile/apc/command/spawned_apc)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/locomotion/apc_wheels)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/primary/dualcannon)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/secondary/frontalcannon)

/obj/effect/vehicle_spawner/apc/command/decrepit/spawn_vehicle()
	var/obj/vehicle/multitile/apc/command/spawned_apc = new (loc)

	load_misc(spawned_apc)
	load_hardpoints(spawned_apc)
	handle_direction(spawned_apc)
	load_damage(spawned_apc)
	spawned_apc.update_appearance()

/*
 * The medical APC
 */
/obj/vehicle/multitile/apc/medical
	name = "M577-MED Armored Personnel Carrier"
	desc = "A medical modification of the M577 Armored Personnel Carrier. An armored transport with four big wheels. Designed as a reliable mobile triage that stores a significant amount of medical supplies for in-field resupplying of medics. Entrances on the sides."

	icon_state = "apc_base_med"

	interior_map = /datum/map_template/interior/apc_med

	passengers_slots = 8
	//MED APC can store additional 6 dead revivable bodies for the triage
	//but interior won't allow more revivable dead if passengers_taken_slots >= passengers_slots + revivable_dead_slots
	//to prevent infinitely growing the marine force inside of the vehicle
	revivable_dead_slots = 6

	entrances = list(
		"left" = list(2, 0),
		"right" = list(-2, 0)
	)

	seats = list(
		VEHICLE_DRIVER = null,
		VEHICLE_GUNNER = null,
	)

	active_hp = list(
		VEHICLE_DRIVER = null,
		VEHICLE_GUNNER = null,
	)

/obj/vehicle/multitile/apc/medical/load_role_reserved_slots()
	var/datum/role_reserved_slots/reserved_slots = new
	reserved_slots.category_name = "Crewmen"
	reserved_slots.roles = list("Vehicle Crewman", "Tank Crewman", "Crewman")
	reserved_slots.total = 2
	role_reserved_slots += reserved_slots

	reserved_slots = new
	reserved_slots.category_name = "Medical Support"
	reserved_slots.roles = list("Medical Doctor", "Chief Medical Officer", "Chemist", "Paramedic", "Coroner")
	reserved_slots.total = 1
	role_reserved_slots += reserved_slots

/obj/vehicle/multitile/apc/medical/add_seated_verbs(mob/living/seated_mob, seat)
	if(!seated_mob.client)
		return
	add_verb(seated_mob, list(
		/obj/vehicle/multitile/proc/get_status_info,
		/obj/vehicle/multitile/proc/open_controls_guide,
		/obj/vehicle/multitile/proc/name_vehicle,
	))
	if(seat == VEHICLE_DRIVER)
		add_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/toggle_door_lock,
			/obj/vehicle/multitile/proc/activate_horn,
		))
	else if(seat == VEHICLE_GUNNER)
		add_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/switch_hardpoint,
			/obj/vehicle/multitile/proc/cycle_hardpoint,
		))

/obj/vehicle/multitile/apc/medical/remove_seated_verbs(mob/living/seated_mob, seat)
	if(!seated_mob.client)
		return
	remove_verb(seated_mob, list(
		/obj/vehicle/multitile/proc/get_status_info,
		/obj/vehicle/multitile/proc/open_controls_guide,
		/obj/vehicle/multitile/proc/name_vehicle,
	))
	SStgui.close_user_uis(seated_mob, src)
	if(seat == VEHICLE_DRIVER)
		remove_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/toggle_door_lock,
			/obj/vehicle/multitile/proc/activate_horn,
		))
	else if(seat == VEHICLE_GUNNER)
		remove_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/switch_hardpoint,
			/obj/vehicle/multitile/proc/cycle_hardpoint,
		))

/*
** MEDICAL APC PRESETS SPAWNERS
*/
/obj/effect/vehicle_spawner/apc/medical
	name = "Medical APC Spawner"
	icon_state = "apc_base_med"

/obj/effect/vehicle_spawner/apc/medical/spawn_vehicle()
	var/obj/vehicle/multitile/apc/medical/spawned_apc = new (loc)

	load_misc(spawned_apc)
	load_hardpoints(spawned_apc)
	handle_direction(spawned_apc)
	spawned_apc.update_appearance()

/obj/effect/vehicle_spawner/apc/medical/load_hardpoints(obj/vehicle/multitile/apc/medical/spawned_apc)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/locomotion/apc_wheels)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/primary/dualcannon)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/secondary/frontalcannon)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/support/flare_launcher)

/obj/effect/vehicle_spawner/apc/medical/decrepit/spawn_vehicle()
	var/obj/vehicle/multitile/apc/medical/spawned_apc = new (loc)

	load_misc(spawned_apc)
	load_hardpoints(spawned_apc)
	handle_direction(spawned_apc)
	load_damage(spawned_apc)
	spawned_apc.update_appearance()

/*
 * The PMC APC
 */
/obj/vehicle/multitile/apc/pmc
	name = "M577-B Armored Personnel Carrier"
	desc = "An M577 Armored Personnel Carrier variant in white and black W-Y corporate colors. Entrances on the sides and back."

	icon = '_horizon/icons/vehicles/obj/apc_pmc.dmi'
	icon_state = "hull_wy"
	pixel_x = -48
	pixel_y = -48

	interior_map = /datum/map_template/interior/apc_pmc

/obj/vehicle/multitile/apc/pmc/load_role_reserved_slots()
	var/datum/role_reserved_slots/reserved_slots = new
	reserved_slots.category_name = "PMC Crewmen"
	reserved_slots.roles = list("Vehicle Crewman", "Tank Crewman", "Crewman", "Security Officer")
	reserved_slots.total = 2
	role_reserved_slots += reserved_slots

/*
** PMC APC PRESETS SPAWNERS
*/
/obj/effect/vehicle_spawner/apc/pmc
	name = "PMC APC Spawner"
	icon = '_horizon/icons/vehicles/obj/apc_pmc.dmi'
	icon_state = "hull_wy"
	pixel_x = -48
	pixel_y = -48

/obj/effect/vehicle_spawner/apc/pmc/spawn_vehicle()
	var/obj/vehicle/multitile/apc/pmc/spawned_apc = new (loc)

	load_misc(spawned_apc)
	load_fpw(spawned_apc)
	load_hardpoints(spawned_apc)
	handle_direction(spawned_apc)
	spawned_apc.update_appearance()

/obj/effect/vehicle_spawner/apc/pmc/load_hardpoints(obj/vehicle/multitile/apc/pmc/spawned_apc)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/locomotion/apc_wheels/pmc)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/primary/dualcannon/pmc)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/secondary/frontalcannon/pmc)
	spawned_apc.add_hardpoint(new /obj/item/hardpoint/support/flare_launcher)
