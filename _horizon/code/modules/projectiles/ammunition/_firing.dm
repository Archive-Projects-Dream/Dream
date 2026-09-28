/obj/item/ammo_casing/ready_proj(atom/target, mob/living/user, quiet, zone_override = "", atom/fired_from)
        if(!loaded_projectile)
                return
        loaded_projectile.original = target
        loaded_projectile.firer = user
        loaded_projectile.fired_from = fired_from
        loaded_projectile.suppressed = quiet
        if(isitem(loaded_projectile.suppressed))
                loaded_projectile.suppressed = SUPPRESSED_NONE
        if(isgun(fired_from))
                var/obj/item/gun/gun = fired_from
                loaded_projectile.damage *= gun.projectile_damage_multiplier
                loaded_projectile.stamina *= gun.projectile_damage_multiplier
                loaded_projectile.ranged_modifier = gun.ranged_modifier
                loaded_projectile.ranged_zone_modifier = gun.ranged_zone_modifier

        //For chemical darts/bullets
        if(reagents && loaded_projectile.reagents)
                reagents.trans_to(loaded_projectile, reagents.total_volume, transfered_by = user)
                qdel(reagents)

        if(zone_override)
                loaded_projectile.def_zone = zone_override
        else
                loaded_projectile.def_zone = user.zone_selected
        if(ishuman(user))
                var/distance = get_dist(user, target)
                loaded_projectile.decayedRange = min(loaded_projectile.range, distance)
                loaded_projectile.range = min(loaded_projectile.range, distance)

/obj/item/ammo_casing/throw_proj(atom/target, turf/targloc, mob/living/user, params, spread, atom/fired_from)
        var/turf/curloc = get_turf(fired_from || user)
        if(!istype(targloc) || !istype(curloc) || !loaded_projectile)
                return FALSE

        var/firing_dir
        if(loaded_projectile.firer)
                firing_dir = get_dir(fired_from || user, target)
        if(!loaded_projectile.suppressed && firing_effect_type)
                new firing_effect_type(user || get_turf(src), firing_dir)

        var/direct_target
        if(target && curloc.Adjacent(targloc, target=targloc, mover=src))
                direct_target = target
        if(!direct_target)
                var/modifiers = params2list(params)
                loaded_projectile.aim_projectile(target, user, modifiers, spread)
        var/obj/projectile/loaded_projectile_cache = loaded_projectile
        loaded_projectile = null
        loaded_projectile_cache.fire(null, direct_target)
        return loaded_projectile_cache
