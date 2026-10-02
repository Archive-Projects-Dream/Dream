// [HORIZON-ADD] HorizonLobby
// Assets required by the CM13-style lobby screen.

/// The lobby jingle played by the frontend shortly after it mounts.
/datum/asset/simple/lobby_files
	keep_local_name = TRUE
	assets = list(
		"load.mp3" = 'sound/lobby/lobby_load.mp3',
	)

/// A randomly picked background image for the lobby screen.
/// Files are read from config/lobby_art/ (*.png); the author attribution is
/// read from config/lobby_art/authors.txt ("file.png=Author Name" per line).
/datum/asset/simple/lobby_art/register()
	var/datum/lobby_art/lobby_art = get_round_lobby_art()
	if(!lobby_art?.art_file)
		return
	assets = list(
		"lobby_art.png" = fcopy_rsc(lobby_art.art_file),
	)
	return ..()

/// Chakra Petch, the CRT lobby font (from CM13).
/datum/asset/simple/namespaced/chakrapetch
	assets = list(
		"chakrapetch-bold.woff2" = file("tgui/packages/chakrapetch/chakrapetch-bold.woff2"),
		"chakrapetch-bold.ttf" = file("tgui/packages/chakrapetch/chakrapetch-bold.ttf"),
		"chakrapetch-regular.woff2" = file("tgui/packages/chakrapetch/chakrapetch-regular.woff2"),
		"chakrapetch-regular.ttf" = file("tgui/packages/chakrapetch/chakrapetch-regular.ttf"),
	)
	parents = list(
		"chakrapetch.css" = file("tgui/packages/chakrapetch/chakrapetch.css"),
	)

/// Cached round lobby art selection (picked once per round).
/datum/lobby_art
	var/art_file
	var/author

GLOBAL_VAR(round_lobby_art)

/// Picks a random lobby art file from config/lobby_art/ once per round.
/// Falls back to "default.png" when the directory holds no images.
/proc/get_round_lobby_art()
	if(GLOB.round_lobby_art)
		return GLOB.round_lobby_art
	var/datum/lobby_art/result = new()
	var/dir_path = "[global.config.directory]/lobby_art/"
	var/list/authors = list()
	var/list/candidates = list()
	for(var/filename in flist(dir_path))
		if(!findtext(filename, ".png"))
			continue
		candidates += filename
	var/picked_name
	if(length(candidates))
		picked_name = pick(candidates)
		result.art_file = file("[dir_path][picked_name]")
	if(picked_name && fexists("[dir_path]authors.txt"))
		for(var/line in splittext(trim(file2text("[dir_path]authors.txt")), "\n"))
			var/split = findtext(line, "=")
			if(!split)
				continue
			authors[trim(copytext(line, 1, split))] = trim(copytext(line, split + 1))
		result.author = authors[picked_name]
	if(!result.art_file)
		var/fallback = "[dir_path]default.png"
		if(fexists(fallback))
			result.art_file = file(fallback)
	GLOB.round_lobby_art = result
	return result
// [/HORIZON-ADD]
