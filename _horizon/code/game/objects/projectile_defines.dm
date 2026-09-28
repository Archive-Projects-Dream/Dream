// horizon-dev-sync[bot] port
// Variables missing from upstream /tg/station codebase but referenced by
// horizon mechanics (projectile organ damage, ammo casing bounce behaviour,
// legacy embedding, angle member, etc.).
// Ported from legacy code/modules/projectiles/ammunition/_ammunition.dm,
// code/modules/projectiles/projectile.dm, and
// modular_septic/code/game/objects/obj_defines.dm.

/obj/item/ammo_casing
        /// If FALSE, the casing will not bounce / play bounce sounds when ejected.
        /// Set FALSE for energy casings, foam darts, etc. that shouldn't clang.
        var/heavy_metal = TRUE

/obj/projectile
        /// How good a given projectile is at causing organ damage on carbons.
        /// Higher values equal better shots at creating serious organ damage.
        var/organ_bonus = 0
        /// If this hits a human with no organ armor on the affected body part,
        /// add this to the organ mod.
        var/bare_organ_bonus = 0

        /// Legacy embedding list (e.g. list("embed_chance"=35, "fall_chance"=0, ...)).
        /// Upstream /tg/station moved to /datum/embedding (embed_data), but horizon's
        /// _projectile.dm reads embedding as a list via LAZYACCESS.
        var/list/embedding

        /// Legacy Angle member (capital A). Upstream uses lowercase `angle` as a
        /// member var, but horizon code references P.Angle. We define this as an
        /// alias that mirrors the upstream `angle` value.
        var/Angle

        /// If TRUE, the projectile deals no damage. Legacy var name.
        /// Upstream removed this; horizon's on_hit() checks it.
        var/nodamage = FALSE

        /// Decayed range - legacy var used by _firing.dm to clamp projectile range
        /// based on distance to target.
        var/decayedRange = 0

        /// Semi-auto cooldown flag. Legacy var read by horizon's on_autofire_start()
        /// and do_autofire() to bail out early.
        var/semicd = FALSE

/// Override of upstream's set_angle() to keep the legacy `Angle` member
/// (capital A) in sync with upstream's lowercase `angle`. Horizon code
/// reads P.Angle to compute particle velocity components.
/obj/projectile/set_angle(new_angle)
        . = ..()
        Angle = angle
