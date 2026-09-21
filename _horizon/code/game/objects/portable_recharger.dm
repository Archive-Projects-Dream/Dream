// MARK: Portable Recharger
/obj/item/recharger_item
	name = "portable recharging station"
	desc = "A portable dual-port weapon recharger. It draws power from the station grid, with a built-in battery serving as a backup. To begin operation, deploy it in any suitable location."
	icon = '_horizon/code/game/objects/structures/sec_recharger.dmi'
	icon_state = "case"
	inhand_icon_state = "toolbox_default"
	lefthand_file = 'icons/mob/inhands/equipment/toolbox_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/toolbox_righthand.dmi'
	force = 15
	throwforce = 12
	throw_speed = 2
	throw_range = 7
	w_class = WEIGHT_CLASS_BULKY
	custom_materials = list(/datum/material/iron = 500)
	attack_verb_continuous = list("robusts")
	attack_verb_simple = list("robust")
	hitsound = 'sound/items/weapons/smash.ogg'
	drop_sound = 'sound/items/handling/toolbox/toolbox_drop.ogg'
	pickup_sound =  'sound/items/handling/toolbox/toolbox_pickup.ogg'
	max_integrity = 200
	//armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, RAD = 100, FIRE = 100, ACID = 30)
	resistance_flags = FIRE_PROOF
	wound_bonus = 5
	var/cell_charge = 10000
	var/cell_maxcharge = 10000
	var/cond_tier = 1

//	Разворачивание станции

/obj/item/recharger_item/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isopenturf(interacting_with))
		return NONE

	var/turf/target_turf = interacting_with
	if(!user.Adjacent(target_turf))
		return NONE
	if(target_turf.is_blocked_turf(source_atom = src))
		balloon_alert(user, "No space to deploy here.")
		return ITEM_INTERACT_BLOCKING

	deploy_recharger(user, target_turf)
	return ITEM_INTERACT_SUCCESS

/obj/item/recharger_item/proc/deploy_recharger(mob/user, atom/location)
	var/obj/machinery/recharger/portable/R = new /obj/machinery/recharger/portable(location)
	R.cell_charge = cell_charge
	R.cell_maxcharge = cell_maxcharge
	R.recharge_coeff = cond_tier
	R.add_fingerprint(user)
	user.visible_message(span_notice("[user] deploys the recharging station."), span_notice("You deploy the recharging station."))
	flick("sec-deploy", R)
	playsound(R, '_horizon/sound/recharger_deploy.ogg', 60, FALSE)
	qdel(src)

/obj/item/recharger_item/examine(mob/user)
	. = ..()
	if(!in_range(user, src) && !issilicon(user) && !isobserver(user))
		. += "<hr><span class='warning'>Too far away to make out the recharging station's display!</span>"
		return
	. += "<span class='notice'>Display:</span>"
	. += "<span class='notice'>- Battery level: <b>[cell_charge*100/cell_maxcharge]%</b>.</span>"

// MARK: Portable Recharger Machine
/obj/machinery/recharger/portable
	name = "portable recharging station"
	desc = "A portable dual-port weapon recharger. It draws power from the station grid, with a built-in battery serving as a backup. It can be folded up for transport when needed."
	icon = '_horizon/code/game/objects/structures/sec_recharger.dmi'
	icon_state = "sec"
	base_icon_state = "sec"
	circuit = /obj/item/circuitboard/machine/portable_recharger
	use_power = NO_POWER_USE
	var/obj/item/charging_port2 = null
	var/using_power2 = FALSE
	var/portable = TRUE
	var/cell_charge = 0
	var/cell_maxcharge = 0

//  Микросхема
/obj/item/circuitboard/machine/portable_recharger
	name = "portable recharging station"
	desc = "A portable dual-port weapon recharger. It draws power from the station grid, with a built-in battery serving as a backup. To begin operation, deploy it in any suitable location."
	greyscale_colors = CIRCUIT_COLOR_SECURITY
	build_path = /obj/machinery/recharger/portable
	req_components = list(
		/obj/item/stock_parts/capacitor = 2,
		/obj/item/stock_parts/power_store/cell = 1,
		)
	def_components = list(/obj/item/stock_parts/power_store/cell = /obj/item/stock_parts/power_store/cell/high)
	needs_anchored = FALSE

/obj/machinery/recharger/portable/process(delta_time)
    . = ..()

    if(charging_port2)
        var/obj/item/stock_parts/power_store/cell/C2 = charging_port2.get_cell()

        if(C2 && C2.charge < C2.maxcharge)
            using_power2 = TRUE

            var/charge_amount = C2.chargerate * recharge_coeff * delta_time
            C2.give(charge_amount)
            charging_port2.update_appearance()
        else
            using_power2 = FALSE

    else
        using_power2 = FALSE

    update_appearance()

/obj/machinery/recharger/portable/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	if(!is_type_in_typecache(arrived, allowed_devices))
		return

	// Первый порт.
	if(isnull(charging))
		charging = arrived
		START_PROCESSING(SSmachines, src)
		update_use_power(ACTIVE_POWER_USE)
		using_power = TRUE
		update_appearance()
		return

	// Второй порт.
	if(isnull(charging_port2))
		charging_port2 = arrived
		START_PROCESSING(SSmachines, src)
		update_use_power(ACTIVE_POWER_USE)
		using_power2 = TRUE
		update_appearance()
		return

/obj/machinery/recharger/portable/Exited(atom/movable/gone, direction)
	// Второй порт обрабатываем отдельно.
	if(gone == charging_port2)
		if(!QDELING(gone))
			gone.update_appearance()

		charging_port2 = null
		using_power2 = FALSE

		// Первый порт всё ещё может работать.
		if(charging)
			update_use_power(ACTIVE_POWER_USE)
		else
			update_use_power(IDLE_POWER_USE)

		update_appearance()
		return

	// Первый порт.
	if(gone == charging)
		if(!QDELING(gone))
			gone.update_appearance()

		charging = null
		using_power = FALSE

		// Если второй порт занят — станция всё ещё активна.
		if(charging_port2)
			update_use_power(ACTIVE_POWER_USE)
		else
			update_use_power(IDLE_POWER_USE)

		update_appearance()
		return

/obj/machinery/recharger/portable/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!is_type_in_typecache(tool, allowed_devices))
		return NONE

	if(!anchored)
		to_chat(user, span_notice("[src] isn't connected to anything!"))
		return ITEM_INTERACT_BLOCKING

	if(panel_open)
		return ITEM_INTERACT_BLOCKING

	// Оба порта заняты.
	if(charging && charging_port2)
		return ITEM_INTERACT_BLOCKING

	var/area/our_area = get_area(src)
	if(!isarea(our_area) || our_area.power_equip == 0)
		to_chat(user, span_notice("[src] blinks red as you try to insert [tool]."))
		return ITEM_INTERACT_BLOCKING

	if(istype(tool, /obj/item/gun/energy))
		var/obj/item/gun/energy/energy_gun = tool

		if(!energy_gun.can_charge)
			to_chat(user, span_notice("Your gun has no external power connector."))
			return ITEM_INTERACT_BLOCKING

	if(!user.transferItemToLoc(tool, src))
		return ITEM_INTERACT_BLOCKING

	return ITEM_INTERACT_SUCCESS

/obj/machinery/recharger/portable/attack_hand(mob/user, list/modifiers)
	if(!charging)
		return ..()

	add_fingerprint(user)

	if(user.put_in_hands(charging))
		return

	charging.forceMove(drop_location())

/obj/machinery/recharger/portable/attack_hand_secondary(mob/user, list/modifiers)
	if(charging_port2)
		add_fingerprint(user)

		if(user.put_in_hands(charging_port2))
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

		charging_port2.forceMove(drop_location())
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	return ..()

/obj/machinery/recharger/portable/MouseDrop(atom/over_object)
	. = ..()
	if(.)
		return
	if(!ishuman(usr) || !usr.can_perform_action(src))
		return FALSE
	if(charging || charging_port2)
		to_chat(usr, span_warning("Remove the charging items first!"))
		return FALSE
	usr.visible_message(span_notice("[usr] folds up the recharging station."), span_notice("You fold up the recharging station."))
	var/obj/item/recharger_item/B = new /obj/item/recharger_item(src.drop_location())
	flick("sec-move", B)
	playsound(B, '_horizon/sound/recharger_go.ogg', 60, FALSE)
	var/obj/item/stock_parts/power_store/cell/port_cell = locate(/obj/item/stock_parts/power_store/cell) in component_parts
	if(port_cell)
		B.cell_maxcharge = port_cell.maxcharge
		B.cell_charge = port_cell.charge
	B.cond_tier = recharge_coeff
	qdel(src)

/obj/machinery/recharger/portable/screwdriver_act(mob/living/user, obj/item/tool)
	if(charging || charging_port2)
		return ITEM_INTERACT_BLOCKING
	return ..()

/obj/machinery/recharger/portable/can_crowbar_deconstruct()
	return ..() && !charging && !charging_port2

//  Оверлеи зарядки
/obj/machinery/recharger/portable/update_overlays()
	. = ..()
	var/area/a = get_area(src)
	var/obj/item/stock_parts/power_store/cell/port_cell = locate(/obj/item/stock_parts/power_store/cell) in component_parts

	if(machine_stat & (NOPOWER|BROKEN) || !anchored)
		return
	if(panel_open)
		. += mutable_appearance(icon, "[base_icon_state]-open", layer)
		. += emissive_appearance(icon, "[base_icon_state]-open", src, alpha = src.alpha)
		return

	if(port_cell)
		var/cell_percent
		switch(port_cell.percent())
			if(0 to 14)
				cell_percent = "1"
			if(15 to 28)
				cell_percent = "2"
			if(29 to 42)
				cell_percent = "3"
			if(43 to 56)
				cell_percent = "4"
			if(57 to 70)
				cell_percent = "5"
			if(71 to 84)
				cell_percent = "6"
			if(85 to 100)
				cell_percent = "7"

		. += mutable_appearance(icon, "[base_icon_state]-charge-[cell_percent]", layer)
		. += emissive_appearance(icon, "[base_icon_state]-charge-[cell_percent]", src, alpha = src.alpha)

		var/power_net
		if(port_cell.percent() != 0)
			if(!isarea(a) || a.power_equip == 0)
				power_net = "cell"
			else
				if(port_cell.percent() < 100)
					power_net = "rech"
				else
					power_net = "net"
		else
			power_net = "dead"
		. += mutable_appearance(icon, "[base_icon_state]-power-[power_net]", layer)
		. += emissive_appearance(icon, "[base_icon_state]-power-[power_net]", src, alpha = src.alpha)

	if(charging)
		if(port_cell && port_cell.percent() != 0)
			var/port_1_cell_percent
			var/port_1_cell_percent_num
			if(istype(charging, /obj/item/tactical_recharger))	// вычисление % заряда имитатора
				var/obj/item/tactical_recharger/CI = charging
				port_1_cell_percent_num = CI.cell_imitator_lvl*100/CI.cell_imitator_max
			else
				var/obj/item/stock_parts/power_store/cell/C = charging.get_cell()	// запрос к реальной батарее
				if(C)
					port_1_cell_percent_num = C.percent()
				else
					port_1_cell_percent_num = 0
			switch(port_1_cell_percent_num)		// процент заряда оружия
				if(0 to 14)
					port_1_cell_percent = "1"
				if(15 to 28)
					port_1_cell_percent = "2"
				if(29 to 42)
					port_1_cell_percent = "3"
				if(43 to 56)
					port_1_cell_percent = "4"
				if(57 to 70)
					port_1_cell_percent = "5"
				if(71 to 84)
					port_1_cell_percent = "6"
				if(85 to 100)
					port_1_cell_percent = "7"
			. += mutable_appearance(icon, "[base_icon_state]-p1-cell-[port_1_cell_percent]", layer)
			. += emissive_appearance(icon, "[base_icon_state]-p1-cell-[port_1_cell_percent]", src, alpha = src.alpha)

			if(using_power)
				. += mutable_appearance(icon, "[base_icon_state]-p1-charging", layer)
				. += emissive_appearance(icon, "[base_icon_state]-p1-charging", src, alpha = src.alpha)
			else
				. += mutable_appearance(icon, "[base_icon_state]-p1-full", layer)
				. += emissive_appearance(icon, "[base_icon_state]-p1-full", src, alpha = src.alpha)
		else
			if(!isarea(a) || a.power_equip == 0)
				. += mutable_appearance(icon, "[base_icon_state]-p1-cell-fail", layer)
				. += emissive_appearance(icon, "[base_icon_state]-p1-cell-fail", src, alpha = src.alpha)

	if(charging_port2)
		if(port_cell && port_cell.percent() != 0)
			var/port_2_cell_percent
			var/port_2_cell_percent_num
			if(istype(charging_port2, /obj/item/tactical_recharger))
				var/obj/item/tactical_recharger/CI2 = charging_port2
				port_2_cell_percent_num = CI2.cell_imitator_lvl*100/CI2.cell_imitator_max
			else
				var/obj/item/stock_parts/power_store/cell/C2 = charging_port2.get_cell()
				if(C2)
					port_2_cell_percent_num = C2.percent()
				else
					port_2_cell_percent_num = 0
			switch(port_2_cell_percent_num)
				if(0 to 14)
					port_2_cell_percent = "1"
				if(15 to 28)
					port_2_cell_percent = "2"
				if(29 to 42)
					port_2_cell_percent = "3"
				if(43 to 56)
					port_2_cell_percent = "4"
				if(57 to 70)
					port_2_cell_percent = "5"
				if(71 to 84)
					port_2_cell_percent = "6"
				if(85 to 100)
					port_2_cell_percent = "7"
			. += mutable_appearance(icon, "[base_icon_state]-p2-cell-[port_2_cell_percent]", layer)
			. += emissive_appearance(icon, "[base_icon_state]-p2-cell-[port_2_cell_percent]", src, alpha = src.alpha)

			if(using_power2)
				. += mutable_appearance(icon, "[base_icon_state]-p2-charging", layer)
				. += emissive_appearance(icon, "[base_icon_state]-p2-charging", src, alpha = src.alpha)
			else
				. += mutable_appearance(icon, "[base_icon_state]-p2-full", layer)
				. += emissive_appearance(icon, "[base_icon_state]-p2-full", src, alpha = src.alpha)
		else
			if(!isarea(a) || a.power_equip == 0)
				. += mutable_appearance(icon, "[base_icon_state]-p2-cell-fail", layer)
				. += emissive_appearance(icon, "[base_icon_state]-p2-cell-fail", src, alpha = src.alpha)

// MARK: Tactical Recharger
/obj/item/tactical_recharger
	name = "tactical weapon recharger"
	desc = "An advanced portable recharging station for energy weapons. Its charging rate is slightly lower than that of larger models, but using it still significantly extends the overall potential capacity of any energy weapon."
	icon = '_horizon/icons/obj/tactical_recharger.dmi'
	icon_state = "toz"
	worn_icon = '_horizon/icons/obj/in_mob/tactical_recharger_body.dmi'
	worn_icon_state = "toz"
	force = 15
	dog_fashion = null
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_SUITSTORE
	equip_sound = 'sound/items/equip/toolbelt_equip.ogg'

	var/cell_imitator_lvl = 2500
	var/cell_imitator_max = 2500
	var/chargerate = 100

	var/obj/item/charging = null
	var/using_power = FALSE
	var/recharge_coeff = 0.5

	var/overlay_state
	var/mutable_appearance/gun_overlay

/obj/item/tactical_recharger/examine(mob/user)
	. = ..()
	. += "<hr><span class='notice'>Display:</span>"
	. += "<span class='notice'>- Battery level: <b>[cell_imitator_lvl*100/cell_imitator_max]%</b>.</span>"
	if(charging)
		var/obj/item/stock_parts/power_store/cell/C = charging.get_cell()
		. += "<span class='notice'>- Weapon charge: <b>[charging]</b> - <b>[C.percent()]%</b>.</span>"

/datum/storage/pockets/tactical_recharger
	max_slots = 1
	max_specific_storage = WEIGHT_CLASS_BULKY
	rustle_sound = FALSE
	attack_hand_interact = TRUE

/datum/storage/pockets/tactical_recharger/New(atom/parent, max_slots, max_specific_storage, max_total_storage, numerical_stacking, allow_quick_gather, allow_quick_empty, collection_mode, attack_hand_interact)
	. = ..()
	set_holdable(list(
		/obj/item/gun/energy
	))

/obj/item/tactical_recharger/Initialize(mapload)
	. = ..()
	create_storage(storage_type = /datum/storage/pockets/tactical_recharger)
	START_PROCESSING(SSmachines, src)
	update_icon()
	update_appearance()

/obj/item/tactical_recharger/Destroy()
	. = ..()
	return PROCESS_KILL

/obj/item/tactical_recharger/attack_hand(mob/user)
	if(loc != user || user.get_item_by_slot(ITEM_SLOT_SUITSTORE) != src || !user.can_perform_action(src))
		return ..()

	if(length(contents))
		var/obj/item/I = contents[1]
		user.visible_message(span_notice("[user] draws [I] from the tactical recharger."), span_notice("You draw [I] from the tactical recharger."))
		I.forceMove(get_turf(loc))
		user.put_in_hands(I)
		update_appearance()
		update_icon()
		user.update_suit_storage()
	else
		to_chat(user, span_warning("The straps are unfastened, [capitalize(src.name)] is empty."))

	return ..()

/obj/item/tactical_recharger/update_icon_state()
	icon_state = initial(icon_state)
//	worn_icon_state = initial(worn_icon_state)
	gun_overlay = null
	overlay_state = null
	if(length(contents))
		var/obj/item/I = contents[1]
		charging = I
	else
		charging = null
	return ..()

// Процесс зарядки
/obj/item/tactical_recharger/process(delta_time)
	using_power = FALSE
	if(length(contents))
		var/obj/item/I = contents[1]
		charging = I
	else
		charging = null

	if(charging)
		var/obj/item/stock_parts/power_store/cell/C = charging.get_cell()
		if(C)
			if(C.charge < C.maxcharge)
				using_power = TRUE
				if(cell_imitator_lvl > 0)
					cell_imitator_lvl = cell_imitator_lvl - (C.chargerate * recharge_coeff * delta_time / 2)
					C.give(C.chargerate * recharge_coeff * delta_time / 2)
					charging.update_icon()
				else
					if(cell_imitator_lvl < 0)	// защита от отрицательных значений
						cell_imitator_lvl = 0
	update_icon()

/obj/item/tactical_recharger/update_overlays()
	. = ..()

	if(length(contents))
		var/obj/item/I = contents[1]
		var/mutable_appearance/gun_overlay = mutable_appearance(I.icon, I.icon_state)
		var/matrix/M = matrix()
		M.Turn(-90)
		M.Translate(2, 0)
		gun_overlay.transform = M
		. += gun_overlay

	if(charging)
		if(using_power)
			. += mutable_appearance(icon, "toz-charge", layer)
			. += emissive_appearance(icon, "toz-charge", src, alpha = src.alpha)
		else
			. += mutable_appearance(icon, "toz-full", layer)
			. += emissive_appearance(icon, "toz-full", src, alpha = src.alpha)

		var/w_cell_percent
		var/obj/item/stock_parts/power_store/cell/C = charging.get_cell()
		switch(C.percent())
			if(0 to 10)
				w_cell_percent = "1"
			if(11 to 20)
				w_cell_percent = "2"
			if(21 to 30)
				w_cell_percent = "3"
			if(31 to 40)
				w_cell_percent = "4"
			if(41 to 50)
				w_cell_percent = "5"
			if(51 to 60)
				w_cell_percent = "6"
			if(61 to 70)
				w_cell_percent = "7"
			if(71 to 80)
				w_cell_percent = "8"
			if(81 to 90)
				w_cell_percent = "9"
			if(91 to 100)
				w_cell_percent = "10"

		. += mutable_appearance(icon, "toz-w_lvl-[w_cell_percent]", layer)
		. += emissive_appearance(icon, "toz-w_lvl-[w_cell_percent]", src, alpha = src.alpha)

	var/cell_percent
	switch(cell_imitator_lvl*100/cell_imitator_max)
		if(0 to 14)
			cell_percent = "1"
		if(15 to 28)
			cell_percent = "2"
		if(29 to 42)
			cell_percent = "3"
		if(43 to 56)
			cell_percent = "4"
		if(57 to 70)
			cell_percent = "5"
		if(71 to 84)
			cell_percent = "6"
		if(85 to 100)
			cell_percent = "7"

	. += mutable_appearance(icon, "toz-c_lvl-[cell_percent]", layer)
	. += emissive_appearance(icon, "toz-c_lvl-[cell_percent]", src, alpha = src.alpha)

// MARK: Types Rechargers
/obj/item/tactical_recharger/pulse/Initialize(mapload)
	. = ..()
	new /obj/item/gun/energy/pulse(src)
	update_appearance()
