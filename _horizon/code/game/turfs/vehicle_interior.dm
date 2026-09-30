/*
 * Vehicle interior turfs, ported from cmss13 code/game/turfs/open.dm
 * plus the interior space reservation type.
 */

/// Re-parent the implicit shuttle turf category onto the engine floor so interior
/// floors behave like proper un-pryable plating.
/turf/open/shuttle
	parent_type = /turf/open/floor/engine

/// Interior floors for multitile vehicles. Based on the engine floor so tiles can't be pried up.
/turf/open/shuttle/vehicle
	name = "floor"
	icon = '_horizon/icons/turf/vehicle_interior.dmi'
	icon_state = "floor_0"
	tiled_turf = FALSE
	rust_resistance = RUST_RESISTANCE_ABSOLUTE

// Medical interior variants
/turf/open/shuttle/vehicle/med
	name = "floor"
	icon_state = "dark_sterile"

/turf/open/shuttle/vehicle/med/slate
	color = "#495462"

/turf/open/shuttle/vehicle/med/gray
	color = "#9c9a97"

// Generic dark sterile variants
/turf/open/shuttle/vehicle/dark_sterile
	icon_state = "dark_sterile"

/turf/open/shuttle/vehicle/dark_sterile_green_5
	icon_state = "dark_sterile_green_5"

/turf/open/shuttle/vehicle/dark_sterile_green_6
	icon_state = "dark_sterile_green_6"

/turf/open/shuttle/vehicle/dark_sterile_green_7
	icon_state = "dark_sterile_green_7"

/turf/open/shuttle/vehicle/dark_sterile_green_8
	icon_state = "dark_sterile_green_8"

/turf/open/shuttle/vehicle/dark_sterile_green_11
	icon_state = "dark_sterile_green_11"

/turf/open/shuttle/vehicle/dark_sterile_green_12
	icon_state = "dark_sterile_green_12"

/turf/open/shuttle/vehicle/dark_sterile_green_13
	icon_state = "dark_sterile_green_13"

/turf/open/shuttle/vehicle/dark_sterile_green_14
	icon_state = "dark_sterile_green_14"

// Plated floor variants
/turf/open/shuttle/vehicle/floor_0_1_15
	icon_state = "floor_0_1_15"

/turf/open/shuttle/vehicle/floor_1_1
	icon_state = "floor_1_1"

/turf/open/shuttle/vehicle/floor_1_2
	icon_state = "floor_1_2"

/turf/open/shuttle/vehicle/floor_1_5
	icon_state = "floor_1_5"

/turf/open/shuttle/vehicle/floor_1_6
	icon_state = "floor_1_6"

/turf/open/shuttle/vehicle/floor_1_7
	icon_state = "floor_1_7"

/turf/open/shuttle/vehicle/floor_1_8
	icon_state = "floor_1_8"

/turf/open/shuttle/vehicle/floor_1_9
	icon_state = "floor_1_9"

/turf/open/shuttle/vehicle/floor_1_10
	icon_state = "floor_1_10"

/turf/open/shuttle/vehicle/floor_1_11
	icon_state = "floor_1_11"

/turf/open/shuttle/vehicle/floor_1_12
	icon_state = "floor_1_12"

/turf/open/shuttle/vehicle/floor_1_13
	icon_state = "floor_1_13"

/turf/open/shuttle/vehicle/floor_1_14
	icon_state = "floor_1_14"

/turf/open/shuttle/vehicle/floor_1_1_3
	icon_state = "floor_1_1_3"

/turf/open/shuttle/vehicle/floor_1_3_3
	icon_state = "floor_1_3_3"

/turf/open/shuttle/vehicle/floor_3
	icon_state = "floor_3"

/turf/open/shuttle/vehicle/floor_3_3
	icon_state = "floor_3_3"

/turf/open/shuttle/vehicle/floor_3_4
	icon_state = "floor_3_4"

/turf/open/shuttle/vehicle/floor_3_5
	icon_state = "floor_3_5"

/turf/open/shuttle/vehicle/floor_3_6
	icon_state = "floor_3_6"

/turf/open/shuttle/vehicle/floor_3_7
	icon_state = "floor_3_7"

/turf/open/shuttle/vehicle/floor_3_7_1
	icon_state = "floor_3_7_1"

/turf/open/shuttle/vehicle/floor_3_8
	icon_state = "floor_3_8"

/turf/open/shuttle/vehicle/floor_3_8_1
	icon_state = "floor_3_8_1"

/turf/open/shuttle/vehicle/floor_3_9
	icon_state = "floor_3_9"

/turf/open/shuttle/vehicle/floor_3_9_1
	icon_state = "floor_3_9_1"

/turf/open/shuttle/vehicle/floor_3_10_1
	icon_state = "floor_3_10_1"

/turf/open/shuttle/vehicle/floor_3_11
	icon_state = "floor_3_11"

/turf/open/shuttle/vehicle/floor_3_12
	icon_state = "floor_3_12"

/turf/open/shuttle/vehicle/floor_3_13
	icon_state = "floor_3_13"

/turf/open/shuttle/vehicle/floor_3_1_1
	icon_state = "floor_3_1_1"

/*
 * The black void that pads vehicle interior reservations, ported from
 * cmss13 /turf/open/void/vehicle. Dense and opaque so players can't wander
 * out of the interior into the reserved z-level.
 */
/turf/open/void
	parent_type = /turf/open/space/basic

/turf/open/void/vehicle
	density = TRUE
	opacity = TRUE
	name = "void"
	desc = "Wow, it's really dark..."
	// cmss13 also zeroed pass_flags here, but TG only defines pass_flags
	// on /atom/movable; the void blocks passage through density alone

/// Interior space reservation, from cmss13 code/modules/mapping/space_management/space_reservation.dm
/datum/turf_reservation/interior
	turf_type = /turf/open/void/vehicle
