/*
 * Interior hull walls and roofs, ported from cmss13 code/modules/vehicles/interior/interior_hull.dm
 * These sit beyond the walking area and stay out of the way of shots and movement.
 */

/obj/structure/interior_wall
	name = "interior wall"
	desc = "An interior wall."
	icon = '_horizon/icons/vehicles/obj/interiors/tank.dmi'
	density = TRUE
	opacity = TRUE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = INTERIOR_WALL_LAYER
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
/obj/structure/interior_wall/ex_act(severity)
	return
//roof for small vehicles to emphasize small space

/obj/effect/vehicle_roof
	name = "interior roof"
	desc = "An interior roof."
	icon = '_horizon/icons/vehicles/obj/interiors/tank.dmi'
	density = FALSE
	opacity = FALSE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER + 0.1
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	alpha = 80
/obj/effect/vehicle_roof/ex_act(severity)
	return
/*
 * Per-vehicle hull subtypes referenced by the interior maps.
 */
/obj/structure/interior_wall/tank
	icon = '_horizon/icons/vehicles/obj/interiors/tank.dmi'
/obj/structure/interior_wall/van
	icon = '_horizon/icons/vehicles/obj/interiors/van.dmi'
/obj/structure/interior_wall/clf_van
	icon = '_horizon/icons/vehicles/obj/interiors/clf_van.dmi'
/obj/structure/interior_wall/box_van
	icon = '_horizon/icons/vehicles/obj/interiors/box_van_interior.dmi'
/obj/structure/interior_wall/pizza_van
	icon = '_horizon/icons/vehicles/obj/interiors/pizza_van_interior.dmi'
/obj/structure/interior_wall/apc
	icon = '_horizon/icons/vehicles/obj/interiors/apc.dmi'
/obj/structure/interior_wall/apc_pmc
	icon = '_horizon/icons/vehicles/obj/interiors/apc_pmc.dmi'
/obj/effect/vehicle_roof/van
	icon = '_horizon/icons/vehicles/obj/interiors/van.dmi'
	icon_state = "roof_1"
/obj/effect/vehicle_roof/clf_van
	icon = '_horizon/icons/vehicles/obj/interiors/clf_van.dmi'
	icon_state = "roof_1"
/obj/effect/vehicle_roof/box_van
	icon = '_horizon/icons/vehicles/obj/interiors/box_van_interior.dmi'
	icon_state = "roof_1"
/obj/effect/vehicle_roof/pizza_van
	icon = '_horizon/icons/vehicles/obj/interiors/pizza_van_interior.dmi'
	icon_state = "roof_1"
/*
 * Simple interior props (ported from cmss13 /obj/structure/prop/tank).
 * Purely visual dressing mapped inside interiors.
 */
/obj/structure/prop
	name = "prop"
	desc = "A piece of equipment bolted to the floor."
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	density = FALSE
/obj/structure/prop/tank
	name = "tank equipment"
	desc = "An assorted piece of machinery inside a tank."
	icon = '_horizon/icons/vehicles/obj/interiors/tank.dmi'
	icon_state = "prop0_extra"
/*
 * Wall telephone, ported from cmss13 /obj/structure/transmitter.
 * Functions as a fixed intercom-style radio usable by the crew.
 */
/obj/structure/transmitter
	name = "telephone"
	desc = "A wall-mounted telephone. Lets you talk over the station radio channels."
	icon = '_horizon/icons/vehicles/obj/interiors/general.dmi'
	icon_state = "wall_phone"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER - 0.1
	/// Name used to identify this phone in messages
	var/phone_id = "Vehicle"
	/// Category grouping phones into switchboards (cosmetic, kept for map compat)
	var/phone_category = "Vehicles"
/obj/structure/transmitter/attack_hand(mob/user, list/modifiers)
	if(!isliving(user))
		return
	var/obj/item/radio/intercom/phone_radio = new(src)
	phone_radio.name = name
	phone_radio.broadcasting = TRUE
	phone_radio.listening = TRUE
	user.put_in_hands(phone_radio)
	to_chat(user, span_notice("You pick up [src]'s handset."))
	RegisterSignal(phone_radio, COMSIG_QDELETING, PROC_REF(radio_returned))
/obj/structure/transmitter/proc/radio_returned(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_QDELETING)
/obj/structure/transmitter/ex_act(severity)
	return