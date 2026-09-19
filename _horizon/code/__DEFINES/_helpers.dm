/// Type is abstract and should be skipped in type iterations, etc.
#define IS_ABSTRACT(datum_type) (initial(datum_type.abstract_type) == datum_type)

#define BASED_TILES list(/atom/movable/atom_shadow, /obj/machinery/door, /obj/structure/grille, /obj/structure/window/fulltile, /obj/structure/window/reinforced/fulltile, /obj/structure/window/reinforced/plasma/fulltile, /obj/structure/window/reinforced/tinted/fulltile, )
