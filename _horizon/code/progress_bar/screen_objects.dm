/atom/movable/screen/progbar_container
	name = "swing cooldown"
	icon_state = ""
	screen_loc = "CENTER:-16,SOUTH:4"
	var/datum/world_progressbar/progbar
	var/iteration = 0

// [HORIZON-FIX] This is the ONLY progbar_container/Initialize definition.
// It used to exist twice (here and in world_progressbar.dm); the later
// compiled one (world_progressbar.dm) silently shadowed this one, so the
// progbar datum was never created and on_changenext() hit a null deref
// on every click. Both bodies are merged here.
/atom/movable/screen/progbar_container/Initialize(mapload, datum/hud/hud_owner)
	if(hud_owner)
		RegisterSignal(hud_owner.mymob, COMSIG_LIVING_CHANGENEXT_MOVE, PROC_REF(on_changenext))
	. = ..()
	progbar = new(src)
	progbar.qdel_when_done = FALSE
	progbar.bar.vis_flags = VIS_INHERIT_ID | VIS_INHERIT_LAYER | VIS_INHERIT_PLANE
	progbar.bar.appearance_flags = APPEARANCE_UI

/atom/movable/screen/progbar_container/Destroy()
	QDEL_NULL(progbar)
	return ..()

/atom/movable/screen/progbar_container/proc/on_changenext(datum/source, next_move)
	SIGNAL_HANDLER

	iteration++
	progbar.goal = next_move - world.time
	progbar.bar.icon_state = "prog_bar_0"

	progbar_process(next_move)

/atom/movable/screen/progbar_container/proc/progbar_process(next_move)
	set waitfor = FALSE

	var/start_time = world.time
	var/iteration = src.iteration
	while(iteration == src.iteration && (world.time < next_move))
		progbar.update(world.time - start_time)
		sleep(1)

	if(iteration == src.iteration)
		progbar.end_progress()
