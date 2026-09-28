// horizon-dev-sync[bot] port
// Procs missing from upstream /tg/station codebase but called by horizon's
// _projectile.dm and blood.dm (legacy projectile API).

// =============================================================================
// /obj/projectile procs
// =============================================================================

/// Legacy: preparePixelProjectile() set up a projectile's pixel-precise
/// trajectory based on click params. Upstream moved this logic into fire().
/// This shim is a no-op so horizon's _firing.dm throw_proj() compiles.
/// Real trajectory setup happens in /obj/projectile/fire() upstream.
/obj/projectile/proc/preparePixelProjectile(atom/target, atom/source, modifiers, spread = 0)
        return

/// Legacy: Range() was called each time the projectile moved a tile.
/// Upstream uses Bump() / process_hit_loop() instead. We provide a no-op
/// stub so horizon's _projectile.dm override compiles; the override is
/// where the real behaviour lives.
/obj/projectile/proc/Range()
        return

// =============================================================================
// /mob/living procs
// =============================================================================

/// Legacy: check_limb_hit(zone) returned the bodypart that would be hit
/// in the given zone, considering miss chances. Upstream uses
/// get_bodypart(zone) directly. We delegate.
/mob/living/proc/check_limb_hit(zone)
        return get_bodypart(zone)

/// Legacy: on_hit(projectile) was called when a projectile hit this mob.
/// Upstream uses bullet_act() instead. We provide a no-op stub so
/// horizon's _projectile.dm call to `living_target.on_hit(src)` compiles.
/mob/living/proc/on_hit(obj/projectile/proj)
        return

// =============================================================================
// /turf procs
// =============================================================================

/// Legacy: get_projectile_hitsound(projectile) returned a sound to play
/// when a projectile hit this turf. Upstream removed this in favour of
/// hardcoded hitsound handling in /obj/projectile/on_hit(). We return
/// null so horizon's _projectile.dm falls back to default behaviour.
/turf/proc/get_projectile_hitsound(obj/projectile/proj)
        return null

/turf/closed/wall/get_projectile_hitsound(obj/projectile/proj)
        return 'sound/items/weapons/gun/general/ricochet.ogg'

/turf/open/floor/get_projectile_hitsound(obj/projectile/proj)
        return 'sound/items/weapons/gun/general/ricochet.ogg'

/// Legacy: add_dent(dent_type, x, y) added a bullet dent decal to the turf.
/// Upstream removed this from the base /turf type (only /turf/closed/wall
/// has it). We provide a no-op stub on /turf and /turf/open/floor so
/// horizon's _projectile.dm compiles. /turf/closed/wall already has a
/// real implementation upstream, so we don't override it here.
/turf/proc/add_dent(dent_type, x, y)
        return

/turf/open/floor/add_dent(dent_type, x, y)
        return

// =============================================================================
// /atom procs
// =============================================================================

/// Legacy: get_projectile_hitsound(projectile) at the atom level.
/// Returns null by default; overridden on /turf subtypes above.
/atom/proc/get_projectile_hitsound(obj/projectile/proj)
        return null

// =============================================================================
// /obj/item/bodypart procs
// =============================================================================

// (ranged_hit_zone_modifier var is added in bodypart_defines.dm)

// =============================================================================
// Blood DNA helpers (legacy)
// =============================================================================

/// Legacy: return_blood_DNA() returned a list of blood DNA data from the
/// projectile (for forensic analysis). Upstream uses the reagent/blood
/// system instead. We return an empty list so horizon's blood.dm compiles.
/obj/projectile/proc/return_blood_DNA()
        return list()

/obj/effect/temp_visual/bloodsplatter/proc/return_blood_DNA()
        return list()

/obj/item/proc/return_blood_DNA()
        return list()
