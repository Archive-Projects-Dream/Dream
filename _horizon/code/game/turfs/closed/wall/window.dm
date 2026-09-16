// MARK: Окна

/obj/structure/window/reinforced/shuttle
	icon = '_horizon/icons/obj/smooth_structures/shuttle_window.dmi'
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_DIAGONAL_CORNERS
	smoothing_groups = SMOOTH_GROUP_TITANIUM_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_SHUTTLE_PARTS + SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_TITANIUM_WALLS

/obj/structure/window/reinforced/plasma/plastitanium
	icon = '_horizon/icons/obj/smooth_structures/plastitanium_window.dmi'

/obj/structure/window/reinforced/fulltile
	icon = '_horizon/icons/obj/smooth_structures/reinforced_window.dmi'
	smoothing_groups = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WALLS

/obj/structure/window/fulltile
	icon = '_horizon/icons/obj/smooth_structures/window.dmi'

/obj/structure/window/plasma/fulltile
	icon = '_horizon/icons/obj/smooth_structures/plasma_window.dmi'

/obj/structure/window/reinforced/plasma/fulltile
	icon = '_horizon/icons/obj/smooth_structures/rplasma_window.dmi'

/turf/closed/indestructible/fakeglass
	icon = MAP_SWITCH('_horizon/icons/obj/smooth_structures/reinforced_window.dmi', 'icons/obj/smooth_structures/structure_variations.dmi')
	smoothing_groups = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WALLS

/obj/structure/grille
	icon = '_horizon/icons/obj/smooth_structures/grille.dmi'
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_DIAGONAL_CORNERS
	smoothing_groups = SMOOTH_GROUP_TITANIUM_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_SHUTTLE_PARTS + SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_TITANIUM_WALLS
