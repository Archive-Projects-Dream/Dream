/datum/asset/simple/lobby
	assets = list(
		"playeroptions.css" = 'html/browser/playeroptions.css'
	)

/// Assets required for the TGUI lobby screen (sound, etc).
/datum/asset/simple/lobby_files
	keep_local_name = TRUE
	assets = list(
		"load.mp3" = 'sound/lobby/lobby_load.mp3',
	)

/// A placeholder background image for the lobby screen.
/// Replace config/lobby_art/<name>.png to use a custom background.
/datum/asset/simple/lobby_art/register()
	var/icon_string = "config/lobby_art/[SSmapping?.current_map?.map_name || "default"].png"

	if(!icon_string || !fexists(icon_string))
		icon_string = "config/lobby_art/default.png"
		if(!fexists(icon_string))
			return

	assets = list(
		"lobby_art.png" = fcopy_rsc(file(icon_string)),
	)

	..()

