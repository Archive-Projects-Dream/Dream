/*
 * Multitile vehicle defines, ported from cmss13 code/__DEFINES/vehicle.dm
 * Horizon-Dream port. See _horizon/code/modules/vehicles/multitile/multitile.dm
 */

// Hardpoint slot ids
#define HDPT_PRIMARY "primary"
#define HDPT_SECONDARY "secondary"
#define HDPT_SUPPORT "support"
#define HDPT_ARMOR "armor"
#define HDPT_TREADS "treads"
#define HDPT_WHEELS "wheels"
#define HDPT_TURRET "turret"
#define HDPT_SPECIAL "special" //special pre-installed hardpoints with unique behaviour

// Visual layers for hardpoint overlays on the vehicle sprite
#define HDPT_LAYER_WHEELS 0.01 // so it appears below mobs
#define HDPT_LAYER_SUPPORT 2
#define HDPT_LAYER_ARMOR 3
#define HDPT_LAYER_TURRET 4
#define HDPT_LAYER_MAX 4

// Crew seat ids
#define VEHICLE_DRIVER "driver"
#define VEHICLE_GUNNER "primary gunner"
#define VEHICLE_SUPPORT_GUNNER_ONE "1st support gunner"
#define VEHICLE_SUPPORT_GUNNER_TWO "2nd support gunner"

// Movement speed presets (delay per tile, in deciseconds)
#define VEHICLE_SPEED_STATIC 5000 //500 seconds per tile, while not actually static, it's much better than adding check for each movement attempt.
#define VEHICLE_SPEED_SLOW 30 //3 seconds per tile
#define VEHICLE_SPEED_NORMAL 10 //default 1 second per tile
#define VEHICLE_SPEED_FASTNORMAL 7
#define VEHICLE_SPEED_FAST 5 //half a second per tile
#define VEHICLE_SPEED_FASTER 4
#define VEHICLE_SPEED_VERYFAST 3
#define VEHICLE_SPEED_SUPERFAST 2
#define VEHICLE_SPEED_DEBUGFAST 1

// Ram damage constants
#define VEHICLE_TRAMPLE_DAMAGE_TIER_1 22.5
#define VEHICLE_TRAMPLE_DAMAGE_TIER_2 18
#define VEHICLE_TRAMPLE_DAMAGE_TIER_3 13.5
#define VEHICLE_TRAMPLE_DAMAGE_SPECIAL 10 // Larva, small critters or tiny mobs
#define VEHICLE_TRAMPLE_DAMAGE_MIN 5 // Minimum is 5% damage from a ram

#define VEHICLE_TRAMPLE_DAMAGE_APC_REDUCTION 0.2 // APC deals 1/5 of normal ram damage

#define VEHICLE_TRAMPLE_DAMAGE_OVERDRIVE_BUFF 3 // Overdrive enhancer damage buff
#define VEHICLE_TRAMPLE_DAMAGE_REDUCTION_ARMOR_MULT 12 // How much we divide our armor by to get the percentage reduction

#define TIER_3_RAM_DAMAGE_TAKEN 60

/// How big we want each vehicle interior reservation to be, including padding
#define INTERIOR_BOUND_SIZE 25

/// Empty pixel offset template for hardpoints facing each direction
#define HDPT_OFFSET_EMPTY list("1" = list(0, 0), "2" = list(0, 0), "4" = list(0, 0), "8" = list(0, 0))

// Vehicle class flags (also gates what the vehicle may crush when ramming)
#define VEHICLE_CLASS_WEAK (1<<1) //light unarmored vehicles like colony vehicles/trucks/vans
#define VEHICLE_CLASS_LIGHT (1<<2) //light class armor (APC, ARC)
#define VEHICLE_CLASS_MEDIUM (1<<3) //medium class armor (tank)
#define VEHICLE_CLASS_HEAVY (1<<4) //heavy class armor (heavy tanks)
/// Vehicle can bypass vehicle blockers, typically going further into maps than intended
#define VEHICLE_BYPASS_BLOCKERS (1<<5)

/*
 * Hardpoint fire modes.
 * cmss13 used the GUN_FIREMODE_* defines from the gun system; Horizon-Dream's
 * gun code uses datum-based firemodes, so the multitile hardpoints keep their own.
 */
#define HARDPOINT_FIREMODE_SEMIAUTO 0
#define HARDPOINT_FIREMODE_AUTOMATIC 1
#define HARDPOINT_FIREMODE_BURSTFIRE 2

/// Layer for interior doors, ported from cmss13 layer defines.
/// BYOND's FLY_LAYER (5) is used for walls; south-facing walls sit above.
#define INTERIOR_DOOR_LAYER 3.7
#define INTERIOR_WALL_SOUTH_LAYER 5.2
#define INTERIOR_WALL_LAYER 2.02

/*
 * Signals for the multitile vehicle system.
 */
/// Sent by the ARC when its sensor antenna finishes deploying or retracting: ( )
#define COMSIG_ARC_ANTENNA_TOGGLED "arc_antenna_toggled"
