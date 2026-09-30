/*
 * Weapons loader, ported from cmss13 code/modules/vehicles/interior/interactable/weapons_loader.dm
 * Interior machine that reloads vehicle hardpoints from spare magazines.
 */

/obj/structure/weapons_loader
	name = "ammunition loader"
	desc = "A hefty piece of machinery that sorts, moves and loads various ammunition into the correct guns."
	icon = '_horizon/icons/vehicles/obj/interiors/general.dmi'
	icon_state = "weapons_loader"

	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

	var/obj/vehicle/multitile/vehicle = null

// Loading new magazines
/obj/structure/weapons_loader/attackby(obj/item/I, mob/user, list/modifiers, list/attack_modifiers)
	if(!istype(I, /obj/item/ammo_magazine/hardpoint))
		return ..()

	// Check if any of the hardpoints accept the magazine
	var/obj/item/hardpoint/reloading_hardpoint = null
	for(var/obj/item/hardpoint/H in vehicle.get_hardpoints_with_ammo())
		if(QDELETED(H) || QDELETED(H.ammo))
			continue

		if(istype(I, H.ammo.type))
			reloading_hardpoint = H
			break

	if(isnull(reloading_hardpoint))
		return ..()

	// Reload the hardpoint
	reloading_hardpoint.try_add_clip(I, user)

// Hardpoint reloading
/obj/structure/weapons_loader/attack_hand(mob/user, list/modifiers)

	if(!user || !ismob(user))
		return

	handle_reload(user)

/obj/structure/weapons_loader/proc/reload_ammo()
	set name = "Reload Ammo"
	set category = "Object"
	set src in range(1)

	var/mob/user = usr
	if(!user || !ismob(user))
		return

	handle_reload(user)

/obj/structure/weapons_loader/proc/handle_reload(mob/user)

	//something went bad, try to reconnect to vehicle if user is currently buckled in a vehicle seat
	if(!vehicle)
		if(istype(user.buckled, /obj/structure/chair/comfy/vehicle))
			var/obj/structure/chair/comfy/vehicle/seat = user.buckled
			vehicle = seat.vehicle
		if(!istype(vehicle))
			to_chat(user, span_warning("Critical Error! Ahelp this! Code: T_VMIS"))
			return

	var/list/hps = vehicle.get_hardpoints_with_ammo()

	if(!LAZYLEN(hps))
		to_chat(user, span_warning("None of the hardpoints can be reloaded!"))
		return

	var/chosen_hp = tgui_input_list(user, "Select a hardpoint", "Hardpoint Menu", (hps + "Cancel"))
	if(isnull(chosen_hp) || chosen_hp == "Cancel")
		return

	var/obj/item/hardpoint/HP = chosen_hp

	// If someone removed the hardpoint while their dialogue was open or something
	if(QDELETED(HP))
		to_chat(user, span_warning("Error! Module not found!"))
		return

	if(!LAZYLEN(HP.backup_clips))
		to_chat(user, span_warning("[HP] has no remaining backup magazines!"))
		return

	var/obj/item/ammo_magazine/M = LAZYACCESS(HP.backup_clips, 1)
	if(!M)
		to_chat(user, span_danger("Something went wrong! Ahelp this! Code: T_BMIS"))
		return

	to_chat(user, span_notice("You begin reloading [HP]."))

	if(!do_after(user, 1 SECONDS, target = src))
		to_chat(user, span_warning("Something interrupted you while reloading [HP]."))
		return

	HP.ammo.forceMove(get_turf(src))
	HP.ammo.update_appearance()
	HP.ammo = M
	LAZYREMOVE(HP.backup_clips, M)

	playsound(loc, '_horizon/sounds/machines/hydraulics_3.ogg', 50)
	to_chat(user, span_notice("You reload [HP]. Ammo: <b>[HP.ammo.current_rounds]/[HP.ammo.max_rounds]</b> | Mags: <b>[LAZYLEN(HP.backup_clips)]/[HP.max_clips]</b>"))

/obj/structure/weapons_loader/wy
	icon = '_horizon/icons/vehicles/obj/interiors/general_wy.dmi'
