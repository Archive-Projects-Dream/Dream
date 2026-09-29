// horizon-dev-sync[bot] port
// Variables required by horizon mechanics but not present in upstream.

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

/// Returns the weight (in kilograms) this item contributes to a mob's encumbrance.
/obj/item/proc/get_carry_weight()
        . = carry_weight || 0
        var/datum/storage/storage = GetComponent(/datum/storage)
        if(storage)
                . += storage.get_carry_weight()

/// Stub: returns the total carry weight of items inside this storage datum.
/datum/storage/proc/get_carry_weight()
        return 0

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
