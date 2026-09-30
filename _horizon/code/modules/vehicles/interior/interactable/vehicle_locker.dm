/*
 * Wall-mounted storage compartments, ported from cmss13
 * code/modules/vehicles/interior/interactable/vehicle_locker.dm
 *
 * cmss13 used its own /obj/item/storage/internal datum, which doesn't exist
 * in Horizon-Dream; this port uses the TG storage datum (create_storage)
 * instead. Access restriction matches job titles of the occupant's mind.
 */

/obj/structure/vehicle_locker
	name = "wall-mounted storage compartment"
	desc = "Small storage unit allowing vehicle crewmen to store their personal possessions or weaponry ammunition. Only vehicle crewmen can access these."
	icon = '_horizon/icons/vehicles/obj/interiors/general.dmi'
	icon_state = "locker"
	anchored = TRUE
	density = FALSE
	layer = 3.2

	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

	/// Job titles allowed to access the locker; empty means anyone
	var/list/role_restriction = list("Vehicle Crewman", "Tank Crewman", "Crewman")

/obj/structure/vehicle_locker/Initialize(mapload)
	. = ..()
	create_storage(
		max_slots = 21,
		max_specific_storage = WEIGHT_CLASS_BULKY,
		max_total_storage = 40 * WEIGHT_CLASS_TINY,
		canthold = list(
			/obj/item/storage/box,
			/obj/item/tank,
		)
	)
	atom_storage.allow_quick_gather = FALSE
	atom_storage.allow_quick_empty = FALSE
	atom_storage.attack_hand_interact = FALSE
	atom_storage.animated = FALSE

/// Quick-empty verb for the locker
/obj/structure/vehicle_locker/proc/empty_storage()
	set name = "Empty"
	set category = "Object"
	set src in range(0)

	var/mob/living/user = usr
	if(!istype(user) || user.incapacitated())
		return

	if(!can_access(user))
		return

	if(!length(contents))
		to_chat(user, span_warning("[src] is already empty."))
		return

	user.visible_message(span_notice("[user] starts to empty \the [src]..."), span_notice("You start to empty \the [src]..."))
	if(!do_after(user, 2 SECONDS, target = src))
		user.visible_message(span_warning("[user] stops emptying \the [src]..."), span_warning("You stop emptying \the [src]..."))
		return

	atom_storage.remove_all(get_turf(user))
	user.visible_message(span_notice("[user] empties \the [src]."), span_notice("You empty \the [src]."))

/// Whether the given mob may open this locker
/obj/structure/vehicle_locker/proc/can_access(mob/living/user)
	if(!length(role_restriction))
		return TRUE
	var/job_title = user.mind?.assigned_role?.title
	if(!job_title || !(job_title in role_restriction))
		to_chat(user, span_warning("You cannot access \the [name]."))
		return FALSE
	return TRUE

/obj/structure/vehicle_locker/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!can_access(user))
		return
	atom_storage.open_storage(user)

/obj/structure/vehicle_locker/MouseDrop(atom/over_object, atom/src_location, atom/over_location, src_control, over_control, params)
	var/mob/living/user = usr
	if(!istype(user) || user.incapacitated())
		return
	if(!can_access(user))
		return
	// Dragging to self opens the storage; other drags behave normally
	if(over_object == user)
		atom_storage.open_storage(user)
		return
	return ..()

/obj/structure/vehicle_locker/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	if(!can_access(user))
		return
	return ..()

/obj/structure/vehicle_locker/ex_act(severity)
	return

/obj/structure/vehicle_locker/tank
	name = "storage compartment"
	desc = "Small storage unit allowing vehicle crewmen to store their personal possessions or weaponry ammunition. Only vehicle crewmen can access these."
	icon = '_horizon/icons/vehicles/obj/interiors/tank.dmi'
	icon_state = "locker"

/obj/structure/vehicle_locker/med
	name = "wall-mounted surgery kit storage"
	desc = "A small locker that securely stores a full surgical kit. ID-locked to medical staff."
	icon_state = "locker_med"
	role_restriction = list("Chief Medical Officer", "Medical Doctor", "Chemist", "Paramedic", "Coroner", "Medical Intern")

/obj/structure/vehicle_locker/med/Initialize(mapload)
	. = ..()
	atom_storage.max_specific_storage = WEIGHT_CLASS_SMALL
	atom_storage.max_total_storage = 24 * WEIGHT_CLASS_TINY
	atom_storage.set_holdable(
		list(
			/obj/item/scalpel,
			/obj/item/hemostat,
			/obj/item/retractor,
			/obj/item/cautery,
			/obj/item/bonesetter,
			/obj/item/stack/medical/bone_gel,
			/obj/item/circular_saw,
			/obj/item/surgicaldrill,
			/obj/item/stack/medical,
			/obj/item/stack/medical/mesh/advanced,
		)
	)

	new /obj/item/scalpel(src)
	new /obj/item/hemostat(src)
	new /obj/item/retractor(src)
	new /obj/item/cautery(src)
	new /obj/item/bonesetter(src)
	new /obj/item/stack/medical/bone_gel(src)
	new /obj/item/circular_saw(src)
	new /obj/item/surgicaldrill(src)
	new /obj/item/stack/medical/bruise_pack(src)
	new /obj/item/stack/medical/bruise_pack(src)
	new /obj/item/stack/medical/ointment(src)
	new /obj/item/stack/medical/wrap/gauze(src)
	new /obj/item/stack/medical/wrap/gauze(src)
	new /obj/item/stack/medical/mesh/advanced(src)

/obj/structure/vehicle_locker/pmc
	icon = '_horizon/icons/vehicles/obj/interiors/general_wy.dmi'
	role_restriction = list("Vehicle Crewman", "Tank Crewman", "Crewman", "Security Officer", "Head of Security", "Captain")
