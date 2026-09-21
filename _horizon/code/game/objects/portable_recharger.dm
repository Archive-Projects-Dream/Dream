// Экипировка СБ
/*
//	Переносной зарядник - предмет для переноски
/obj/item/recharger_item
	name = "portable recharging station"
	desc = "A portable dual-port weapon recharger. It draws power from the station grid, with a built-in battery serving as a backup. To begin operation, deploy it in any suitable location."
	icon = 'white/Feline/icons/sec_recharger.dmi'
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
	attack_verb_continuous = list("робастит")
	attack_verb_simple = list("робастит")
	hitsound = 'sound/weapons/smash.ogg'
	drop_sound = 'sound/items/handling/toolbox_drop.ogg'
	pickup_sound =  'sound/items/handling/toolbox_pickup.ogg'
	max_integrity = 200
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, RAD = 100, FIRE = 100, ACID = 30)
	resistance_flags = FIRE_PROOF
	wound_bonus = 5
	var/cell_charge = 10000
	var/cell_maxcharge = 10000
	var/cond_tier = 1

//	Разворачивание станции
/obj/item/recharger_item/afterattack(obj/target, mob/user , proximity)
	. = ..()
	if(!proximity)
		return
	if(user.a_intent == INTENT_HELP)
		if(isopenturf(target))
			deploy_recharger(user, target)

/obj/item/recharger_item/proc/deploy_recharger(mob/user, atom/location)
	var/obj/machinery/recharger/portable/R = new /obj/machinery/recharger/portable(location)
	R.port_cell.maxcharge = cell_maxcharge
	R.port_cell.charge = cell_charge
	R.recharge_coeff = cond_tier
	R.add_fingerprint(user)
	user.visible_message(span_notice("[user] разворачивает зарядную станцию.") , span_notice("Разворачиваю зарядную станцию."))
	flick("sec-deploy", R)
	playsound(R,'white/Feline/sounds/recharger_deploy.ogg', 60, FALSE)
	qdel(src)

//	Осмотр чемоданчика
/obj/item/recharger_item/examine(mob/user)
	. = ..()
	if(!in_range(user, src) && !issilicon(user) && !isobserver(user))
		. += "<hr><span class='warning'>Слишком далеко, чтобы рассмотреть дисплей зарядной станции!</span>"
		return
	. += "<hr><span class='notice'>Дисплей:</span>"
	. += "</br><span class='notice'>- Уроверь батареи <b>[cell_charge*100/cell_maxcharge]%</b>.</span>"

//	Переносной зарядник - развернутая машина
/obj/machinery/recharger/portable
	name = "portable recharging station"
	desc = "A portable dual-port weapon recharger. It draws power from the station grid, with a built-in battery serving as a backup. It can be folded up for transport when needed."
	icon = 'white/Feline/icons/sec_recharger.dmi'
	icon_state = "sec"
	base_icon_state = "sec"
	circuit = /obj/item/circuitboard/machine/portable_recharger
	portable = TRUE
	use_power = NO_POWER_USE

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

// 	Сворачивание станции

/obj/machinery/recharger/portable/MouseDrop(over_object, src_location, over_location)
	. = ..()
	if(over_object == usr && Adjacent(usr))
		if(!ishuman(usr) || !usr.can_perform_action(src, BE_CLOSE))
			return FALSE
		if(charging || charging_port2)
			to_chat(usr, span_warning("Невозможно свернуть зарядную станцию в процессе зарядки!"))
			return FALSE
		usr.visible_message(span_notice("[usr] сворачивает зарядную станцию.") , span_notice("Сворачиваю зарядную станцию."))
		var/obj/item/recharger_item/B = new /obj/item/recharger_item(src.drop_location())
		flick("sec-move", B)
		playsound(B, 'white/Feline/sounds/recharger_go.ogg', 60, FALSE)
		B.cell_maxcharge = port_cell.maxcharge
		B.cell_charge = port_cell.charge
		B.cond_tier = recharge_coeff
		qdel(src)

//  Оверлеи зарядки
/obj/machinery/recharger/portable/update_overlays()
	. = ..()
	var/area/a = get_area(src)
	if(machine_stat & (NOPOWER|BROKEN) || !anchored)
		return
	if(panel_open)						// панель снята
		. += mutable_appearance(icon, "[base_icon_state]-open", layer)
		. += emissive_appearance(icon, "[base_icon_state]-open", src, alpha = src.alpha)
		return

	if(port_cell)						// уровень батареи
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
		if(port_cell.percent() != 0)	// рабочая сеть
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

	if(charging)							// порт 1
		if(port_cell.percent() != 0)
			var/port_1_cell_percent
			var/port_1_cell_percent_num
			if(istype(charging, /obj/item/tactical_recharger))	// вычисление % заряда имитатора
				var/obj/item/tactical_recharger/CI = charging
				port_1_cell_percent_num = CI.cell_imitator_lvl*100/CI.cell_imitator_max
			else
				var/obj/item/stock_parts/power_store/cell/C = charging.get_cell()	// запрос к реальной батарее
				port_1_cell_percent_num = C.percent()
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

			if(using_power)						// в процессе
				. += mutable_appearance(icon, "[base_icon_state]-p1-charging", layer)
				. += emissive_appearance(icon, "[base_icon_state]-p1-charging", src, alpha = src.alpha)
			else								// завершен
				. += mutable_appearance(icon, "[base_icon_state]-p1-full", layer)
				. += emissive_appearance(icon, "[base_icon_state]-p1-full", src, alpha = src.alpha)
		else
			if(!isarea(a) || a.power_equip == 0)	// питания нет, внутренняя батарея пуста
				. += mutable_appearance(icon, "[base_icon_state]-p1-cell-fail", layer)
				. += emissive_appearance(icon, "[base_icon_state]-p1-cell-fail", src, alpha = src.alpha)


	if(charging_port2)						// порт 2
		if(port_cell.percent() != 0)
			var/port_2_cell_percent
			var/port_2_cell_percent_num
			if(istype(charging_port2, /obj/item/tactical_recharger))	// вычисление % заряда имитатора
				var/obj/item/tactical_recharger/CI2 = charging_port2
				port_2_cell_percent_num = CI2.cell_imitator_lvl*100/CI2.cell_imitator_max
			else
				var/obj/item/stock_parts/power_store/cell/C2 = charging_port2.get_cell()	// запрос к реальной батарее
				port_2_cell_percent_num = C2.percent()
			switch(port_2_cell_percent_num)			// процент заряда оружия
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

			if(using_power2)					// в процессе
				. += mutable_appearance(icon, "[base_icon_state]-p2-charging", layer)
				. += emissive_appearance(icon, "[base_icon_state]-p2-charging", src, alpha = src.alpha)
			else								// завершен
				. += mutable_appearance(icon, "[base_icon_state]-p2-full", layer)
				. += emissive_appearance(icon, "[base_icon_state]-p2-full", src, alpha = src.alpha)
		else
			if(!isarea(a) || a.power_equip == 0)	// питания нет, внутренняя батарея пуста
				. += mutable_appearance(icon, "[base_icon_state]-p2-cell-fail", layer)
				. += emissive_appearance(icon, "[base_icon_state]-p2-cell-fail", src, alpha = src.alpha)
*/

//  Тактический наспинный зарядник
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
		to_chat(user, span_warning("Крепления расстегнуты, [capitalize(src.name)] пуст."))

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
