// [HORIZON-ADD] HorizonLobby
// Client-owned lobby menu lifecycle, CM13-style.
// The lobby is rendered by the standard tgui interface LobbyMenu
// (tgui/packages/tgui/interfaces/LobbyMenu.tsx) inside a browser element
// this datum creates and parents to either lobby_screen (opaque) or
// map_screen (transparent overlay), so it survives mob transfers.
// Hooks: COMSIG_CLIENT_MOB_LOGIN (auto-show/hide), COMSIG_QDELETING
// (cleanup). No sleep() - fade-out is async via addtimer callback.
// Ported from: MenuUI branch (layout/CRT lobby), html_v2 branch (preview,
// stats), upstream master (transparency, polls query), CM13 (behavior).

GLOBAL_LIST_EMPTY(lobby_menus)
GLOBAL_VAR(lobby_background_transparent)

#define LOBBY_FADE_OUT_TIME 0.6 SECONDS
#define LOBBY_PREVIEW_REFRESH_COOLDOWN 8 SECONDS
#define LOBBY_PREVIEW_DIRS list("south" = SOUTH, "east" = EAST, "north" = NORTH, "west" = WEST)
#define LOBBY_STATS_UPDATE_DEBOUNCE 2 SECONDS

/client/var/datum/lobby_menu/lobby_menu

/// Toggles the lobby background between opaque and transparent for every player in the lobby.
ADMIN_VERB(toggle_lobby_transparency, R_ADMIN, "Toggle Lobby Transparency", "Toggles the lobby background between opaque and transparent.", ADMIN_CATEGORY_MAIN)
	GLOB.lobby_background_transparent = !GLOB.lobby_background_transparent
	for(var/datum/lobby_menu/menu as anything in GLOB.lobby_menus)
		menu.set_transparency(GLOB.lobby_background_transparent)
	to_chat(user, span_adminnotice("Lobby background [GLOB.lobby_background_transparent ? "transparent" : "opaque"]."))
	log_admin("[key_name(user)] toggled lobby transparency [GLOB.lobby_background_transparent ? "on" : "off"].")

/datum/lobby_menu
	var/client/client
	/// The tgui window bound to the "lobby_browser" browser element.
	var/datum/tgui_window/lobby_window
	/// Tracked here because the new_player mob can be qdeleted before close.
	var/datum/tgui/ui
	var/visible = FALSE
	var/fading_out = FALSE
	/// TRUE when the browser overlays the map with a transparent background.
	var/transparent = FALSE
	/// Character preview icon URLs by direction (flat icons), see update_character_preview().
	var/list/preview_urls
	var/preview_sequence = 0
	var/preview_last_refresh = 0
	/// TRUE if there are polls the player has not voted in yet.
	var/has_new_poll = FALSE
	/// Debounce timer for player-count driven stats refreshes.
	var/stats_update_timer

/datum/lobby_menu/New(client/new_client)
	if(!istype(new_client))
		qdel(src)
		return
	client = new_client
	GLOB.lobby_menus += src
	RegisterSignal(client, COMSIG_QDELETING, PROC_REF(on_client_qdel))
	RegisterSignal(client, COMSIG_CLIENT_MOB_LOGIN, PROC_REF(on_mob_login))
	RegisterSignal(SSdcs, COMSIG_GLOB_CLIENT_CONNECT, PROC_REF(queue_stats_update))
	RegisterSignal(SSticker, COMSIG_TICKER_ENTER_PREGAME, PROC_REF(queue_stats_update))
	RegisterSignal(SSticker, COMSIG_TICKER_ENTER_SETTING_UP, PROC_REF(queue_stats_update))
	RegisterSignal(SSticker, COMSIG_TICKER_ERROR_SETTING_UP, PROC_REF(queue_stats_update))
	RegisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING, PROC_REF(queue_stats_update))
	update_visibility()

/datum/lobby_menu/Destroy()
	GLOB.lobby_menus -= src
	if(stats_update_timer)
		deltimer(stats_update_timer)
		stats_update_timer = null
	cleanup_window()
	if(client)
		UnregisterSignal(client, list(COMSIG_QDELETING, COMSIG_CLIENT_MOB_LOGIN))
		UnregisterSignal(SSdcs, list(COMSIG_GLOB_CLIENT_CONNECT))
		UnregisterSignal(SSticker, list(
			COMSIG_TICKER_ENTER_PREGAME,
			COMSIG_TICKER_ENTER_SETTING_UP,
			COMSIG_TICKER_ERROR_SETTING_UP,
			COMSIG_TICKER_ROUND_STARTING,
		))
	client = null
	return ..()

/datum/lobby_menu/proc/on_client_qdel()
	SIGNAL_HANDLER
	qdel(src)

/datum/lobby_menu/proc/on_mob_login()
	SIGNAL_HANDLER
	update_visibility()

/// Shows or hides the lobby depending on whether the client's mob is a new_player.
/datum/lobby_menu/proc/update_visibility()
	var/should_show = istype(client?.mob, /mob/dead/new_player) && !client.interviewee
	if(should_show && !visible)
		show()
	else if(!should_show && visible)
		hide()
	else if(!should_show && client)
		// Not in the lobby (mid-round reconnect, interview, spectating):
		// make sure the map is selected instead of the empty lobby pane.
		winset(client, SKIN_MAP_LOBBY_SELECTOR, "left=[SKIN_MAP_SCREEN]")

/datum/lobby_menu/proc/show()
	if(visible || !client)
		return
	var/mob/dead/new_player/new_player = client.mob
	if(!istype(new_player))
		return
	visible = TRUE
	fading_out = FALSE
	transparent = GLOB.lobby_background_transparent \
		&& !client.prefs?.read_preference(/datum/preference/toggle/disable_lobby_transparency)
	create_browser(transparent)
	if(!lobby_window)
		lobby_window = new(client, "lobby_browser")
		// The element is created via winset at runtime, so the
		// winexists() check inside tgui_window/initialize() can
		// race the control creation and misroute every message to
		// "lobby_browser.browser:update" (nowhere), leaving a blank
		// white screen. Upstream master sets this explicitly too.
		lobby_window.is_browser = TRUE
		initialize_browser()
	// In opaque mode the CHILD selector swaps between the lobby pane and the
	// map pane; in transparent mode the map is always selected and the
	// browser simply overlays it.
	if(transparent)
		winset(client, SKIN_MAP_LOBBY_SELECTOR, "left=[SKIN_MAP_SCREEN]")
		winset(client, "lobby_browser", "is-visible=true")
	else
		winset(client, SKIN_MAP_LOBBY_SELECTOR, "left=[SKIN_LOBBY_SCREEN]")
	new_player.ui_interact(new_player)
	// Track the UI ref so we can close it after the mob is qdeleted.
	ui = SStgui.get_open_ui(new_player, new_player)
	INVOKE_ASYNC(src, PROC_REF(queue_preview_update))
	INVOKE_ASYNC(src, PROC_REF(check_new_polls))

/datum/lobby_menu/proc/hide()
	if(!visible)
		return
	// If a fade is in progress, the close is already scheduled by send_fade_out().
	if(fading_out)
		return
	do_close()

/// Creates the "lobby_browser" browser element in the appropriate parent window.
/// When transparent, it lives in map_screen overlaying the map.
/// When opaque, it lives in lobby_screen (swapped via the CHILD selector).
/datum/lobby_menu/proc/create_browser(transparent = FALSE)
	// Remove the existing browser element first so the parent can be swapped.
	winset(client, "lobby_browser", list("parent" = ""))

	if(transparent)
		winset(client, "lobby_browser", list(
			"parent" = SKIN_MAP_SCREEN,
			"type" = "BROWSER",
			"pos" = "0,0",
			"size" = "640x480",
			"anchor1" = "0,0",
			"anchor2" = "100,100",
			"background-color" = "none",
			"inner-background-color" = "transparent",
		))
	else
		winset(client, "lobby_browser", list(
			"parent" = SKIN_LOBBY_SCREEN,
			"type" = "BROWSER",
			"pos" = "0,0",
			"size" = "640x480",
			"anchor1" = "0,0",
			"anchor2" = "100,100",
			"background-color" = "#000000",
			"inner-background-color" = "#000000",
		))

/// Loads the tgui bundle and the lobby fonts into the browser element.
/// Guarded: a missing build artifact (e.g. tgui.bundle.js after pulling the
/// branch without running the tgui build) would CRASH inside SSassets before
/// tgui_window/initialize() ever reaches browse(), leaving the element
/// permanently blank-white. Check the files up front, say so in chat, and
/// always let the html reach the browser.
/datum/lobby_menu/proc/initialize_browser()
	var/list/lobby_assets = list()
	if(fexists("tgui/public/tgui.bundle.js") && fexists("tgui/public/tgui.bundle.css"))
		lobby_assets += get_asset_datum(/datum/asset/simple/tgui)
	else
		to_chat(client, span_danger("<b>Lobby:</b> tgui bundle was not found in tgui/public/. Build it (tgui:build / tools/build/build.ts) and restart the server, otherwise the lobby will stay blank."))
		log_tgui(client, "Lobby: tgui/public/tgui.bundle.js or .css is missing - run the tgui build.", context = "lobby_browser")
	if(fexists("tgui/packages/chakrapetch/chakrapetch.css"))
		lobby_assets += get_asset_datum(/datum/asset/simple/namespaced/chakrapetch)
	else
		log_tgui(client, "Lobby: chakrapetch font asset is missing.", context = "lobby_browser")
	try
		lobby_window.initialize(
			strict_mode = TRUE,
			assets = lobby_assets,
		)
	catch(var/exception/e)
		// Asset transit exploded - load a bare page so the element
		// shows the tgui error screen instead of an empty white box.
		log_tgui(client, "Lobby: initialization failed ([e.name]): retrying without assets.", context = "lobby_browser")
		lobby_window.initialize(strict_mode = TRUE)

/// Toggle the lobby browser between opaque (own pane) and transparent (overlaying the map).
/// Recreates the browser element in the appropriate parent and reinitializes it.
/datum/lobby_menu/proc/set_transparency(transparent)
	if(transparent && client?.prefs?.read_preference(/datum/preference/toggle/disable_lobby_transparency))
		return
	src.transparent = transparent
	if(!visible || !client)
		return
	create_browser(transparent)
	if(lobby_window)
		lobby_window.unsubscribe()
		QDEL_NULL(lobby_window)
	lobby_window = new(client, "lobby_browser")
	lobby_window.is_browser = TRUE
	initialize_browser()
	if(transparent)
		winset(client, SKIN_MAP_LOBBY_SELECTOR, "left=[SKIN_MAP_SCREEN]")
		winset(client, "lobby_browser", "is-visible=true")
	else
		winset(client, SKIN_MAP_LOBBY_SELECTOR, "left=[SKIN_LOBBY_SCREEN]")
	var/mob/dead/new_player/new_player = client.mob
	if(istype(new_player))
		new_player.ui_interact(new_player)
		ui = SStgui.get_open_ui(new_player, new_player)
	if(transparent)
		to_chat(client, span_notice("An admin has made the lobby background transparent. You can now see the map behind the lobby menu. You can disable this in your game preferences."))

/// Send the fade-out message to the React app and schedule the actual close
/// via addtimer. No sleep - the calling proc (e.g. transfer_character)
/// returns immediately. The actual close happens via the callback, by which
/// time the mob may have already transferred (the lobby_browser is bound to
/// the client, not the mob, so it survives).
/datum/lobby_menu/proc/send_fade_out()
	if(!visible || fading_out || !client)
		return
	fading_out = TRUE
	// Drop the backdrop so the fading lobby cross-fades into the game view
	// rendered behind the now see-through browser element.
	if(!transparent)
		winset(client, "lobby_browser", "background-color=none;inner-background-color=transparent")
	lobby_window?.send_message("lobbyFadeOut")
	addtimer(CALLBACK(src, PROC_REF(do_close)), LOBBY_FADE_OUT_TIME, TIMER_DELETE_ME)

/datum/lobby_menu/proc/do_close()
	fading_out = FALSE
	if(visible)
		// The lobby was re-shown (player returned) while the fade-out
		// timer was still pending - keep the freshly opened lobby.
		return
	visible = FALSE
	if(ui)
		ui.close(can_be_suspended = FALSE)
		ui = null
	cleanup_window()
	if(client)
		winset(client, "lobby_browser", "is-visible=false")
		if(!transparent)
			winset(client, SKIN_MAP_LOBBY_SELECTOR, "left=[SKIN_MAP_SCREEN]")

/datum/lobby_menu/proc/cleanup_window()
	fading_out = FALSE
	visible = FALSE
	if(ui)
		QDEL_NULL(ui)
	if(lobby_window)
		lobby_window.unsubscribe()
		QDEL_NULL(lobby_window)

/// Re-renders the character preview, guarded by a cooldown so it can be
/// spammed safely from preference windows closing.
/datum/lobby_menu/proc/queue_preview_update(force = FALSE)
	set waitfor = FALSE
	if(!client?.prefs || !visible)
		return
	if(!force && world.time < preview_last_refresh + LOBBY_PREVIEW_REFRESH_COOLDOWN)
		return
	update_character_preview()

/// Renders the player's character into four flat icons and ships them to the
/// client as assets. Lightweight by design: no retry loops, refreshed on
/// lobby show, on preferences closing and via the Refresh button only.
/datum/lobby_menu/proc/update_character_preview()
	set waitfor = FALSE
	if(!client?.prefs || !visible)
		return
	preview_last_refresh = world.time

	var/datum/preferences/preferences = client.prefs
	var/mob/living/carbon/human/dummy/mannequin = new()
	// Dress the mannequin once; silicon jobs return an /image instead
	var/rendered = preferences.render_new_preview_appearance(mannequin, TRUE)
	var/icon_source = istype(rendered, /image) ? rendered : mannequin

	preview_sequence += 1
	var/list/new_urls = list()
	for(var/dir_name in LOBBY_PREVIEW_DIRS)
		var/icon/flat = getFlatIcon(icon_source, LOBBY_PREVIEW_DIRS[dir_name])
		if(!flat)
			continue
		var/asset_name = "lobby_preview_[client.ckey]_[preview_sequence]_[dir_name].png"
		SSassets.transport.register_asset(asset_name, flat)
		SSassets.transport.send_assets(client, asset_name)
		new_urls[dir_name] = SSassets.transport.get_asset_url(asset_name)

	qdel(mannequin)

	preview_urls = length(new_urls) ? new_urls : null
	// If rendering failed entirely, retry once a bit later (prefs may still be settling).
	if(!preview_urls)
		addtimer(CALLBACK(src, PROC_REF(queue_preview_update), TRUE), 10 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_DELETE_ME)
		return
	update_open_ui()

/// Asks the database whether the player has polls they have not voted in yet.
/datum/lobby_menu/proc/check_new_polls()
	set waitfor = FALSE
	if(!client)
		return
	var/mob/dead/new_player/player = client.mob
	if(!istype(player) || is_guest_key(player.key))
		return
	if(!SSdbcore.Connect())
		return
	var/isadmin = !isnull(client.holder)
	var/datum/db_query/query = SSdbcore.NewQuery({"
		SELECT id FROM [format_table_name("poll_question")]
		WHERE (adminonly = 0 OR :isadmin = 1)
		AND Now() BETWEEN starttime AND endtime
		AND deleted = 0
		AND id NOT IN (
			SELECT pollid FROM [format_table_name("poll_vote")]
			WHERE ckey = :ckey
			AND deleted = 0
		)
		AND id NOT IN (
			SELECT pollid FROM [format_table_name("poll_textreply")]
			WHERE ckey = :ckey
			AND deleted = 0
		)
	"}, list("isadmin" = isadmin, "ckey" = player.ckey))
	if(!query.Execute())
		qdel(query)
		return
	var/has_new = query.NextRow() ? TRUE : FALSE
	qdel(query)
	if(!client)
		return
	has_new_poll = has_new
	update_open_ui()

/// Debounced stats refresh - player counts change every join/quit, one
/// resend per burst is plenty.
/datum/lobby_menu/proc/queue_stats_update()
	SIGNAL_HANDLER
	if(!visible || stats_update_timer)
		return
	stats_update_timer = addtimer(CALLBACK(src, PROC_REF(do_stats_update)), LOBBY_STATS_UPDATE_DEBOUNCE, TIMER_STOPPABLE)

/datum/lobby_menu/proc/do_stats_update()
	stats_update_timer = null
	update_open_ui()

/// Pushes fresh ui_data to the open lobby UI (if any).
/datum/lobby_menu/proc/update_open_ui()
	if(QDELETED(ui))
		return
	ui.send_update()

#undef LOBBY_FADE_OUT_TIME
#undef LOBBY_PREVIEW_REFRESH_COOLDOWN
#undef LOBBY_PREVIEW_DIRS
#undef LOBBY_STATS_UPDATE_DEBOUNCE
// [/HORIZON-ADD]
