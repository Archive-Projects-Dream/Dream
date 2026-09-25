/mob/dead/new_player/Logout()
	ready = PLAYER_NOT_READY

	// [HORIZON-EDIT] HorizonLobby - lobby hide is now signal-driven.
	// /datum/lobby_menu hooks COMSIG_CLIENT_MOB_LOGIN and auto-hides when
	// client.mob is no longer a /mob/dead/new_player.
	// [/HORIZON-EDIT]

	..()
	if(!spawning)//Here so that if they are spawning and log out, the other procs can play out and they will have a mob to come back to.
		key = null//We null their key before deleting the mob, so they are properly kicked out.
		QDEL_NULL(mind) //Clean out mind, yes this fucking sucks
		qdel(src)
	return
