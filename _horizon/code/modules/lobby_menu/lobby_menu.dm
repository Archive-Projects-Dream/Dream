// [HORIZON-ADD] HorizonLobby
// /client-owned lobby menu lifecycle. Survives mob transfers, signal-driven.
// Hooks: COMSIG_CLIENT_MOB_LOGIN (auto-show/hide), COMSIG_QDELETING (cleanup).
// No sleep() - fade-out is async via addtimer callback.

/datum/lobby_menu
	var/client/client
	var/datum/tgui_window/lobby_window
	var/datum/tgui/ui  // tracked here, mob may be qdeleted before close
	var/visible = FALSE
	var/fading_out = FALSE

/datum/lobby_menu/New(client/C)
	if(!istype(C))
		qdel(src)
		return
	client = C
	RegisterSignal(client, COMSIG_QDELETING, PROC_REF(on_client_qdel))
	RegisterSignal(client, COMSIG_CLIENT_MOB_LOGIN, PROC_REF(on_mob_login))
	update_visibility()

/datum/lobby_menu/Destroy()
	cleanup_window()
	if(client)
		UnregisterSignal(client, list(COMSIG_QDELETING, COMSIG_CLIENT_MOB_LOGIN))
	client = null
	return ..()

/datum/lobby_menu/proc/on_client_qdel()
	SIGNAL_HANDLER
	qdel(src)

/datum/lobby_menu/proc/on_mob_login(client/source, mob/new_mob)
	SIGNAL_HANDLER
	update_visibility()

/datum/lobby_menu/proc/update_visibility()
	var/mob/M = client?.mob
	var/should_show = istype(M, /mob/dead/new_player) && !client?.interviewee
	if(should_show && !visible)
		show()
	else if(!should_show && visible)
		hide()

/datum/lobby_menu/proc/show()
	if(visible || !client)
		return
	var/mob/dead/new_player/NP = client.mob
	if(!istype(NP))
		return
	visible = TRUE
	fading_out = FALSE
	winset(client, "lobby_browser", "is-disabled=false;is-visible=true")
	winset(client, "mapwindow.status_bar", "is-visible=false")
	if(!lobby_window)
		lobby_window = new(client, "lobby_browser")
		lobby_window.initialize(
			assets = list(
				get_asset_datum(/datum/asset/simple/tgui),
				get_asset_datum(/datum/asset/simple/namespaced/chakrapetch)
			)
		)
	NP.ui_interact(NP)
	// Track the UI ref so we can close it after the mob is qdeleted.
	ui = SStgui.get_open_ui(NP, NP)

/datum/lobby_menu/proc/hide()
	if(!visible)
		return
	visible = FALSE
	// If fade is in progress, the close is scheduled by addtimer in send_fade_out().
	if(fading_out)
		return
	do_close()

/// Send the fade-out message to the React app and schedule the actual close
/// via addtimer. No sleep - the calling proc (e.g. SSticker.transfer_characters)
/// returns immediately. The actual close happens via the callback, by which
/// time the mob may have already transferred (the lobby_browser is bound to
/// the client, not the mob, so it survives).
/datum/lobby_menu/proc/send_fade_out()
	if(!visible || fading_out || !lobby_window)
		return
	fading_out = TRUE
	lobby_window.send_message("lobbyFadeOut")
	addtimer(CALLBACK(src, PROC_REF(do_close)), LOBBY_FADE_OUT_TIME, TIMER_DELETE_ME)

/datum/lobby_menu/proc/do_close()
	fading_out = FALSE
	visible = FALSE
	if(ui)
		ui.close(can_be_suspended = FALSE)
		ui = null
	if(lobby_window)
		lobby_window.unsubscribe()
		lobby_window.close(FALSE)
		lobby_window = null
	if(client)
		winset(client, "lobby_browser", "is-disabled=true;is-visible=false")
		winset(client, "mapwindow.status_bar", "is-visible=true")

/datum/lobby_menu/proc/cleanup_window()
	fading_out = FALSE
	visible = FALSE
	if(ui)
		QDEL_NULL(ui)
	if(lobby_window)
		lobby_window.unsubscribe()
		QDEL_NULL(lobby_window)
// [/HORIZON-ADD]
