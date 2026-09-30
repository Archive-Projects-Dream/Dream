/*
 * Vehicle viewports, ported from cmss13 code/modules/vehicles/interior/interactable/viewports.dm
 * Lets a crewmember look out through the vehicle's external cameras.
 */

/obj/structure/interior_viewport
	name = "External Cameras Terminal"
	desc = "A small terminal connected to the external cameras of a vehicle, allowing a 360-degree visual survey of vehicle surroundings."
	icon = '_horizon/icons/vehicles/obj/interiors/general.dmi'
	icon_state = "viewport"
	layer = INTERIOR_DOOR_LAYER

	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	anchored = TRUE

	// The vehicle this viewport is tied to
	var/obj/vehicle/multitile/vehicle = null

/obj/structure/interior_viewport/ex_act(severity)
	return

/obj/structure/interior_viewport/attack_hand(mob/M, list/modifiers)
	if(!vehicle)
		return

	M.reset_perspective(vehicle)

/obj/structure/interior_viewport/wy
	icon = '_horizon/icons/vehicles/obj/interiors/general_wy.dmi'

/obj/structure/interior_viewport/simple
	name = "viewport"
	desc = "Hey, I can see my base from here!"
	icon_state = "viewport_simple"

//van's frontal window viewport
/obj/structure/interior_viewport/simple/windshield
	name = "windshield"
	desc = "When was it cleaned last time? There is a squashed bug in the corner."
	icon = '_horizon/icons/vehicles/obj/interiors/van.dmi'
	icon_state = "windshield_viewport_top"
	alpha = 80
