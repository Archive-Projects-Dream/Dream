/*
 * Locomotion hardpoints (wheels and treads), ported from cmss13
 * code/modules/vehicles/hardpoints/wheels/.dm
 *
 * cmss13's acid-spray environment damage for locomotion modules is not
 * ported (no xeno acid sprays in TG); the modules are otherwise identical.
 */

/obj/item/hardpoint/locomotion
	name = "locomotive aid hardpoint"
	desc = "I help the vehicle move :)"
	gender = PLURAL // it's always wheels or treads

	damage_multiplier = 0.15

	// these are used to change all vehicle's movement characteristics, 0 means no change
	var/move_delay = VEHICLE_SPEED_FASTNORMAL
	var/move_max_momentum = 0
	var/move_momentum_build_factor = 0
	var/move_turn_momentum_loss_factor = 0

/obj/item/hardpoint/locomotion/p_are(temp_gender)
	if(!temp_gender)
		temp_gender = gender
	. = "is"
	if(temp_gender == PLURAL)
		. = "are"

/obj/item/hardpoint/locomotion/deactivate()
	owner.move_delay = initial(owner.move_delay)
	owner.move_max_momentum = initial(owner.move_max_momentum)
	owner.move_momentum_build_factor = initial(owner.move_momentum_build_factor)
	owner.move_turn_momentum_loss_factor = initial(owner.move_turn_momentum_loss_factor)
	owner.next_move = world.time + move_delay

/obj/item/hardpoint/locomotion/on_install(obj/vehicle/multitile/vehicle)
	if(move_delay)
		vehicle.move_delay = move_delay
	if(move_max_momentum)
		vehicle.move_max_momentum = move_max_momentum
	if(move_momentum_build_factor)
		vehicle.move_momentum_build_factor = move_momentum_build_factor
	if(move_turn_momentum_loss_factor)
		vehicle.move_turn_momentum_loss_factor = move_turn_momentum_loss_factor
	vehicle.next_move = world.time + move_delay

/obj/item/hardpoint/locomotion/on_uninstall(obj/vehicle/multitile/vehicle)
	deactivate()

// Tank treads
/obj/item/hardpoint/locomotion/treads
	name = "\improper Treads"
	desc = "Integral to the movement of the vehicle. Steel reinforced rubber tracks, they allow the tank to move faster but in turn need repairs more often."

	icon_state = "treads"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "treads"

	slot = HDPT_TREADS

	max_integrity = 300

	//with this settings, takes 3 tiles to reach top speed
	move_delay = 3.8
	move_max_momentum = 3
	move_momentum_build_factor = 1.8
	move_turn_momentum_loss_factor = 0.6

/obj/item/hardpoint/locomotion/treads/robust
	name = "\improper Reinforced Treads"
	desc = "These treads are made of solid steel plates and are more durable. However, the extra weight slows the tank down."

	max_integrity = 500

	move_max_momentum = 5 //same top speed, but takes 5 tiles to reach it

/obj/item/hardpoint/locomotion/treads/on_install(obj/vehicle/multitile/vehicle)
	for(var/obj/item/hardpoint/support/overdrive_enhancer/overdrive_module in vehicle.hardpoints)
		if(overdrive_module.atom_integrity > 0)
			overdrive_module.apply_buff(vehicle)
	if(move_delay)
		vehicle.move_delay = move_delay
	if(move_max_momentum)
		vehicle.move_max_momentum = move_max_momentum
	if(move_momentum_build_factor)
		vehicle.move_momentum_build_factor = move_momentum_build_factor
	if(move_turn_momentum_loss_factor)
		vehicle.move_turn_momentum_loss_factor = move_turn_momentum_loss_factor

/obj/item/hardpoint/locomotion/treads/deactivate()
	for(var/obj/item/hardpoint/support/overdrive_enhancer/overdrive_module in owner.hardpoints)
		if(overdrive_module.atom_integrity > 0)
			overdrive_module.remove_buff(owner)
	owner.move_delay = initial(owner.move_delay)
	owner.move_max_momentum = initial(owner.move_max_momentum)
	owner.move_momentum_build_factor = initial(owner.move_momentum_build_factor)
	owner.move_turn_momentum_loss_factor = initial(owner.move_turn_momentum_loss_factor)

// Van wheels
/obj/item/hardpoint/locomotion/van_wheels
	name = "vehicle wheels"
	desc = "Integral to the movement of the van."
	icon = '_horizon/icons/vehicles/obj/hardpoints/van.dmi'

	icon_state = "tires"
	disp_icon = '_horizon/icons/vehicles/obj/van.dmi'
	disp_icon_state = "wheels"

	slot = HDPT_WHEELS

	max_integrity = 250

	move_delay = VEHICLE_SPEED_VERYFAST

// APC wheels
/obj/item/hardpoint/locomotion/apc_wheels
	name = "\improper APC Wheels"
	desc = "Integral to the movement of the APC."
	icon = '_horizon/icons/vehicles/obj/hardpoints/apc.dmi'

	damage_multiplier = 0.15

	icon_state = "tires"
	disp_icon = '_horizon/icons/vehicles/obj/apc.dmi'
	disp_icon_state = "wheels"

	max_integrity = 500

	move_delay = VEHICLE_SPEED_SUPERFAST
	move_max_momentum = 2
	move_momentum_build_factor = 1.5
	move_turn_momentum_loss_factor = 0.5

/obj/item/hardpoint/locomotion/apc_wheels/pmc
	icon_state = "tires_wy"
	disp_icon_state = "wheels_wy"

// ARC wheels
/obj/item/hardpoint/locomotion/arc_wheels
	name = "\improper ARC Wheels"
	desc = "Integral to the movement of the ARC."
	icon = '_horizon/icons/vehicles/obj/hardpoints/arc.dmi'

	damage_multiplier = 0.15

	icon_state = "tires"
	disp_icon = '_horizon/icons/vehicles/obj/arc.dmi'
	disp_icon_state = "arc_wheels"

	max_integrity = 500

	move_delay = VEHICLE_SPEED_SUPERFAST
	move_max_momentum = 2
	move_momentum_build_factor = 1.5
	move_turn_momentum_loss_factor = 0.5
