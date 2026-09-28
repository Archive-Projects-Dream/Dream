/obj/projectile
	speed = 0.3
	icon = '_horizon/icons/obj/items/guns/projectiles/projectiles.dmi'
	icon_state = "bullet"
	/// Minimum damage this projectile can do
	var/min_damage
	/// Add this to the projectile diceroll modifiers
	var/diceroll_modifier = 0
	/// Add this to the projectile diceroll modifiers of whatever we hit, but ONLY against a specified target
	var/list/target_specific_diceroll
	/// How much to remove from edge_protection
	var/edge_protection_penetration = 0
	/// Amount of armour effectiveness to remove
	var/subtractible_armour_penetration = 0
	/// Whether or not our object is easily hindered by the presence of subtractible armor
	var/weak_against_subtractible_armour = FALSE
	/// This is NOT related to armor penetration, and simply works as a bonus for armor damage
	var/armor_damage_modifier = 0
	/// Pain damage caused to targets
	var/pain = 0
	/// Accuracy modifier for ranged combat
	var/ranged_modifier = 0
	/// Accuracy modifier for body zone in ranged combat
	var/ranged_zone_modifier = 0
	/// Volume of the hitsound
	var/hitsound_volume = 80
	/// Stored visible message
	var/hit_text = ""
	/// Stored target message
	var/target_hit_text = ""
	var/no_effect = FALSE
