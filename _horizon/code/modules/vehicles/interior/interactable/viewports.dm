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
	if(!vehicle || QDELETED(vehicle))
		return

	M.reset_perspective(vehicle)
	// cmss13 also hands out the vehicle unbuckle action here so the
	// camera view can be stepped back out of; without it you would be
	// stuck looking outside forever
	if(!locate(/datum/action/vehicle/multitile_view) in M.actions)
		var/datum/action/vehicle/multitile_view/view_action = new()
		view_action.Grant(M)

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

/*
 * Vehicle unbuckle action, ported from cmss13
 * /datum/action/human_action/vehicle_unbuckle. Given to anyone whose camera
 * gets attached to a multitile vehicle (crew seats and interior viewports).
 * Activating it unbuckles seated crew, or returns a viewport user to their
 * own eyes; it also cleans itself up whenever the holder's perspective
 * resets for any other reason, exactly like the cmss13 original.
 */
/datum/action/vehicle/multitile_view
	name = "Vehicle Unbuckle"
	desc = "Climb out of the vehicle seat, or stop looking through the vehicle's cameras."
	button_icon = 'icons/mob/actions/actions_vehicle.dmi'
	button_icon_state = "vehicle_eject"
	check_flags = NONE

/datum/action/vehicle/multitile_view/Grant(mob/grant_to)
	. = ..()
	if(!owner)
		return
	// cmss13 parity: the button removes itself whenever the view resets
	RegisterSignal(owner, COMSIG_MOB_RESET_PERSPECTIVE, PROC_REF(on_view_reset), override = TRUE)

/datum/action/vehicle/multitile_view/Remove(mob/remove_from)
	UnregisterSignal(remove_from, COMSIG_MOB_RESET_PERSPECTIVE)
	return ..()

/datum/action/vehicle/multitile_view/proc/on_view_reset(mob/source)
	SIGNAL_HANDLER
	Remove(source)

/datum/action/vehicle/multitile_view/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return
	var/mob/living/viewer = owner
	if(QDELETED(viewer))
		return FALSE
	// Buckled into a crew seat: unbuckle (that resets the view as well)
	if(istype(viewer.buckled, /obj/structure/chair/comfy/vehicle))
		var/obj/structure/chair/comfy/vehicle/crew_seat = viewer.buckled
		crew_seat.unbuckle_mob(viewer, TRUE)
		return TRUE
	// Just watching through the cameras: back to our own eyes
	viewer.reset_perspective()
	return TRUE
