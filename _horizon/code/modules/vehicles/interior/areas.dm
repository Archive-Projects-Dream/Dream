/*
 * Vehicle interior areas, ported from cmss13 code/modules/vehicles/interior/areas.dm
 */

/area/interior
	requires_power = FALSE
	// cmss13 interior areas are always lit through area base lighting
	// (cmss13 /area/interior sets base_lighting_alpha = 255 with the
	// default white colour). static_lighting = FALSE additionally skips
	// per-turf darkness objects so interiors can never go pitch black.
	static_lighting = FALSE
	base_lighting_alpha = 255
	base_lighting_color = COLOR_WHITE
	icon = '_horizon/icons/turf/areas_interiors.dmi'
	icon_state = "interior"
	// cmss13's has_gravity = TRUE maps onto TG's area-level default_gravity
	default_gravity = STANDARD_GRAVITY
	// cmss13's valid_territory = FALSE maps onto clearing area_flags
	// (drops VALID_TERRITORY, BLOBS_ALLOWED and CULT_PERMITTED)
	area_flags = NONE
	// cmss13's /area/interior loops sound/ambience/vehicle_interior1.ogg as
	// the interior ambience; mapped onto TG's looping ambient buzz.
	// Interiors are self-powered (no APC), so the buzz needs the
	// apc-independent flag declared in interior_map_compat.dm.
	ambient_buzz = '_horizon/sounds/ambience/vehicle_interior1.ogg'
	ambient_buzz_vol = 40
	ambient_buzz_apc_independent = TRUE

/area/interior/vehicle/tank
	name = "Tank Interior"
	icon_state = "tank"

/area/interior/vehicle/apc
	name = "APC Interior"
	icon_state = "apc"

/area/interior/vehicle/apc/med
	name = "MED APC Interior"
	icon_state = "apc_med"

/area/interior/vehicle/apc/command
	name = "CMD APC Interior"
	icon_state = "apc_cmd"

/area/interior/vehicle/van
	name = "Van Interior"
	icon_state = "van"

/area/interior/vehicle/clf_van
	name = "CLF Van Interior"
	icon_state = "van"

/area/interior/vehicle/box_van
	name = "Box-Van Interior"
	icon_state = "van"

/area/interior/vehicle/pizza_van
	name = "Pizza-Van Interior"
	icon_state = "van"

/area/interior/vehicle/arc
	name = "ARC Interior"
	icon_state = "arc"
