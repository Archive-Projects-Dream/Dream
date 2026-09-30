/*
 * Vehicle seats, ported from cmss13 code/modules/vehicles/interior/interactable/seats.dm
 * Adapted to Horizon-Dream's buckle API (post_buckle_mob/post_unbuckle_mob).
 */

// Crew seats for general vehicles.
/obj/structure/chair/comfy/vehicle
	name = "seat"
	desc = "A seat bolted to the vehicle floor."

	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	anchored = TRUE
	item_chair = null

	//you want these chairs to not be easily obscured by objects
	layer = BELOW_MOB_LAYER

	// The vehicle this seat is tied to
	var/obj/vehicle/multitile/vehicle = null

	// Which seat this is in the vehicle
	var/seat = null

	/// The client view size the rider had before buckling
	var/stored_view = null

	/// cooldown for re-buckling to prevent seat spam
	COOLDOWN_DECLARE(seat_cooldown)

/obj/structure/chair/comfy/vehicle/MakeRotate()
	return // vehicle seats are bolted down; no player rotation

/obj/structure/chair/comfy/vehicle/Initialize(mapload)
	. = ..()
	if(!istype(vehicle))
		return
	RegisterSignal(vehicle, COMSIG_QDELETING, PROC_REF(vehicle_deleted))

/obj/structure/chair/comfy/vehicle/proc/vehicle_deleted(datum/source)
	SIGNAL_HANDLER
	vehicle = null

/obj/structure/chair/comfy/vehicle/Destroy()
	if(vehicle && has_buckled_mobs())
		for(var/mob/living/M in buckled_mobs)
			unbuckle_mob(M, TRUE)
	vehicle = null
	return ..()

/obj/structure/chair/comfy/vehicle/ex_act(severity)
	return

/obj/structure/chair/comfy/vehicle/handle_layer()
	if(has_buckled_mobs() && dir == NORTH)
		layer = ABOVE_MOB_LAYER
	else
		layer = BELOW_MOB_LAYER

/obj/structure/chair/comfy/vehicle/handle_rotation(direction)
	handle_layer()
	if(has_buckled_mobs())
		for(var/m in buckled_mobs)
			var/mob/living/buckled_mob = m
			buckled_mob.setDir(direction)

/obj/structure/chair/comfy/vehicle/post_buckle_mob(mob/living/M)
	. = ..()
	if(!vehicle)
		return
	if(M.stat == DEAD)
		unbuckle_mob(M, TRUE)
		return
	vehicle.set_seated_mob(seat, M)
	if(M.client)
		stored_view = M.client.view
		M.client.change_view(7)

/obj/structure/chair/comfy/vehicle/unbuckle_mob(mob/living/buckled_mob, force = FALSE, can_fall = TRUE)
	. = ..()
	if(!.)
		return
	if(vehicle)
		vehicle.set_seated_mob(seat, null)
	if(buckled_mob?.client)
		if(stored_view)
			buckled_mob.client.change_view(stored_view)
			stored_view = null
		buckled_mob.reset_perspective()

// Pass movement relays to the vehicle
/obj/structure/chair/comfy/vehicle/relaymove(mob/living/user, direction)
	if(vehicle)
		return vehicle.relaymove(user, direction)

/obj/structure/chair/comfy/vehicle/user_buckle_mob(mob/living/M, mob/user, check_loc = TRUE)
	if(!vehicle)
		return FALSE
	if(!COOLDOWN_FINISHED(src, seat_cooldown))
		return FALSE
	COOLDOWN_START(src, seat_cooldown, 1 SECONDS)
	return ..()

// Driver's seat
/obj/structure/chair/comfy/vehicle/driver
	name = "driver's seat"
	desc = "Comfortable seat for a driver."
	seat = VEHICLE_DRIVER

// Gunner seat
/obj/structure/chair/comfy/vehicle/gunner
	name = "gunner's seat"
	desc = "Comfortable seat for a gunner."
	seat = VEHICLE_GUNNER

//custom vehicle seats for armored vehicles
//spawners located in interior_landmarks

/obj/structure/chair/comfy/vehicle/driver/armor
	desc = "Military-grade seat for armored vehicle driver with some controls, switches and indicators."
	var/image/over_image = null

/obj/structure/chair/comfy/vehicle/driver/armor/Initialize(mapload)
	over_image = image(icon, src, "armor_chair_buckled")
	over_image.layer = ABOVE_MOB_LAYER

	return ..()

/obj/structure/chair/comfy/vehicle/driver/armor/update_appearance(updates)
	. = ..()
	if(has_buckled_mobs())
		add_overlay(over_image)

/obj/structure/chair/comfy/vehicle/gunner/armor
	desc = "Military-grade seat for armored vehicle gunner with some controls, switches and indicators."
	var/image/over_image = null

/obj/structure/chair/comfy/vehicle/gunner/armor/Initialize(mapload)
	over_image = image(icon, src, "armor_chair_buckled")
	over_image.layer = ABOVE_MOB_LAYER

	return ..()

/obj/structure/chair/comfy/vehicle/gunner/armor/update_appearance(updates)
	. = ..()
	if(has_buckled_mobs())
		add_overlay(over_image)

//armored vehicles support gunner seat

/obj/structure/chair/comfy/vehicle/support_gunner
	name = "left support gunner's seat"
	desc = "Military-grade seat for a support gunner with some controls, switches and indicators."
	seat = VEHICLE_SUPPORT_GUNNER_ONE

	var/image/over_image = null

/obj/structure/chair/comfy/vehicle/support_gunner/Initialize(mapload)
	over_image = image(icon, src, "armor_chair_buckled")
	over_image.layer = ABOVE_MOB_LAYER

	return ..()

/obj/structure/chair/comfy/vehicle/support_gunner/update_appearance(updates)
	. = ..()
	if(has_buckled_mobs())
		add_overlay(over_image)

/obj/structure/chair/comfy/vehicle/support_gunner/second
	name = "right support gunner's seat"
	seat = VEHICLE_SUPPORT_GUNNER_TWO

//ARMORED VEHICLES PASSENGER SEATS
//Unique feature - you can put two seats on same tile with different pixel_offsets, humans will be buckled with respective offsets
//and only when both seats taken, seats will be made dense and, therefore, tile will become unpassible

//DOES NOT SUPPORT MORE THAN TWO SEATS ON TILE
/obj/structure/chair/vehicle
	name = "passenger seat"
	desc = "A sturdy chair with a brace that lowers over your body. Prevents being flung around in vehicle during crash being injured as a result. Fasten your seatbelts, kids! Fix with welding tool in case of damage."
	icon = '_horizon/icons/vehicles/obj/interiors/general.dmi'
	icon_state = "vehicle_seat"
	item_chair = null
	buildstacktype = null

	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	anchored = TRUE

	var/image/chairbar = null
	// Plain assignment: /obj/structure already declares var/broken in TG
	broken = FALSE

	var/buckle_offset_x = 0
	var/mob_old_x = 0
	var/buckle_offset_y = 0
	var/mob_old_y = 0

	var/init_pixel_y
	var/init_pixel_x
	var/higher_layer

/obj/structure/chair/vehicle/MakeRotate()
	return // vehicle seats are bolted down; no player rotation

/obj/structure/chair/vehicle/Initialize(mapload)
	. = ..()
	chairbar = image(icon, src, "vehicle_bars")
	chairbar.layer = ABOVE_MOB_LAYER

	addtimer(CALLBACK(src, PROC_REF(setup_buckle_offsets)), 1 SECONDS)

	handle_rotation()

	init_pixel_y = pixel_y
	init_pixel_x = pixel_x

/obj/structure/chair/vehicle/proc/setup_buckle_offsets()
	if(pixel_x != 0)
		buckle_offset_x = pixel_x
	if(pixel_y != 0)
		buckle_offset_y = pixel_y

/obj/structure/chair/vehicle/handle_rotation(direction)
	if(dir == NORTH)
		layer = FLY_LAYER
	else
		if(higher_layer)
			layer = BELOW_MOB_LAYER + 0.01
		else
			layer = BELOW_MOB_LAYER
	if(has_buckled_mobs())
		for(var/m in buckled_mobs)
			var/mob/living/buckled_mob = m
			buckled_mob.setDir(direction)

/obj/structure/chair/vehicle/handle_layer()
	return

//------BUCKLING AND UNBUCKLING
//trying to buckle a mob
/obj/structure/chair/vehicle/user_buckle_mob(mob/living/M, mob/user, check_loc = TRUE)
	if(broken)
		to_chat(user, span_warning("[src] is broken and requires fixing with a welder!"))
		return FALSE

	return ..()

/obj/structure/chair/vehicle/unbuckle_mob(mob/living/buckled_mob, force = FALSE, can_fall = TRUE)
	// restore seat pixel offsets before the mob reference is gone from buckled_mobs
	if(buckle_offset_x != 0)
		buckled_mob.pixel_x = mob_old_x
		mob_old_x = 0
	if(buckle_offset_y != 0)
		buckled_mob.pixel_y = mob_old_y
		mob_old_y = 0
	return ..()

/obj/structure/chair/vehicle/post_buckle_mob(mob/living/M)
	. = ..()

	if(has_buckled_mobs())
		icon_state = initial(icon_state) + "_buckled"
		add_overlay(chairbar)

		if(buckle_offset_x != 0)
			mob_old_x = M.pixel_x
			M.pixel_x = buckle_offset_x
		if(buckle_offset_y != 0)
			mob_old_y = M.pixel_y
			M.pixel_y = buckle_offset_y
	else
		icon_state = initial(icon_state)
		cut_overlay(chairbar)

	for(var/obj/structure/chair/vehicle/VS in get_turf(src))
		if(VS != src)
			//if both seats on same tile have buckled mob, we become dense, otherwise, not dense.
			if(has_buckled_mobs())
				if(VS.has_buckled_mobs())
					VS.density = TRUE
					density = TRUE
			else
				VS.density = FALSE
			break

	handle_rotation()

/obj/structure/chair/vehicle/post_unbuckle_mob()
	. = ..()

	icon_state = initial(icon_state)
	cut_overlay(chairbar)

	for(var/obj/structure/chair/vehicle/VS in get_turf(src))
		if(VS != src)
			VS.density = FALSE
			density = FALSE
			break

	handle_rotation()

//attack handling
/obj/structure/chair/vehicle/welder_act(mob/living/user, obj/item/tool)
	if(user.combat_mode || !broken)
		return ITEM_INTERACT_SKIP_TO_ATTACK

	if(!tool.tool_start_check(user, amount=1))
		return ITEM_INTERACT_BLOCKING

	user.visible_message(span_warning("[user] begins repairing [src]."), span_warning("You begin repairing [src]."))
	if(!tool.use_tool(src, user, 2 SECONDS, volume=50))
		return ITEM_INTERACT_BLOCKING

	if(broken)
		user.visible_message(span_warning("[user] repairs [src]."), span_warning("You repair [src]."))
		broken = FALSE
		icon_state = initial(icon_state)
	return ITEM_INTERACT_SUCCESS

//breaking and repairing seats
/obj/structure/chair/vehicle/proc/break_seat()
	broken = TRUE
	if(has_buckled_mobs())
		for(var/mob/living/M in buckled_mobs)
			unbuckle_mob(M, TRUE)
	icon_state = "vehicle_seat_destroyed"

/obj/structure/chair/vehicle/proc/repair_seat()
	broken = FALSE
	icon_state = initial(icon_state)

//MISC

/obj/structure/chair/vehicle/ex_act(severity)
	if(broken)
		return
	switch(severity)
		if(EXPLODE_DEVASTATE)
			break_seat()
		if(EXPLODE_HEAVY)
			if(prob(60))
				break_seat()
		if(EXPLODE_LIGHT)
			if(prob(20))
				break_seat()

// White chairs

/obj/structure/chair/vehicle/white
	name = "passenger seat"
	desc = "A sturdy chair with a brace that lowers over your body. Prevents being flung around in vehicle during crash being injured as a result. Fasten your seatbelts, kids! Fix with welding tool in case of damage."
	icon = '_horizon/icons/vehicles/obj/interiors/general_wy.dmi'
