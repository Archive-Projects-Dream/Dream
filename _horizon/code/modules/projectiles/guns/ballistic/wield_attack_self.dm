/obj/item/gun/ballistic/attack_self(mob/living/user, modifiers)
	if(wielded_inhand_state && user?.is_holding(src) && istype(user, /mob/living/carbon))
		var/datum/component/two_handed/two_handed_component = GetComponent(/datum/component/two_handed)
		if(two_handed_component)
			if(two_handed_component.wielded)
				two_handed_component.unwield(user)
			else
				two_handed_component.wield(user)
			return
	// Non-wieldable guns: fall through to upstream rack/eject logic.
	if(!internal_magazine && magazine)
		if(!magazine.ammo_count())
			eject_magazine(user)
			return
	if(bolt_type == BOLT_TYPE_NO_BOLT)
		unload_ammo(user)
		return
	if(bolt_type == BOLT_TYPE_LOCKING && bolt_locked)
		drop_bolt(user)
		return
	if(recent_rack > world.time)
		return
	recent_rack = world.time + rack_delay
	rack(user)

/obj/item/gun/ballistic/attack_self_secondary(mob/living/user, modifiers)
	if(safety_flags & GUN_SAFETY_HAS_SAFETY)
		toggle_safety(user)
		return TRUE
	return ..()

