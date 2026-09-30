/*
 * Van variants, ported from cmss13 code/modules/vehicles/van/box_van.dm,
 * clf_van.dm and pizza_van.dm.
 *
 * In cmss13 these were siblings of /obj/vehicle/multitile/van that
 * duplicated the under-van/overdrive logic; here they are plain subtypes of
 * the ported van, which already carries that shared logic. Xeno weeds
 * momentum loss is not ported (no weeds in Horizon-Dream).
 */

/// Compact 2x2 cargo van.
/obj/vehicle/multitile/box_van
	name = "\improper box-van"
	desc = "A small box-type van. It's a compact vehicle with a rectangular cargo area, typically designed for transporting goods or small equipment. It features a high roof and straight sides, providing ample vertical space for storage. Its size makes it maneuverable and ideal for urban driving and tight spaces."

	icon = '_horizon/icons/vehicles/obj/box_van.dmi'
	icon_state = "van_base"
	pixel_x = 0
	pixel_y = 8

	interior_map = /datum/map_template/interior/box_van

	passengers_slots = 4
	xenos_slots = 2

	movement_sound = '_horizon/sounds/vehicles/box_van_driving.ogg'
	honk_sound = '_horizon/sounds/vehicles/box_van_horn.ogg'

	// Big critters can shake it around; small ones cannot meaningfully hit it
	mob_size_required_to_hit = MOB_SIZE_LARGE

/// CLF-upgraded technical: armored civilian truck.
/obj/vehicle/multitile/clf_van
	name = "CLF Technical"
	desc = "A repurposed civilian truck, plastered with CLF emblems and insignias. Armor plates have been attached on all sides, including the front windows. Bulletholes riddle the vehicle."

	icon = '_horizon/icons/vehicles/obj/clf_van.dmi'
	icon_state = "van_base"
	pixel_x = -16
	pixel_y = -16

	interior_map = /datum/map_template/interior/clf_van

	passengers_slots = 8
	xenos_slots = 2

	dmg_multipliers = list(
		"all" = 1,
		"acid" = 1,
		"slash" = 0.9,
		"bullet" = 0.8,
		"explosive" = 0.8,
		"blunt" = 0.8,
		"abstract" = 1
	)

	movement_sound = '_horizon/sounds/vehicles/tank_driving.ogg'
	honk_sound = '_horizon/sounds/vehicles/honk_2_truck.ogg'

	mob_size_required_to_hit = MOB_SIZE_LARGE

/// Pizza-Galaxy livery box-van.
/obj/vehicle/multitile/box_van/pizza_van
	name = "\improper box-van"

	icon = '_horizon/icons/vehicles/obj/pizza_van.dmi'

	interior_map = /datum/map_template/interior/pizza_van

/*
** PRESETS SPAWNERS
*/

/obj/effect/vehicle_spawner/box_van
	name = "Van Spawner"
	icon = '_horizon/icons/vehicles/obj/box_van.dmi'
	icon_state = "van_base"
	pixel_x = 0
	pixel_y = 8

/obj/effect/vehicle_spawner/box_van/Initialize(mapload)
	. = ..()
	spawn_vehicle()
	qdel(src)

//PRESET: no hardpoints
/obj/effect/vehicle_spawner/box_van/spawn_vehicle()
	var/obj/vehicle/multitile/box_van/spawned_van = new (loc)

	load_misc(spawned_van)
	handle_direction(spawned_van)
	spawned_van.update_appearance()

//PRESET: wheels installed, destroyed
/obj/effect/vehicle_spawner/box_van/decrepit/spawn_vehicle()
	var/obj/vehicle/multitile/box_van/spawned_van = new (loc)

	load_misc(spawned_van)
	load_hardpoints(spawned_van)
	handle_direction(spawned_van)
	load_damage(spawned_van)
	spawned_van.update_appearance()

/obj/effect/vehicle_spawner/box_van/decrepit/load_hardpoints(obj/vehicle/multitile/box_van/spawned_van)
	spawned_van.add_hardpoint(new /obj/item/hardpoint/locomotion/van_wheels)

//PRESET: wheels installed
/obj/effect/vehicle_spawner/box_van/fixed/spawn_vehicle()
	var/obj/vehicle/multitile/box_van/spawned_van = new (loc)

	load_misc(spawned_van)
	load_hardpoints(spawned_van)
	handle_direction(spawned_van)
	spawned_van.update_appearance()

/obj/effect/vehicle_spawner/box_van/fixed/load_hardpoints(obj/vehicle/multitile/box_van/spawned_van)
	spawned_van.add_hardpoint(new /obj/item/hardpoint/locomotion/van_wheels)

/obj/effect/vehicle_spawner/clf_van
	name = "CLF Van Spawner"
	icon = '_horizon/icons/vehicles/obj/clf_van.dmi'
	icon_state = "van_base"
	pixel_x = -16
	pixel_y = -16

/obj/effect/vehicle_spawner/clf_van/Initialize(mapload)
	. = ..()
	spawn_vehicle()
	qdel(src)

//PRESET: no hardpoints
/obj/effect/vehicle_spawner/clf_van/spawn_vehicle()
	var/obj/vehicle/multitile/clf_van/spawned_van = new (loc)

	load_misc(spawned_van)
	handle_direction(spawned_van)
	spawned_van.update_appearance()

//PRESET: wheels installed, destroyed
/obj/effect/vehicle_spawner/clf_van/decrepit/spawn_vehicle()
	var/obj/vehicle/multitile/clf_van/spawned_van = new (loc)

	load_misc(spawned_van)
	load_hardpoints(spawned_van)
	handle_direction(spawned_van)
	load_damage(spawned_van)
	spawned_van.update_appearance()

/obj/effect/vehicle_spawner/clf_van/decrepit/load_hardpoints(obj/vehicle/multitile/clf_van/spawned_van)
	spawned_van.add_hardpoint(new /obj/item/hardpoint/locomotion/van_wheels)

//PRESET: wheels installed
/obj/effect/vehicle_spawner/clf_van/fixed/spawn_vehicle()
	var/obj/vehicle/multitile/clf_van/spawned_van = new (loc)

	load_misc(spawned_van)
	load_hardpoints(spawned_van)
	handle_direction(spawned_van)
	spawned_van.update_appearance()

/obj/effect/vehicle_spawner/clf_van/fixed/load_hardpoints(obj/vehicle/multitile/clf_van/spawned_van)
	spawned_van.add_hardpoint(new /obj/item/hardpoint/locomotion/van_wheels)

/obj/effect/vehicle_spawner/box_van/pizza_van
	name = "Pizza-Galaxy Van Spawner"
	icon = '_horizon/icons/vehicles/obj/pizza_van.dmi'
	icon_state = "van_base"

//PRESET: no hardpoints
/obj/effect/vehicle_spawner/box_van/pizza_van/spawn_vehicle()
	var/obj/vehicle/multitile/box_van/pizza_van/spawned_van = new (loc)

	load_misc(spawned_van)
	handle_direction(spawned_van)
	spawned_van.update_appearance()

//PRESET: wheels installed, destroyed
/obj/effect/vehicle_spawner/box_van/pizza_van/decrepit/spawn_vehicle()
	var/obj/vehicle/multitile/box_van/pizza_van/spawned_van = new (loc)

	load_misc(spawned_van)
	load_hardpoints(spawned_van)
	handle_direction(spawned_van)
	load_damage(spawned_van)
	spawned_van.update_appearance()

/obj/effect/vehicle_spawner/box_van/pizza_van/decrepit/load_hardpoints(obj/vehicle/multitile/box_van/pizza_van/spawned_van)
	spawned_van.add_hardpoint(new /obj/item/hardpoint/locomotion/van_wheels)

//PRESET: wheels installed
/obj/effect/vehicle_spawner/box_van/pizza_van/fixed/spawn_vehicle()
	var/obj/vehicle/multitile/box_van/pizza_van/spawned_van = new (loc)

	load_misc(spawned_van)
	load_hardpoints(spawned_van)
	handle_direction(spawned_van)
	spawned_van.update_appearance()

/obj/effect/vehicle_spawner/box_van/pizza_van/fixed/load_hardpoints(obj/vehicle/multitile/box_van/pizza_van/spawned_van)
	spawned_van.add_hardpoint(new /obj/item/hardpoint/locomotion/van_wheels)
