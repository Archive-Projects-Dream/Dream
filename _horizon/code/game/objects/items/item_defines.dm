// horizon-dev-sync[bot] port
// These variables are required by horizon mechanics (projectiles, gun systems,
// weight system, item descriptions) but are not present in the upstream
// /tg/station codebase that this branch is based on.
// They are ported from the legacy modular_septic/code/game/objects/item_defines.dm
// to keep the horizon gunplay and inventory systems compiling.

/obj/item
        /// Organ storage component requires this
        var/atom/stored_in

        /// Used for unturning when picked up by a mob
        var/our_angle = 0

        /**
         * How much fatigue we (normally) take away from the user when attacking with this.
         *
         * LEAVING THIS AS NULL WILL CALCULATE A NEW attack_fatigue_cost BASED ON W_CLASS ON INITIALIZE()
         */
        var/attack_fatigue_cost = null

        /// Accuracy modifier for ranged combat
        var/ranged_modifier = 0
        /// Accuracy modifier for body zone in ranged combat
        var/ranged_zone_modifier = 0

        /// How much to remove from edge_protection
        var/edge_protection_penetration = 0
        /// Armour penetration that only applies to subtractible armor
        var/subtractible_armour_penetration = 0
        /// Whether or not our object is easily hindered by the presence of subtractible armor
        var/weak_against_subtractible_armour = FALSE
        /// This is NOT related to armor penetration, and simply works as a bonus for armor damage
        var/armor_damage_modifier = 0

/// Returns the weight (in kilograms) this item contributes to a mob's encumbrance.
/// Defaults to the item's own carry_weight value, plus any weight contributed by
/// attached storage datums.
/// NOTE: Upstream /tg/station renamed /datum/component/storage to /datum/storage.
/// We check for both at runtime to be safe.
/obj/item/proc/get_carry_weight()
        . = carry_weight || 0
        var/datum/storage/storage = GetComponent(/datum/storage)
        if(storage)
                . += storage.get_carry_weight()

/// Cool drop / throw effect: randomises pixel offset and rotation a bit
/// so dropped items look less stiff. Ported from legacy
/// modular_septic/code/game/objects/items.dm.
/obj/item/proc/do_messy(pixel_variation = 8, angle_variation = 360, duration = 0)
        if(item_flags & NO_ANGLE_RANDOM_DROP)
                return
        animate(src, pixel_x = (base_pixel_x + rand(-pixel_variation, pixel_variation)), duration)
        animate(src, pixel_y = (base_pixel_y + rand(-pixel_variation, pixel_variation)), duration)
        if(our_angle)
                animate(src, transform = transform.Turn(-our_angle), duration)
                our_angle = 0
        our_angle = rand(0, angle_variation)
        transform = transform.Turn(our_angle)

/// Undo the do_messy() pixel/rotation offsets.
/obj/item/proc/undo_messy(duration = 0)
        animate(src, pixel_x = base_pixel_x, duration)
        animate(src, pixel_y = base_pixel_y, duration)
        if(our_angle)
                animate(src, transform = transform.Turn(-our_angle), duration)
                our_angle = 0
