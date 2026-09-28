// horizon-dev-sync[bot] port
// Compatibility procs / vars missing from upstream /tg/station codebase but
// called by horizon mechanics (gun_altclick, secondary attacks, ammo box
// update_ammo_count, atom handle_atom_del, mob incapacitated, etc.).
//
// These are deliberately THIN wrappers or no-ops that delegate to upstream
// equivalents where possible. They exist only so horizon's legacy call sites
// compile against the new upstream API.

// =============================================================================
// /atom helpers
// =============================================================================

/// Legacy: called when an atom contained in this atom is deleted.
/// Upstream removed this in favour of datum storage signals. No-op stub.
/atom/proc/handle_atom_del(atom/deleting_atom)
        return

// =============================================================================
// /obj/item/ammo_box helpers
// =============================================================================

/// Legacy: refreshes the ammo count display on the ammo box / magazine.
/// Upstream removed this in favour of update_icon_state() doing the work
/// internally. We re-derive the count via ammo_count() and trigger an
/// appearance refresh so call sites like _ammo_box.dm keep working.
/obj/item/ammo_box/proc/update_ammo_count()
        update_appearance()

// =============================================================================
// /mob helpers
// =============================================================================

/// Legacy: returns TRUE if the mob is incapacitated (stunned, restrained,
/// KO'd, etc.). Upstream uses HAS_TRAIT(mob, TRAIT_INCAPACITATED) instead.
/// This shim keeps horizon's _gun.dm / _ballistic.dm MouseDrop checks working.
/mob/proc/incapacitated(ignore_restraints = FALSE, ignore_grab = FALSE, ignore_stasis = FALSE)
        return HAS_TRAIT(src, TRAIT_INCAPACITATED)

/mob/living/incapacitated(ignore_restraints = FALSE, ignore_grab = FALSE, ignore_stasis = FALSE)
        if(stat >= SOFT_CRIT)
                return TRUE
        if(HAS_TRAIT(src, TRAIT_INCAPACITATED))
                return TRUE
        if(!ignore_restraints && (HAS_TRAIT(src, TRAIT_HANDS_BLOCKED) || HAS_TRAIT(src, TRAIT_RESTRAINED)))
                return TRUE
        return FALSE

// =============================================================================
// /obj/item/gun helpers
// =============================================================================

/// Legacy AltClick base proc. Upstream /tg/station removed /atom/AltClick
/// in favour of /mob/AltClickOn(atom/target). Horizon's _ballistic.dm,
/// rifle.dm, and pistol.dm override /obj/item/gun/.../AltClick(mob/user)
/// and call ..(), so we need this base to exist on /obj/item.
/obj/item/proc/AltClick(mob/user)
        return

/// Legacy: fire selector position. 1 = semi, 2 = burst, 3 = full auto.
/// Defined here (loaded before _automatic.dm) so `select = 3` in
/// _automatic.dm doesn't trigger a "var_before_def" warning.
/obj/item/gun/ballistic/automatic
        var/select = 1

// =============================================================================
// /obj/item/gun/ballistic/shotgun helpers
// =============================================================================

/// Legacy tertiary attack (third mouse button click). Upstream doesn't ship
/// attack_self_tertiary - it's a no-op stub so the override in shotgun.dm
/// compiles. Returns the standard "continue chain" sentinel.
/obj/item/proc/attack_self_tertiary(mob/user, modifiers)
        return NONE

// =============================================================================
// /obj/item/gun secondary attack helpers
// =============================================================================

/// Legacy: afterattack_secondary() was a /tg/station proc that fired after a
/// secondary (right-click) attack on a non-adjacent target. Upstream replaced
/// it with attack_secondary(). This no-op stub lets horizon's _gun.dm override
/// compile. Override at the subtype level to add real behaviour.
/obj/item/proc/afterattack_secondary(atom/target, mob/user, proximity_flag, click_parameters)
        return NONE

/// Legacy: alt_click_secondary() was the right-click variant of AltClick.
/// Upstream uses AltClickSecondaryOn(atom/target) on /mob instead. This
/// no-op stub lets horizon's pistol.dm override compile.
/obj/item/proc/alt_click_secondary(mob/user)
        return NONE

// =============================================================================
// /obj/item helpers
// =============================================================================

/// Legacy: image2html() converted an /image (or icon file path) into an
/// HTML <img> tag for embedding in chat. Upstream removed it. We emit a
/// simple file-path reference so the chaser / examine UI can resolve the
/// asset via the standard asset cache.
/proc/image2html(icon_or_image, mob/user, format = null, sourceonly = FALSE)
        if(!icon_or_image)
                return ""
        // If we were handed a file path (the common case for horizon's desc_chaser),
        // return the path string so the caller can embed it in an <img> tag.
        if(isfile(icon_or_image) || istext(icon_or_image))
                return "[icon_or_image]"
        return "\[[icon_or_image]\]"


/// Legacy: desc_chaser() returns a verbose description of an item for the
/// chaser / examine UI. Upstream doesn't ship this - we return "" so the
/// override in pistol.dm compiles.
/obj/item/proc/desc_chaser(mob/user)
        return ""

// =============================================================================
// /obj/item/knife helpers
// =============================================================================

/obj/item/knife
        /// Legacy: if TRUE, this knife can be attached as a bayonet to a gun.
        /// Upstream removed the bayonet attachment system from /obj/item/gun;
        /// horizon's _gun.dm still reads `knife.bayonet`.
        var/bayonet = FALSE

// =============================================================================
// /obj/item/flashlight/seclite helpers
// =============================================================================

/obj/item/flashlight/seclite
        /// Legacy: if TRUE, the seclite is currently turned on. Upstream uses
        /// `light_on` instead. This alias keeps horizon's _gun.dm overlay code
        /// working.
        var/on = FALSE

// =============================================================================
// Action button helpers
// =============================================================================

/// Legacy: refreshes all action buttons on the user's HUD.
/// Upstream uses /mob/proc/update_action_buttons(reload_screen).
/obj/item/proc/update_action_buttons()
        if(ismob(loc))
                var/mob/M = loc
                M.update_action_buttons()

// =============================================================================
// /datum/action/item_action helpers
// =============================================================================

/datum/action/item_action
        /// Legacy: icon file for the action button. Upstream uses `button_icon`
        /// instead. We provide `icon_icon` as an alias so horizon's _gun.dm
        /// toggle_stock action definition compiles.
        var/icon_icon

/datum/action/item_action/New(Target)
        . = ..()
        // Mirror icon_icon into button_icon so upstream's rendering code works.
        if(icon_icon && !button_icon)
                button_icon = icon_icon

// =============================================================================
// /obj/projectile helpers
// =============================================================================

/// Legacy: process_hit() handled projectile-vs-atom collision logic.
/// Upstream renamed it to process_hit_loop(). We provide a thin wrapper
/// that delegates to the upstream proc with the right signature, so
/// horizon's _projectile.dm recursive calls still work.
///
/// NOTE: horizon's _projectile.dm OVERRIDES /obj/projectile/process_hit.
/// That override is the real implementation. This stub is only here so
/// upstream's call sites that still use process_hit_loop() don't break.
/obj/projectile/proc/process_hit(turf/T, atom/target, atom/bumped, hit_something = FALSE)
        return process_hit_loop(target)
