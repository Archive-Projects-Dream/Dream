// horizon-dev-sync[bot] port
// Override /obj/item/gun/ballistic/attack_self to defer to the two_handed
// component's wield/unweld when the gun is wieldable (wielded_inhand_state).
//
// Upstream's /obj/item/gun/ballistic/attack_self does NOT call ..(), so
// /obj/item/proc/attack_self never runs, and COMSIG_ITEM_ATTACK_SELF never
// fires. This means the /datum/component/two_handed (which listens for that
// signal to wield/unwield) never gets a chance to run.
//
// We want Z (attack_self) on a heavy gun to TOGGLE WIELD, not rack the bolt.
// Racking is done via the unique_action verb (Space by default) or the
// "Rack" action button.
//
// For non-wieldable guns (pistols, SMGs without wielded_inhand_state), we
// fall through to upstream's normal rack/eject logic by calling ..()

/obj/item/gun/ballistic/attack_self(mob/living/user, modifiers)
        // Heavy two-handed guns: Z toggles wield/unwield instead of racking.
        if(wielded_inhand_state && user?.is_holding(src) && istype(user, /mob/living/carbon))
                var/datum/component/two_handed/two_handed_component = GetComponent(/datum/component/two_handed)
                if(two_handed_component)
                        if(two_handed_component.wielded)
                                two_handed_component.unwield(user)
                        else
                                two_handed_component.wield(user)
                        return
        // Non-wieldable guns: fall through to upstream rack/eject logic.
        // We can't just call ..() because upstream /obj/item/gun/ballistic/
        // attack_self is the override we're replacing. Re-implement the
        // upstream logic here.
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
