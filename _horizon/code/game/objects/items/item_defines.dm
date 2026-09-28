// horizon-dev-sync[bot] port
// These variables are required by horizon mechanics (projectiles, gun systems,
// weight system, item descriptions) but are not present in the upstream
// /tg/station codebase that this branch is based on.
// They are ported from the legacy modular_septic/code/game/objects/item_defines.dm
// to keep the horizon gunplay and inventory systems compiling.

/obj/item
	/// Organ storage component requires this
	var/atom/stored_in

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
/// Defaults to the item's own carry_weight value. Override to add the weight of
/// attached components (magazines, pins, etc.).
/obj/item/proc/get_carry_weight()
	return carry_weight || 0
