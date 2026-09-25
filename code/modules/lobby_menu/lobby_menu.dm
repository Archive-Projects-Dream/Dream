// [HORIZON-ADD] HorizonLobby
// Self-contained lobby menu system. Owned by /client, survives mob transfers.
// Hooks into COMSIG_CLIENT_MOB_LOGIN to auto-show/hide based on mob type.
// Hooks into COMSIG_QDELETING to clean up on client disconnect.
//
// Architecture rationale:
//   - /datum/lobby_menu is owned by /client, NOT by /mob/dead/new_player.
//     This means the lobby_window survives mob transfer (new_player -> living
//     mob), so we can properly fade-out + close before the client.mob changes.
//   - All lobby UI lifecycle is encapsulated here. The mob's ui_interact etc
//     (which TGUI requires on src_object) delegate to client.lobby_menu for
//     the tgui_window ref, but the data/state procs stay on the mob.
//   - Signal-driven: no edits needed in /mob/dead/new_player/Login/Logout for
//     showing/hiding. Auto-shows when client.mob becomes a
//     /mob/dead/new_player, auto-hides when client.mob becomes anything else.
//   - Designed to survive upstream merges: the bulk of the lobby logic is in
//     this HORIZON-only file. Touch points in TG files are minimal and tagged
//     [HORIZON-EDIT] HorizonLobby so they can be re-applied after a merge.
//
// Note: LOBBY_FADE_OUT_TIME is defined in _horizon/code/__DEFINES/tgui.dm.

/datum/lobby_menu
	/// Client that owns this lobby menu. Set in New(), nulled in Destroy().
	var/client/client
	/// TGUI window rendered inside the lobby_browser skin element. Owned here
	/// (not on the mob) so it survives mob transfer.
	var/datum/tgui_window/lobby_window
	/// Whether the lobby is currently visible (window created + UI open).
	var/visible = FALSE
	/// Whether fade-out is in progress (prevents double-close races).
	var/fading_out = FALSE

/datum/lobby_menu/New(client/C)
	if(!istype(C))
		qdel(src)
		return
	client = C
	RegisterSignal(client, COMSIG_QDELETING, PROC_REF(on_client_qdel))
	RegisterSignal(client, COMSIG_CLIENT_MOB_LOGIN, PROC_REF(on_mob_login))
	// Initial state - show if we are already a new_player mob at creation time
	update_visibility()

/datum/lobby_menu/Destroy()
	cleanup_window()
	if(client)
		UnregisterSignal(client, list(COMSIG_QDELETING, COMSIG_CLIENT_MOB_LOGIN))
	client = null
	return ..()

/// Signal handler for COMSIG_QDELETING on the client. Cleans up the lobby_menu
/// when the client is destroyed (disconnect).
/datum/lobby_menu/proc/on_client_qdel()
	SIGNAL_HANDLER
	qdel(src)

/// Signal handler for COMSIG_CLIENT_MOB_LOGIN. Fired when the client's mob
/// changes (login, transfer to spawned character, transfer to observer, etc.).
/// Auto-shows or auto-hides the lobby based on the new mob type.
/datum/lobby_menu/proc/on_mob_login(client/source, mob/new_mob)
	SIGNAL_HANDLER
	update_visibility()

/// Show or hide the lobby based on the client's current mob. Called from
/// on_mob_login signal AND from New() for initial state. Idempotent.
/datum/lobby_menu/proc/update_visibility()
	var/mob/M = client?.mob
	var/should_show = istype(M, /mob/dead/new_player) && !client?.interviewee
	if(should_show && !visible)
		show()
	else if(!should_show && visible)
		hide()

/// Show the lobby: reveal the skin element, create the tgui_window (if not
/// already), and open the LobbyMenu TGUI UI on the new_player mob. Idempotent.
/datum/lobby_menu/proc/show()
	if(visible || !client)
		return
	var/mob/dead/new_player/NP = client.mob
	if(!istype(NP))
		return
	visible = TRUE
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
	// Open the TGUI UI. The ui_interact proc on /mob/dead/new_player handles
	// creating the actual /datum/tgui and binding it to this lobby_window.
	NP.ui_interact(NP)

/// Hide the lobby: optionally play fade-out animation, then close the TGUI UI,
/// close the tgui_window, hide the skin element. Idempotent.
/datum/lobby_menu/proc/hide(fade_out = FALSE)
	if(!visible)
		return
	visible = FALSE
	if(fade_out && lobby_window && !fading_out)
		fading_out = TRUE
		lobby_window.send_message("lobbyFadeOut")
		sleep(LOBBY_FADE_OUT_TIME)
		if(QDELETED(src))
			return
		fading_out = FALSE
	// Find and close the TGUI UI bound to the (former) new_player mob.
	var/mob/M = client?.mob
	if(istype(M))
		var/datum/tgui/ui = SStgui.get_open_ui(M, M)
		if(ui)
			ui.close(can_be_suspended = FALSE)
	if(lobby_window)
		lobby_window.unsubscribe()
		lobby_window.close(FALSE)
		lobby_window = null
	if(client)
		winset(client, "lobby_browser", "is-disabled=true;is-visible=false")
		winset(client, "mapwindow.status_bar", "is-visible=true")

/// Just send the fade-out message to the React app, without sleeping or
/// closing. Used by the ticker subsystem to batch-fade-out all clients
/// before transferring characters at round start. The actual close happens
/// later, when each player's mob transfer triggers hide() via the
/// COMSIG_CLIENT_MOB_LOGIN signal.
/datum/lobby_menu/proc/send_fade_out()
	if(!visible || fading_out || !lobby_window)
		return
	fading_out = TRUE
	lobby_window.send_message("lobbyFadeOut")

/// Force cleanup. Called from Destroy() and from any path that needs to
/// hard-reset the lobby (e.g. reset_menu_hud verb).
/datum/lobby_menu/proc/cleanup_window()
	var/mob/M = client?.mob
	if(istype(M))
		var/datum/tgui/ui = SStgui.get_open_ui(M, M)
		if(ui)
			ui.close(can_be_suspended = FALSE)
	if(lobby_window)
		lobby_window.unsubscribe()
		QDEL_NULL(lobby_window)
	visible = FALSE
	fading_out = FALSE
// [/HORIZON-ADD]
