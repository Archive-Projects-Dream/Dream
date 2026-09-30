/*
 * The tank, ported from cmss13 code/modules/vehicles/tank/tank.dm and
 * code/modules/vehicles/tank/interior.dm
 *
 * Role-reserved slots use job title strings; since cmss13's job defines
 * don't exist here, the categories match on titles from configured jobs.
 * Xeno-only features (jumping over wrecks) are not ported.
 */

/obj/vehicle/multitile/tank
	name = "M34A2 Longstreet Light Tank"
	desc = "A giant piece of armor with a big gun, you know what to do. Entrance in the back."

	icon = '_horizon/icons/vehicles/obj/tank.dmi'
	icon_state = "tank_base"
	pixel_x = -48
	pixel_y = -48

	bound_width = 96
	bound_height = 96

	bound_x = -32
	bound_y = -32

	max_integrity = 1000

	interior_map = /datum/map_template/interior/tank

	//tank always has 2 crewmen slot reserved and 1 general slot for other roles.
	passengers_slots = 1
	//this is done in case VCs die inside the tank, so that someone else can come in and take them out.
	revivable_dead_slots = 2
	xenos_slots = 4

	entrances = list(
		"back" = list(0, 2)
	)

	movement_sound = '_horizon/sounds/vehicles/tank_driving.ogg'
	honk_sound = '_horizon/sounds/vehicles/honk_3_ambulence.ogg'

	vehicle_flags = VEHICLE_CLASS_MEDIUM

	move_max_momentum = 3
	move_momentum_build_factor = 1.8
	move_turn_momentum_loss_factor = 0.6

	vehicle_light_range = 7

	// Rest (all the guns) is handled by the tank turret hardpoint
	hardpoints_allowed = list(
		/obj/item/hardpoint/holder/tank_turret,
		/obj/item/hardpoint/support/weapons_sensor,
		/obj/item/hardpoint/support/overdrive_enhancer,
		/obj/item/hardpoint/support/artillery_module,
		/obj/item/hardpoint/armor/ballistic,
		/obj/item/hardpoint/armor/caustic,
		/obj/item/hardpoint/armor/concussive,
		/obj/item/hardpoint/armor/paladin,
		/obj/item/hardpoint/armor/snowplow,
		/obj/item/hardpoint/locomotion/treads,
		/obj/item/hardpoint/locomotion/treads/robust,
	)

	seats = list(
		VEHICLE_DRIVER = null,
		VEHICLE_GUNNER = null,
	)

	active_hp = list(
		VEHICLE_DRIVER = null,
		VEHICLE_GUNNER = null,
	)

	dmg_multipliers = list(
		"all" = 1,
		"acid" = 1.5, // Acid melts the tank
		"slash" = 0.7, // Slashing a massive, solid chunk of metal does very little except leave scratches
		"bullet" = 0.4,
		"explosive" = 0.8,
		"blunt" = 0.8,
		"abstract" = 1
	)

	explosive_resistance = 400

/obj/vehicle/multitile/tank/initialize_cameras(change_tag = FALSE)
	if(!camera)
		camera = new /obj/machinery/camera/vehicle(src)
	if(change_tag)
		camera.c_tag = "#[rand(1,100)] M34A2 \"[nickname]\" Tank" //this fluff allows it to be at the start of cams list
		if(camera_int)
			camera_int.c_tag = camera.c_tag + " interior" //this fluff allows it to be at the start of cams list
	else
		camera.c_tag = "#[rand(1,100)] M34A2 Tank"
		if(camera_int)
			camera_int.c_tag = camera.c_tag + " interior" //this fluff allows it to be at the start of cams list

/obj/vehicle/multitile/tank/load_role_reserved_slots()
	var/datum/role_reserved_slots/reserved_slots = new
	reserved_slots.category_name = "Crewmen"
	reserved_slots.roles = list("Vehicle Crewman", "Tank Crewman", "Crewman")
	reserved_slots.total = 2
	role_reserved_slots += reserved_slots

/obj/vehicle/multitile/tank/load_hardpoints()
	add_hardpoint(new /obj/item/hardpoint/holder/tank_turret)

/obj/vehicle/multitile/tank/add_seated_verbs(mob/living/seated_mob, seat)
	if(!seated_mob.client)
		return
	add_verb(seated_mob, list(
		/obj/vehicle/multitile/proc/switch_hardpoint,
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
			/obj/vehicle/multitile/proc/cycle_hardpoint,
			/obj/vehicle/multitile/proc/toggle_gyrostabilizer,
		))


/obj/vehicle/multitile/tank/remove_seated_verbs(mob/living/seated_mob, seat)
	if(!seated_mob.client)
		return
	remove_verb(seated_mob, list(
		/obj/vehicle/multitile/proc/get_status_info,
		/obj/vehicle/multitile/proc/open_controls_guide,
		/obj/vehicle/multitile/proc/name_vehicle,
		/obj/vehicle/multitile/proc/switch_hardpoint,
	))
	SStgui.close_user_uis(seated_mob, src)
	if(seat == VEHICLE_DRIVER)
		remove_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/toggle_door_lock,
			/obj/vehicle/multitile/proc/activate_horn,
		))
	else if(seat == VEHICLE_GUNNER)
		remove_verb(seated_mob, list(
			/obj/vehicle/multitile/proc/cycle_hardpoint,
			/obj/vehicle/multitile/proc/toggle_gyrostabilizer,
		))

//Called when players try to move vehicle
//Another wrapper for try_move()
/obj/vehicle/multitile/tank/relaymove(mob/user, direction)
	if(user == seats[VEHICLE_DRIVER])
		// Check if treads are installed
		if(!(locate(/obj/item/hardpoint/locomotion/treads) in hardpoints))
			return FALSE

		return ..()

	if(user != seats[VEHICLE_GUNNER])
		return FALSE

	var/obj/item/hardpoint/holder/tank_turret/turret = null
	for(var/obj/item/hardpoint/holder/tank_turret/installed_turret in hardpoints)
		turret = installed_turret
		break
	if(!turret)
		return FALSE

	if(direction == REVERSE_DIR(turret.dir) || direction == turret.dir)
		return FALSE

	turret.user_rotation(user, turning_angle(turret.dir, direction))
	update_appearance()

	return TRUE

/*
** PRESETS SPAWNERS
*/
/obj/effect/vehicle_spawner/tank
	name = "Tank Spawner"
	icon = '_horizon/icons/vehicles/obj/tank.dmi'
	icon_state = "tank_base"
	pixel_x = -48
	pixel_y = -48

/obj/effect/vehicle_spawner/tank/Initialize(mapload)
	. = ..()
	spawn_vehicle()
	qdel(src)

//PRESET: turret, no hardpoints (not the one without turret for convenience, you still expect to have turret when you spawn "no hardpoints tank")
/obj/effect/vehicle_spawner/tank/spawn_vehicle()
	var/obj/vehicle/multitile/tank/spawned_tank = new (loc)

	load_misc(spawned_tank)
	load_hardpoints(spawned_tank)
	handle_direction(spawned_tank)
	spawned_tank.update_appearance()

	return spawned_tank

/obj/effect/vehicle_spawner/tank/load_hardpoints(obj/vehicle/multitile/tank/spawned_tank)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/holder/tank_turret)

//PRESET: turret, treads installed
/obj/effect/vehicle_spawner/tank/plain/load_hardpoints(obj/vehicle/multitile/tank/spawned_tank)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/holder/tank_turret)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/locomotion/treads)

//PRESET: no hardpoints
/obj/effect/vehicle_spawner/tank/hull/load_hardpoints(obj/vehicle/multitile/tank/spawned_tank)
	return

//Just the hull and it's broken TOO, you get the full experience
/obj/effect/vehicle_spawner/tank/hull/broken/spawn_vehicle()
	var/obj/vehicle/multitile/tank/spawned_tank = ..()
	load_damage(spawned_tank)
	spawned_tank.update_appearance()

//PRESET: default hardpoints, destroyed
/obj/effect/vehicle_spawner/tank/decrepit/spawn_vehicle()
	var/obj/vehicle/multitile/tank/spawned_tank = new (loc)

	load_misc(spawned_tank)
	handle_direction(spawned_tank)
	load_hardpoints(spawned_tank)
	load_damage(spawned_tank)
	spawned_tank.update_appearance()

/obj/effect/vehicle_spawner/tank/decrepit/load_hardpoints(obj/vehicle/multitile/tank/spawned_tank)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/support/artillery_module)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/armor/paladin)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/locomotion/treads)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/holder/tank_turret)
	for(var/obj/item/hardpoint/holder/tank_turret/installed_turret in spawned_tank.hardpoints)
		installed_turret.add_hardpoint(new /obj/item/hardpoint/primary/cannon)
		installed_turret.add_hardpoint(new /obj/item/hardpoint/secondary/m56cupola)
		break

//PRESET: default hardpoints
/obj/effect/vehicle_spawner/tank/fixed/load_hardpoints(obj/vehicle/multitile/tank/spawned_tank)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/support/artillery_module)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/armor/paladin)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/locomotion/treads)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/holder/tank_turret)
	for(var/obj/item/hardpoint/holder/tank_turret/installed_turret in spawned_tank.hardpoints)
		installed_turret.add_hardpoint(new /obj/item/hardpoint/primary/cannon)
		installed_turret.add_hardpoint(new /obj/item/hardpoint/secondary/m56cupola)
		break

//PRESET: minigun kit
/obj/effect/vehicle_spawner/tank/fixed/minigun/load_hardpoints(obj/vehicle/multitile/tank/spawned_tank)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/support/artillery_module)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/armor/paladin)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/locomotion/treads)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/holder/tank_turret)
	for(var/obj/item/hardpoint/holder/tank_turret/installed_turret in spawned_tank.hardpoints)
		installed_turret.add_hardpoint(new /obj/item/hardpoint/primary/minigun)
		installed_turret.add_hardpoint(new /obj/item/hardpoint/secondary/m56cupola)
		break

//PRESET: autocannon kit
/obj/effect/vehicle_spawner/tank/fixed/autocannon/load_hardpoints(obj/vehicle/multitile/tank/spawned_tank)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/support/artillery_module)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/armor/paladin)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/locomotion/treads)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/holder/tank_turret)
	for(var/obj/item/hardpoint/holder/tank_turret/installed_turret in spawned_tank.hardpoints)
		installed_turret.add_hardpoint(new /obj/item/hardpoint/primary/autocannon)
		installed_turret.add_hardpoint(new /obj/item/hardpoint/secondary/m56cupola)
		break

//PRESET: flamer kit
/obj/effect/vehicle_spawner/tank/fixed/flamer/load_hardpoints(obj/vehicle/multitile/tank/spawned_tank)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/support/artillery_module)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/armor/paladin)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/locomotion/treads)
	spawned_tank.add_hardpoint(new /obj/item/hardpoint/holder/tank_turret)
	for(var/obj/item/hardpoint/holder/tank_turret/installed_turret in spawned_tank.hardpoints)
		installed_turret.add_hardpoint(new /obj/item/hardpoint/primary/flamer)
		installed_turret.add_hardpoint(new /obj/item/hardpoint/secondary/towlauncher)
		break
