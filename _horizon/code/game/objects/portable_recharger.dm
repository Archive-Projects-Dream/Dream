// MARK: Portable Recharger
/obj/item/recharger_item
	name = "portable recharging station"
	desc = "A portable dual-port weapon recharger. It draws power from the station grid, with a built-in battery serving as a backup. To begin operation, deploy it in any suitable location."
	icon = '_horizon/icons/obj/sec_recharger_portable.dmi'
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
	var/obj/item/stock_parts/power_store/cell/port_cell = locate(/obj/item/stock_parts/power_store/cell) in R.component_parts
	if(port_cell)
		port_cell.maxcharge = cell_maxcharge
		port_cell.charge = cell_charge
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
	icon = '_horizon/icons/obj/sec_recharger_portable.dmi'
	icon_state = "sec"
	base_icon_state = "sec"
	circuit = /obj/item/circuitboard/machine/portable_recharger
	use_power = NO_POWER_USE
	var/obj/item/charging2 = null
	var/using_power2 = FALSE
	var/portable = TRUE

// Микросхема
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

/obj/machinery/recharger/portable/process(seconds_per_tick)
	if(machine_stat & BROKEN || !anchored)
		return PROCESS_KILL

	using_power = FALSE
	using_power2 = FALSE

	var/area/a = get_area(src)
	var/has_grid_power = isarea(a) && a.power_equip != 0

	// Встроенная батарея станции. // Подзарядка встроенной батареи от сети.
	var/obj/item/stock_parts/power_store/cell/port_cell = locate(/obj/item/stock_parts/power_store/cell) in component_parts
	if(port_cell && port_cell.charge < port_cell.maxcharge && has_grid_power)
		port_cell.give(port_cell.chargerate * recharge_coeff * seconds_per_tick / 12)

	// Первый порт.
	if(charging)
		using_power = process_charging_port(charging, seconds_per_tick, port_cell, has_grid_power)

	// Второй порт.
	if(charging2)
		using_power2 = process_charging_port(charging2, seconds_per_tick, port_cell, has_grid_power)

	update_appearance()

	if(!charging && !charging2)
		return PROCESS_KILL

/obj/machinery/recharger/portable/proc/process_charging_port(obj/item/charging_item, seconds_per_tick, obj/item/stock_parts/power_store/cell/port_cell, has_grid_power)
	if(!charging_item)
		return FALSE

	// Обычная батарея предмета.
	var/obj/item/stock_parts/power_store/cell/charging_cell = charging_item.get_cell()
	if(charging_cell)
		if(charging_cell.charge >= charging_cell.maxcharge)
			return FALSE

		var/charge_amount = charging_cell.chargerate * recharge_coeff * seconds_per_tick

		if(has_grid_power)
			use_energy(active_power_usage * recharge_coeff * seconds_per_tick)
			charging_cell.give(charge_amount)
		else
			if(!port_cell || port_cell.charge <= 0)
				return FALSE

			var/backup_charge = min(charge_amount, port_cell.charge)
			port_cell.use(backup_charge)
			charging_cell.give(backup_charge)

		if(charging_cell.charge >= charging_cell.maxcharge)
			playsound(src, 'sound/machines/ping.ogg', 30, TRUE)
			say("[charging_item] has finished recharging!")
			charging_item.update_appearance()
			return FALSE

		charging_item.update_appearance()
		return TRUE

	// Перезаряжаемый магазин.
	if(istype(charging_item, /obj/item/ammo_box/magazine/recharge))
		var/obj/item/ammo_box/magazine/recharge/power_pack = charging_item
		for(var/charge_iterations in 1 to recharge_coeff)
			if(power_pack.stored_ammo.len >= power_pack.max_ammo)
				break
			if(has_grid_power)
				power_pack.stored_ammo += new power_pack.ammo_type(power_pack)
				use_energy(active_power_usage * seconds_per_tick)
			else
				if(!port_cell || port_cell.charge <= 0)
					break
				var/ammo_charge_cost = active_power_usage * seconds_per_tick
				if(port_cell.charge < ammo_charge_cost)
					break
				port_cell.use(ammo_charge_cost)
				power_pack.stored_ammo += new power_pack.ammo_type(power_pack)

		if(power_pack.stored_ammo.len >= power_pack.max_ammo)
			playsound(src, 'sound/machines/ping.ogg', 30, TRUE)
			say("[charging_item] has finished recharging!")
			charging_item.update_appearance()
			return FALSE

		charging_item.update_appearance()
		return power_pack.stored_ammo.len < power_pack.max_ammo

	// Боевой винтовочный recalibration.
	if(istype(charging_item, /obj/item/gun/ballistic/automatic/battle_rifle))
		var/obj/item/gun/ballistic/automatic/battle_rifle/recalibrating_gun = charging_item

		if(recalibrating_gun.degradation_stage)
			if(has_grid_power)
				recalibrating_gun.attempt_recalibration(FALSE)
				use_energy(active_power_usage * recharge_coeff * seconds_per_tick)
			else
				if(!port_cell || port_cell.charge <= 0)
					return FALSE

				var/recalibration_cost = active_power_usage * recharge_coeff * seconds_per_tick
				if(port_cell.charge < recalibration_cost)
					return FALSE

				port_cell.use(recalibration_cost)
				recalibrating_gun.attempt_recalibration(FALSE)

			charging_item.update_appearance()
			return TRUE

		if(recalibrating_gun.shots_before_degradation < recalibrating_gun.max_shots_before_degradation)
			if(has_grid_power)
				recalibrating_gun.attempt_recalibration(TRUE, recharge_coeff)
				use_energy(active_power_usage * recharge_coeff * seconds_per_tick)
			else
				if(!port_cell || port_cell.charge <= 0)
					return FALSE

				var/recalibration_cost = active_power_usage * recharge_coeff * seconds_per_tick
				if(port_cell.charge < recalibration_cost)
					return FALSE

				port_cell.use(recalibration_cost)
				recalibrating_gun.attempt_recalibration(TRUE, recharge_coeff)

			if(recalibrating_gun.shots_before_degradation >= recalibrating_gun.max_shots_before_degradation)
				playsound(src, 'sound/machines/ping.ogg', 30, TRUE)
				say("[charging_item] has finished recalibrating!")
				charging_item.update_appearance()
				return FALSE

			charging_item.update_appearance()
			return TRUE

		return FALSE

	return FALSE

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
	if(isnull(charging2))
		charging2 = arrived
		START_PROCESSING(SSmachines, src)
		update_use_power(ACTIVE_POWER_USE)
		using_power2 = TRUE
		update_appearance()
		return

/obj/machinery/recharger/portable/Exited(atom/movable/gone, direction)
	// Первый порт.
	if(gone == charging)
		if(!QDELING(gone))
			gone.update_appearance()

		charging = null
		using_power = FALSE

		// Если второй порт занят — станция всё ещё активна.
		if(charging2)
			update_use_power(ACTIVE_POWER_USE)
		else
			update_use_power(IDLE_POWER_USE)

		update_appearance()
		return

	// Второй порт обрабатываем отдельно.
	if(gone == charging2)
		if(!QDELING(gone))
			gone.update_appearance()

		charging2 = null
		using_power2 = FALSE

		if(charging)
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

	if(charging && charging2)
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

// MARK: Второго слота ПКМ
/obj/machinery/recharger/portable/attack_hand_secondary(mob/user, list/modifiers)
	if(charging2)
		add_fingerprint(user)

		if(user.put_in_hands(charging2))
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

		charging2.forceMove(drop_location())
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	return ..()

/obj/machinery/recharger/portable/MouseDrop(over_object, src_location, over_location)
	. = ..()
	if(.)
		return
	if(!ishuman(usr) || !usr.can_perform_action(src))
		return FALSE
	if(charging || charging2)
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
	if(charging || charging2)
		return ITEM_INTERACT_BLOCKING
	return ..()

/obj/machinery/recharger/portable/can_crowbar_deconstruct()
	return ..() && !charging && !charging2

//  Оверлеи зарядки
/obj/machinery/recharger/portable/update_overlays()
	. = ..()
	var/area/a = get_area(src)
	var/obj/item/stock_parts/power_store/cell/port_cell = locate(/obj/item/stock_parts/power_store/cell) in component_parts

	if(machine_stat & BROKEN || !anchored)
		return
	if(panel_open)
		. += mutable_appearance(icon, "[base_icon_state]-open", layer)
		. += emissive_appearance(icon, "[base_icon_state]-open", src, alpha = src.alpha)
		return

	if(port_cell)
		var/cell_percent
		switch(round(port_cell.percent()))
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
			var/obj/item/stock_parts/power_store/cell/charging_port1 = charging.get_cell()	// запрос к реальной батарее
			port_1_cell_percent_num = charging_port1 ? charging_port1.percent() : 0
			switch(round(port_1_cell_percent_num))
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

			var/icon_to_use = "[base_icon_state]-p1-[using_power ? "charging" : "full"]"
			. += mutable_appearance(icon, icon_to_use, layer)
			. += emissive_appearance(icon, icon_to_use, src, alpha = src.alpha)
		else
			if(!isarea(a) || a.power_equip == 0)
				. += mutable_appearance(icon, "[base_icon_state]-p1-cell-fail", layer)
				. += emissive_appearance(icon, "[base_icon_state]-p1-cell-fail", src, alpha = src.alpha)

	if(charging2)
		if(port_cell && port_cell.percent() != 0)
			var/port_2_cell_percent
			var/port_2_cell_percent_num
			var/obj/item/stock_parts/power_store/cell/charging_port2 = charging2.get_cell()
			port_2_cell_percent_num = charging_port2 ? charging_port2.percent() : 0
			switch(round(port_2_cell_percent_num))
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

			var/icon_to_use2 = "[base_icon_state]-p2-[using_power2 ? "charging" : "full"]"
			. += mutable_appearance(icon, icon_to_use2, layer)
			. += emissive_appearance(icon, icon_to_use2, src, alpha = src.alpha)
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
/obj/item/tactical_recharger/process(seconds_per_tick)
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
					cell_imitator_lvl = cell_imitator_lvl - (C.chargerate * recharge_coeff * seconds_per_tick / 2)
					C.give(C.chargerate * recharge_coeff * seconds_per_tick / 2)
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
