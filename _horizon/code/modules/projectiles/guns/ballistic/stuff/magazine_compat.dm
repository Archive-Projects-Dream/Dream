/obj/item/gun/ballistic/Initialize(mapload)
	if(spawn_magazine_type && accepted_magazine_type == initial(accepted_magazine_type))
		accepted_magazine_type = spawn_magazine_type
	return ..()
