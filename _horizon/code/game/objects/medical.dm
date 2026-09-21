
// MARK: Пеналы

/obj/item/storage/belt/medipenal
	name = "пенал для медипенов"
	desc = "Компактный и очень удобный пенал вмещающий до 5 медипенов, специальная клипса позволяет закрепить его на карманах или поясе, а с его маленькими габаритами он поместится в коробке или аптечке."
	icon = '_horizon/icons/obj/medipenal.dmi'
	icon_state = "penal"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_SMALL
	max_integrity = 300
	equip_sound = 'sound/items/equip/toolbelt_equip.ogg'

/obj/item/storage/belt/medipenal/Initialize()
	. = ..()
	atom_storage.max_slots = 5
	atom_storage.max_specific_storage = WEIGHT_CLASS_NORMAL
	atom_storage.max_total_storage = 10
	atom_storage.set_holdable(list(
		/obj/item/reagent_containers/hypospray/medipen,
		/obj/item/reagent_containers/syringe
		))

/obj/item/storage/belt/medipenal/update_icon_state()
	. = ..()
	icon_state = initial(icon_state)
	worn_icon_state = initial(worn_icon_state)
	if(length(contents))
		icon_state = "penal[length(contents)]"

/obj/item/storage/belt/medipenal/attack_hand(mob/user, list/modifiers)
	if(loc == user)
		if((user.get_item_by_slot(ITEM_SLOT_BELT) == src) || (user.get_item_by_slot(ITEM_SLOT_LPOCKET) == src) || (user.get_item_by_slot(ITEM_SLOT_RPOCKET) == src))
			if(!user.can_perform_action(src)) // !user.canUseTopic(src, BE_CLOSE, NO_DEXTERITY, FALSE, TRUE))
				return
			atom_storage?.show_contents(user)
	else ..()
	return

/obj/item/storage/medkit/field_surgery
	name = "укладка полевого хирурга"
	desc = "Компактный набор самых необходимых медицинских инструментов для неотложного хирургического вмешательства в полевых условиях."
	icon_state = "medkit_tactical"
	inhand_icon_state = "medkit-tactical"
	damagetype_healed = HEAL_ALL_DAMAGE
	storage_type = /datum/storage/medkit/surgery/holding

/obj/item/storage/medkit/field_surgery/PopulateContents()
	if(empty)
		return
	var/static/items_inside = list(
		/obj/item/scalpel/advanced = 1,
		/obj/item/retractor/advanced = 1,
		/obj/item/cautery/advanced = 1,
		/obj/item/surgical_drapes = 1,
		/obj/item/reagent_containers/medigel/sterilizine = 1,
		/obj/item/bonesetter = 1,
		/obj/item/blood_filter = 1,
		/obj/item/breathing_bag=1,
		/obj/item/defibrillator/compact/loaded = 1,
		/obj/item/stack/medical/bone_gel = 1,
		/obj/item/stack/medical/wrap/sticky_tape/surgical = 1,
		/obj/item/healthanalyzer/super = 1)
	generate_items_inside(items_inside,src)

// MARK: Дыхательная груша
/obj/item/breathing_bag
	name = "дыхательная груша"
	desc = "Она же мешок Амбу — механическое ручное устройство для выполнения искусственной вентиляции лёгких."
	icon = '_horizon/icons/obj/med_items.dmi'
	icon_state = "breathing_bag"
	lefthand_file = 'icons/mob/inhands/clothing/masks_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/clothing/masks_righthand.dmi'
	inhand_icon_state = "m_mask"
	custom_materials = list(/datum/material/iron=5000, /datum/material/glass=2500)
	w_class = WEIGHT_CLASS_SMALL
	toolspeed = 1

/obj/item/breathing_bag/attack(mob/living/M, mob/user)
	if(M == user)
		return
	if (M.is_mouth_covered())
		to_chat(user, span_warning("Для произведения ИВЛ с пациента надо снять маску!"))
		return
	to_chat(user, span_notice("Прикладываю дыхательную маску к лицу [M.name].")) // [skloname(M.name, RODITELNI, M.gender)]."))
	if(!do_after(user, 30, user))
		to_chat(user, span_warning("Не получается!"))
		return
	. = ..()
	playsound(user,'_horizon/sound/breathing_bag.ogg', 100, TRUE)
	for(var/ivl in 1 to 15)
		if(!do_after(user, 10, user))
			return
		to_chat(user, span_notice("Произвожу искуственную вентиляцию легких!"))
		M.adjust_oxy_loss(-15)

/obj/item/storage/box/traitorbundledebug
	name = "box of traitor"
	icon_state = "syndiebox"
	illustration = "writing_syndie"

/obj/item/storage/box/traitorbundledebug/PopulateContents()
	var/static/items_inside = list(
		/obj/item/card/emag=1,\
		/obj/item/uplink/debug=1,\
		/obj/item/uplink/nuclear/debug=1,\
		/obj/item/flashlight/emp/debug=1,\
	)
	generate_items_inside(items_inside,src)

// MARK: Мед-Сканер

/obj/item/healthanalyzer/range
	name = "long-range health analyzer"
	desc = "A handheld body scanner capable of accurately detecting the patient's vital signs from a distance."
	icon = '_horizon/icons/obj/tools.dmi'
	lefthand_file = '_horizon/icons/obj/in_hands/tools_lefthand.dmi'
	righthand_file = '_horizon/icons/obj/in_hands/tools_righthand.dmi'
	icon_state = "ranged_analyzer"
//	item_state = "ranged_analyzer"
//	healthmode = "ranged_analyzer"
//	reagentmode = "ranged_reagent_analyzer"
//	healthmodeinhand = "ranged_analyzer"
//	reagentmodeinhand = "ranged_reagent_analyzer"
	reach = 3
	custom_premium_price = 1000
